import SwiftUI

struct MatchView: View {
    @EnvironmentObject var api: APIService
    @State private var showMatchesOverlay = false
    @State private var targetNumber = ""
    @State private var responseMessage = ""
    @State private var showMatchAnimation = false
    @State private var currentAnimationName = ""
    @State private var gifID = UUID()
    @State private var inputFieldID = UUID()
    @State private var isTargetNumberFocused = false

    var body: some View {
        ZStack {
            // 🎉 GIF-Overlay bei Match
            if showMatchAnimation {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    GIFView(name: currentAnimationName)
                        .frame(width: 500, height: 500)
                        .id(gifID)
                }
                .transition(.scale)
                .zIndex(2)
            }

            // 🔲 Hintergrundbild
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 📦 Hauptinhalt
            HStack(spacing: 0) {
                // 🧭 Sidebar
                VStack(alignment: .leading, spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 170)

                    Text("Deine Nummer:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Text(api.number)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Button("Deine Matches") {
                        showMatchesOverlay = true
                    }
                    .buttonStyle(SidebarButtonStyle())

                    Button("Spielregeln") {
                        // TODO
                    }
                    .buttonStyle(SidebarButtonStyle())

                    Button("Logout") {
                        api.logout()
                    }
                    .buttonStyle(SidebarButtonStyle())

                    Spacer()
                }
                .padding()
                .frame(width: 240)
                .background(Color.black.opacity(0.6))

                Divider()
                    .background(Color.white.opacity(0.3))

                // 📝 Wunsch äußern
                VStack {
                    Spacer()

                    VStack(spacing: 25) {
                        Text("Match?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        NumberTextField(text: $targetNumber, placeholder: "Ziel-Nummer eingeben", isFocused: $isTargetNumberFocused)
                            .id(inputFieldID)
                            .frame(width: 280, height: 55)
                            .padding(.horizontal)

                        HStack(spacing: 16) {
                            Button("N-Match ❤️") {
                                sendMatch(type: "normal")
                            }
                            .buttonStyle(MatchButtonStyle())

                            Button("F-Match 🔥") {
                                sendMatch(type: "hot")
                            }
                            .buttonStyle(FMatchButtonStyle())
                        }

                        if !responseMessage.isEmpty {
                            Text(responseMessage)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color(hex: "#3c0d1f").opacity(0.92))
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                    .padding(.horizontal)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            // ✅ MatchList Overlay
            if showMatchesOverlay {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMatchesOverlay = false
                    }

                MatchListView(isPresented: $showMatchesOverlay)
                    .environmentObject(api)
                    .zIndex(3)
                    .transition(.opacity)
            }
        }
    }

    func sendMatch(type: String) {
        Task {
            do {
                if targetNumber == api.number {
                    responseMessage = "Du kannst dich nicht selbst matchen 😅"
                    currentAnimationName = "stupid"
                    gifID = UUID()
                    showMatchAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showMatchAnimation = false
                        }
                    }
                    targetNumber = ""
                    isTargetNumberFocused = false
                    return
                }

                let result = try await api.submitMatch(targetNumber: targetNumber, type: type)
                responseMessage = result

                if result.contains("Match gefunden") || result.contains("F-Match") || result.contains("F-Gematcht") {
                    currentAnimationName = (type == "hot") ? "hot_match" : "normal_match"
                    gifID = UUID()
                    showMatchAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showMatchAnimation = false
                        }
                        inputFieldID = UUID()
                    }
                }

            } catch {
                responseMessage = "Fehler: \(error.localizedDescription)"
            }

            targetNumber = ""
            isTargetNumberFocused = false
        }
    }
}
