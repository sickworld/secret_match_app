import SwiftUI

struct MatchListView: View {
    @EnvironmentObject var api: APIService
    @State private var matches: [Match] = []
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Deine Matches")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if matches.isEmpty {
                    Text("Noch keine Matches 🤷‍♂️")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 30)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(matches) { match in
                                HStack {
                                    Text("\(match.other)")
                                        .foregroundColor(.white)
                                        .fontWeight(.medium)

                                    Spacer()

                                    Text(match.type == "hot" ? "🔥 F-Match" : "❤️ Normal")
                                        .font(.caption)
                                        .foregroundColor(match.type == "hot" ? .orange : .green)
                                }
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                    dismiss()
                }
                .buttonStyle(SidebarButtonStyle())
                .padding(.top, 20)
            }
            .padding()
            .frame(maxWidth: 400)
            .background(Color(hex: "#3c0d1f").opacity(0.92)) // 🍷 Box-Stil
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            Task {
                do {
                    let fetched = try await api.loadMatches()
                    self.matches = fetched
                } catch {
                    print("❌ Fehler beim Laden der Matches: \(error.localizedDescription)")
                }
            }
        }
    }
}
