//
//  DatePickerAccordionView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/02.
//

import SwiftUI

struct DatePickerAccordionView: View {
    @Binding var date: Date
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("日付")
                Spacer()
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Text(date.formatted(as: .yyyyMMdd))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(isExpanded ? .blue : .primary)
                            .background(Color(.systemGray5))
                            .cornerRadius(100)
                }
            }
            if isExpanded {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
        }
    }
}

#Preview {
    DatePickerAccordionView(date: .constant(Date()))
}
