import SwiftUI

struct MatchView: View {
    @EnvironmentObject var api: APIService
    @State private var showMatchesSheet = false
    @State private var targetNumber = ""
    @State private var responseMessage = ""
    @State private var showMatchAnimation = false
    @State private var currentAnimationName = ""
    @State private var gifID = UUID()
    @FocusState private var isTargetFieldFocused: Bool
    
    var body: some View {
        ZStack {
            if showMatchAnimation {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    GIFView(name: currentAnimationName)
                        .frame(width: 500, height: 500)
                        .id(gifID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .transition(.scale)
                .zIndex(1)
            }
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            HStack(spacing: 0) {
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

                    Button("📋 Meine Matches") {
                        showMatchesSheet = true
                    }
                    .buttonStyle(SidebarButtonStyle())

                    Button("📜 Spielregeln") {
                        // TODO: Spielregeln anzeigen
                    }
                    .buttonStyle(SidebarButtonStyle())

                    Button("🚪 Logout") {
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

                VStack {
                    Spacer()

                    VStack(spacing: 25) {
                        Text("Match?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        TextField("", text: $targetNumber)
                            .placeholder(when: targetNumber.isEmpty) {
                                Text("Ziel-Nummer eingeben")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .keyboardType(.numberPad)
                            .padding()
                            .frame(width: 280, height: 55)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            )
                            .focused($isTargetFieldFocused)
                            .padding(.horizontal)

                        HStack(spacing: 16) {
                            Button("N-Match") {
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
                    .background(Color(hex: "#3c0d1f").opacity(0.92)) // 🔥 Burgundy Box
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                    .padding(.horizontal)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showMatchesSheet) {
            MatchListView()
        }
    }

    func sendMatch(type: String) {
        Task {
            do {
                let result = try await api.submitMatch(targetNumber: targetNumber, type: type)
                responseMessage = result
                targetNumber = ""
                isTargetFieldFocused = true

                if result.contains("Match gefunden") || result.contains("F-Match") || result.contains("F-Gematcht") {
                    currentAnimationName = (type == "hot") ? "hot_match" : "normal_match"
                    gifID = UUID()
                    showMatchAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showMatchAnimation = false
                        }
                    }
                }

            } catch {
                responseMessage = "Fehler: \(error.localizedDescription)"
            }
        }
    }
}
