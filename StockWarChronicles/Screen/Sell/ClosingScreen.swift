//
//  ClosingScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct ClosingScreen: View {
    private struct LotAllocation: Identifiable {
        let record: StockRecord
        var sharesText: String

        var id: ObjectIdentifier {
            ObjectIdentifier(record)
        }
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let records: [StockRecord]

    @State private var sellDate = Date.fromToday()
    @State private var amount = ""
    @State private var totalSharesText: String
    @State private var allocations: [LotAllocation]
    @State private var reason = ""
    @State private var emotion: Emotion = .sales(.normal)

    @State private var keyboardIsPresented = false
    @State private var showDateAlert = false
    @State private var showSaveError = false
    @State private var showEditView = false

    init(records: [StockRecord]) {
        let openRecords = records
            .filter { $0.remainingShares > 0 }
            .sorted { $0.purchase.date < $1.purchase.date }
        let initialAllocations = openRecords.map {
            LotAllocation(record: $0, sharesText: String($0.remainingShares))
        }

        self.records = openRecords
        _totalSharesText = State(initialValue: String(openRecords.reduce(0) { $0 + $1.remainingShares }))
        _allocations = State(initialValue: initialAllocations)
    }

    init(record: StockRecord) {
        self.init(records: [record])
    }

    private var totalAvailableShares: Int {
        records.reduce(0) { $0 + $1.remainingShares }
    }

    private var totalAllocatedShares: Int {
        allocations.reduce(0) { $0 + allocationShares($1) }
    }

    private var requestedTotalShares: Int? {
        Int(totalSharesText)
    }

    private var isAllocationValid: Bool {
        guard let requestedTotalShares,
              requestedTotalShares > 0,
              requestedTotalShares <= totalAvailableShares,
              requestedTotalShares == totalAllocatedShares else {
            return false
        }

        return allocations.allSatisfy { allocation in
            guard let shares = Int(allocation.sharesText) else { return false }
            return (0...allocation.record.remainingShares).contains(shares)
        }
    }

    private var isSaveDisabled: Bool {
        Double(amount) == nil || !isAllocationValid
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: header) {
                    VStack {
                        DatePickerAccordionView(date: $sellDate)
                        Divider().background(.separator)
                    }

                    VStack {
                        HStack {
                            TextField("金額", text: $amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("円")
                        }
                        Divider().background(.separator)
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text("合計株数")

                            Spacer()

                            TextField("株数", text: totalSharesBinding)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 60)

                            Text("/ \(totalAvailableShares.withComma())株")
                                .foregroundStyle(.secondary)

                            Button("全株") {
                                allocateAllShares()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if let requestedTotalShares,
                           requestedTotalShares > totalAvailableShares {
                            Text("売却できるのは最大\(totalAvailableShares.withComma())株です")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Divider().background(.separator)
                    }
                }
                .listRowSeparator(.hidden)

                if allocations.count > 1 {
                    allocationSection
                }

                Section {
                    VStack {
                        Picker("感情", selection: $emotion) {
                            ForEach(SalesEmotions.allCases) { emotion in
                                Text(emotion.rawValue + emotion.name)
                                    .tag(Emotion.sales(emotion))
                            }
                        }
                        .tint(.primary)
                        Divider().background(.separator)
                    }

                    VStack {
                        HStack {
                            Text("メモ")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        VariableHeightTextEditor(text: $reason)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .navigationTitle(records.count > 1 ? "まとめて手仕舞い" : "手仕舞い")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveSell()
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive")
                            Text("保存")
                        }
                        .padding(.horizontal)
                        .opacity(isSaveDisabled ? 0.5 : 1.0)
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
        .withKeyboardToolbar(keyboardIsPresented: $keyboardIsPresented)
        .alert("売却日が購入日以前に設定されています", isPresented: $showDateAlert) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text("売却株数を入力した建玉の購入日以降に修正してください。")
        }
        .alert("保存できませんでした", isPresented: $showSaveError) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text("時間をおいて、もう一度お試しください。")
        }
        .sheet(isPresented: $showEditView) {
            if let record = records.first {
                EditScreen(record: record)
            }
        }
    }

    private var allocationSection: some View {
        Section {
            Text("合計株数を変えると、購入日の古い建玉から自動で配分します。部分売却では各建玉の株数を直接変更できます。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(allocations) { allocation in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(allocation.record.purchase.date.formatted(as: .yyyyMMdd))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("取得 \(Int(allocation.record.purchase.amount).withComma())円・残り\(allocation.record.remainingShares.withComma())株")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        TextField("0", text: allocationBinding(for: allocation.id))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                            .textFieldStyle(.roundedBorder)
                        Text("株")
                    }

                    if allocationShares(allocation) > allocation.record.remainingShares {
                        Text("この建玉は最大\(allocation.record.remainingShares.withComma())株です")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                Text("内訳合計")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalAllocatedShares.withComma())株")
                    .fontWeight(.semibold)
                    .foregroundStyle(isAllocationValid ? Color.primary : Color.red)
            }
        } header: {
            Label("売却する建玉の内訳", systemImage: "square.stack.3d.up")
        }
    }

    private var header: some View {
        HStack {
            if let record = records.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.code + " " + record.name)
                        .lineLimit(1)
                    if records.count > 1 {
                        Text("\(record.position.rawValue)ポジション・\(records.count)件")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if records.count == 1 {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    showEditView.toggle()
                } label: {
                    Text("編集")
                        .font(.caption)
                }
                .glassButtonStyle()
                .contentShape(Rectangle())
            }
        }
    }

    private var totalSharesBinding: Binding<String> {
        Binding(
            get: { totalSharesText },
            set: { newValue in
                let sanitizedValue = digitsOnly(newValue)
                totalSharesText = sanitizedValue
                distributeShares(Int(sanitizedValue) ?? 0)
            }
        )
    }

    private func allocationBinding(for id: ObjectIdentifier) -> Binding<String> {
        Binding(
            get: {
                allocations.first(where: { $0.id == id })?.sharesText ?? ""
            },
            set: { newValue in
                guard let index = allocations.firstIndex(where: { $0.id == id }) else { return }
                allocations[index].sharesText = digitsOnly(newValue)

                let newTotal = totalAllocatedShares
                totalSharesText = newTotal == 0 ? "" : String(newTotal)
            }
        )
    }

    private func digitsOnly(_ value: String) -> String {
        String(value.filter(\.isNumber))
    }

    private func allocationShares(_ allocation: LotAllocation) -> Int {
        Int(allocation.sharesText) ?? 0
    }

    /// 合計入力から購入日の古い順（FIFO）で各建玉へ配分します。
    private func distributeShares(_ requestedShares: Int) {
        var remainingToAllocate = min(max(requestedShares, 0), totalAvailableShares)

        for index in allocations.indices {
            let availableShares = allocations[index].record.remainingShares
            let allocatedShares = min(remainingToAllocate, availableShares)
            allocations[index].sharesText = String(allocatedShares)
            remainingToAllocate -= allocatedShares
        }
    }

    private func allocateAllShares() {
        totalSharesText = String(totalAvailableShares)
        distributeShares(totalAvailableShares)
    }

    private func saveSell() {
        guard let sellAmount = Double(amount), isAllocationValid else { return }

        let selectedAllocations = allocations.filter { allocationShares($0) > 0 }
        let calendar = Calendar.current
        let sellDay = calendar.startOfDay(for: sellDate)
        let hasInvalidDate = selectedAllocations.contains {
            calendar.startOfDay(for: $0.record.purchase.date) > sellDay
        }

        guard !hasInvalidDate else {
            showDateAlert = true
            return
        }

        for allocation in selectedAllocations {
            let sellInfo = StockTradeInfo(
                amount: sellAmount,
                shares: allocationShares(allocation),
                date: sellDate,
                emotion: emotion,
                reason: reason
            )
            allocation.record.sales.append(sellInfo)
        }

        do {
            try context.save()
            dismiss()
        } catch {
            showSaveError = true
        }
    }
}

#if DEBUG
#Preview {
    let first = StockRecord(
        code: "350A",
        market: .tokyo,
        name: "デジタルグリッド",
        position: .buy,
        purchase: .init(
            amount: 5100,
            shares: 100,
            date: Date.from(year: 2025, month: 7, day: 1),
            emotion: Emotion.purchase(.random),
            reason: "成長を期待"
        )
    )
    let second = StockRecord(
        code: "350A",
        market: .tokyo,
        name: "デジタルグリッド",
        position: .buy,
        purchase: .init(
            amount: 5400,
            shares: 200,
            date: Date.from(year: 2025, month: 8, day: 1),
            emotion: Emotion.purchase(.random),
            reason: "買い増し"
        )
    )

    ClosingScreen(records: [first, second])
}
#endif
