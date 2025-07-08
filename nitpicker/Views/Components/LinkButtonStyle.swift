import SwiftUI

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.blue)
            .font(.system(size: 11))
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}