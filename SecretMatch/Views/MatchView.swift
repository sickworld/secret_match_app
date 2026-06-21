import SwiftUI

struct MatchView: View {
    @EnvironmentObject var api: APIService
    
    @State private var showMatchesOverlay = false
    @State private var showActionsOverlay = false
    @State private var targetNumber = ""
    @State private var selectedActions: Set<String> = []
    @State private var responseMessage = ""


    // Inactivity / Auto-Logout
    @State private var inactivityTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var secondsRemaining = 30

    // UI State
    @State private var showKeyboard = false

    @State private var isLoading = false


    // MARK: - Inactivity Handling
    
    func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        countdownTimer?.invalidate()

        secondsRemaining = 30

        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            Task { @MainActor in
                api.logout()
            }
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                countdownTimer?.invalidate()
            }
        }
    }

    func pauseInactivityTimer() {
        inactivityTimer?.invalidate()
        countdownTimer?.invalidate()
    }

    // MARK: - View

    var body: some View {
        ZStack {
            if isLoading {
                LoadingOverlay(message: "Wird geprüft…")
                    .zIndex(10)
            }

            if showKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .zIndex(20)
                    .task {
                        pauseInactivityTimer()
                    }
                VStack {
                    Spacer()

                    CustomNumberKeyboard(text: $targetNumber) {
                        showKeyboard = false
                        resetInactivityTimer()
                    }
                    .frame(maxWidth: 460)
                    .padding()
                    .cornerRadius(16)
                    .shadow(radius: 20)

                    Spacer()
                }
                .transition(.move(edge: .bottom))
                .zIndex(30)
            }
            
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView(
                    secondsRemaining: secondsRemaining,
                    pauseInactivity: pauseInactivityTimer,
                    logout: { api.logout() },
                    showMatchesOverlay: $showMatchesOverlay,
                    showActionsOverlay: $showActionsOverlay
                )

                Divider().background(Color.white.opacity(0.3))

                VStack {
                    Spacer()

                    MatchInputBox(
                        targetNumber: $targetNumber,
                        showKeyboard: $showKeyboard,
                        selectedActions: $selectedActions,
                        responseMessage: $responseMessage,
                        onSend: sendInteractions
                    )

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .onAppear {
                    resetInactivityTimer()
                }
            }
            
            if showMatchesOverlay {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMatchesOverlay = false
                        resetInactivityTimer()
                    }

                MatchListView(isPresented: $showMatchesOverlay)
                    .environmentObject(api)
                    .zIndex(5)
                    .onTapGesture {
                        showMatchesOverlay = false
                        resetInactivityTimer()
                    }
            }

            if showActionsOverlay {
                Color.black.opacity(0.6).ignoresSafeArea().onTapGesture {
                    showActionsOverlay = false
                }

                ActionListView(isPresented: $showActionsOverlay)
                    .environmentObject(api)
                    .zIndex(5)
                    .onTapGesture {
                        showActionsOverlay = false
                        resetInactivityTimer()
                    }
            }
            
        }.onTapGesture {
            withAnimation {
                showKeyboard = false
                resetInactivityTimer()
            }
        }
    }

    func sendInteractions() {
        Task {
            guard !targetNumber.isEmpty, !selectedActions.isEmpty else { return }
            pauseInactivityTimer()
            isLoading = true

            defer {
                isLoading = false
                targetNumber = ""
                selectedActions = []
                resetInactivityTimer()
                showKeyboard = false
            }

            if targetNumber == api.number {
                responseMessage = "Du kannst keine Aktion an dich selbst senden 😅"
                return
            }

            do {
                let orderedTypes = ["normal", "hot", "bjob", "hjob", "ljob"]
                    .filter(selectedActions.contains)
                var results: [String] = []

                for type in orderedTypes {
                    if type == "normal" || type == "hot" {
                        results.append(try await api.submitMatch(targetNumber: targetNumber, type: type))
                    } else {
                        results.append(try await api.submitAction(targetNumber: targetNumber, type: type))
                    }
                }

                responseMessage = results.joined(separator: "\n")
            } catch {
                responseMessage = "Nicht alle Aktionen konnten gesendet werden: \(error.localizedDescription)"
            }
        }
    }
}
