import SwiftUI

struct MatchView: View {
    @EnvironmentObject var api: APIService
    
    @State private var showMatchesOverlay = false
    @State private var showActionsOverlay = false
    @State private var targetNumber = ""
    @State private var actionNumber = ""

    @State private var responseMessageMatches = ""
    @State private var responseMessageAction = ""


    // Inactivity / Auto-Logout
    @State private var inactivityTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var secondsRemaining = 30

    // UI State
    @State private var showKeyboard = false
    @State private var showKeyboardAction = false

    @State private var isLoading = false
    
    @State private var sentActions: [SentAction] = []


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
                    .frame(maxWidth: 300)
                    .padding()
                    .cornerRadius(16)
                    .shadow(radius: 20)

                    Spacer()
                }
                .transition(.move(edge: .bottom))
                .zIndex(30)
            }
            
            if showKeyboardAction {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .zIndex(20)
                    .task {
                        pauseInactivityTimer()
                    }
                VStack {
                    Spacer()

                    CustomNumberKeyboard(text: $actionNumber) {
                        showKeyboardAction = false
                        resetInactivityTimer()
                    }
                    .frame(maxWidth: 300)
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

                VStack(spacing: 30) {
                    Spacer()

                    MatchInputBox(
                        targetNumber: $targetNumber,
                        showKeyboard: $showKeyboard,
                        responseMessage: $responseMessageMatches,
                        onSendMatch: { type in sendMatch(type: type) }
                    )

                    OtherActionsBox(
                        targetNumber: $actionNumber,
                        showKeyboard: $showKeyboardAction,
                        responseMessage: $responseMessageAction,
                        onSendAction: { bonusType in sendAction(type: bonusType) }
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
                showKeyboardAction = false
                resetInactivityTimer()
            }
        }
    }

    func sendMatch(type: String) {
        Task {
            pauseInactivityTimer()
            isLoading = true

            defer {
                isLoading = false
                targetNumber = ""
                resetInactivityTimer()
                showKeyboard = false
            }

            if targetNumber == api.number {
                responseMessageMatches = "Du kannst dich nicht selbst matchen 😅"
                return
            }

            do {
                let result = try await api.submitMatch(
                    targetNumber: targetNumber,
                    type: type
                )
                responseMessageMatches = result
            } catch {
                responseMessageMatches = "Fehler: \(error.localizedDescription)"
            }
        }
    }
    
    func sendAction(type: String) {
        Task {
            isLoading = true
            defer {
                isLoading = false
                actionNumber = ""
                showKeyboard = false
            }
            
            if actionNumber == api.number {
                responseMessageAction = "Du kannst dich nicht selbst beglücken 😅"
                return
            }

            do {
                let result = try await api.submitAction(targetNumber: actionNumber, type: type)
                responseMessageAction = result
            } catch {
                responseMessageAction = "Fehler: \(error.localizedDescription)"
            }
        }
    }
}
