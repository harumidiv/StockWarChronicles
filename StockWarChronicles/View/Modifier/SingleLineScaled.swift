import SwiftUI

extension View {
    func singleLineScaled() -> some View {
        lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
