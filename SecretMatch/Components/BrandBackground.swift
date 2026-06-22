import SwiftUI

struct BrandBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#160307"), Color(hex: "#3A0710"), Color(hex: "#210309")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(hex: "#F52235").opacity(0.38), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 560
            )

            RadialGradient(
                colors: [Color(hex: "#FF7048").opacity(0.20), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
    }
}
