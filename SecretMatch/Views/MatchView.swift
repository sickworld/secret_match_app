import SwiftUI

struct MatchView: View {
    @EnvironmentObject var api: APIService
    
    @State private var showMatchesOverlay = false
    @State private var showActionsOverlay = false
    @State private var targetNumber = ""
    @State private var selectedActions: Set<String> = []
    @State private var responseMessage = ""


    // Inactivity / Auto-Logout
    @State private var autoLogoutTask: Task<Void, Never>?
    @State private var secondsRemaining = 30
    private let autoLogoutSeconds = 30

    // UI State
    @State private var showKeyboard = false

    @State private var isLoading = false


    // MARK: - Inactivity Handling
    
    func resetInactivityTimer() {
        autoLogoutTask?.cancel()
        secondsRemaining = autoLogoutSeconds

        autoLogoutTask = Task { @MainActor in
            while !Task.isCancelled && secondsRemaining > 0 {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                secondsRemaining -= 1
            }

            guard !Task.isCancelled, secondsRemaining == 0 else { return }
            api.logout()
        }
    }

    func pauseInactivityTimer() {
        autoLogoutTask?.cancel()
    }

    // MARK: - View

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < proxy.size.height

            content(isCompact: isCompact)
        }
    }

    private func content(isCompact: Bool) -> some View {
        ZStack {
            BrandBackground()

            if isLoading {
                LoadingOverlay(message: "Wird geprüft…")
                    .zIndex(10)
            }

            if showKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .zIndex(20)
                VStack {
                    Spacer()

                    CustomNumberKeyboard(text: $targetNumber, onActivity: resetInactivityTimer) {
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

            mainLayout(isCompact: isCompact)
                .onAppear {
                    resetInactivityTimer()
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
                    resetInactivityTimer()
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
        .onDisappear {
            autoLogoutTask?.cancel()
        }
    }

    @ViewBuilder
    private func mainLayout(isCompact: Bool) -> some View {
        if isCompact {
            ScrollView {
                VStack(spacing: 0) {
                    sidebar(isCompact: true)

                    MatchInputBox(
                        targetNumber: $targetNumber,
                        showKeyboard: $showKeyboard,
                        selectedActions: $selectedActions,
                        responseMessage: $responseMessage,
                        onSend: sendInteractions
                    )
                    .padding(18)
                }
            }
        } else {
            HStack(spacing: 0) {
                sidebar(isCompact: false)

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
            }
        }
    }

    private func sidebar(isCompact: Bool) -> some View {
        SidebarView(
            secondsRemaining: secondsRemaining,
            registerActivity: resetInactivityTimer,
            logout: { api.logout() },
            showMatchesOverlay: $showMatchesOverlay,
            showActionsOverlay: $showActionsOverlay,
            isCompact: isCompact
        )
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
