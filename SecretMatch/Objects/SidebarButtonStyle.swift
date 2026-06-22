import SwiftUI

struct SidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(hex: "#F52235"))
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: 140)
            .background(Color(hex: "#F52235"))
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct FMatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: 140)
            .background(Color(hex: "#F52235"))
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
