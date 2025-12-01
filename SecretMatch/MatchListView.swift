import SwiftUI

struct MatchListView: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        NavigationView {
            List(api.matches, id: \.id) { match in
                HStack {
                    Text("Nummer \(match.other)")
                    Spacer()
                    Text(match.type == "hot" ? "🔥 F-Match" : "🤝 Match")
                        .foregroundColor(match.type == "hot" ? .orange : .green)
                }
            }
            .navigationTitle("Deine Matches")
        }
    }
}
