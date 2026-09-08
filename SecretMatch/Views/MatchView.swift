import SwiftUI

struct MatchView: View {
    @EnvironmentObject var api: APIService
    
    @State private var showOverviewOverlay = false
    @State private var selectedOverviewSection: ParticipantOverviewSection = .matches
    @State private var showGuideOverlay = false
    @State private var showRulesOverlay = false
    @State private var showInfoOverlay = false
    @State private var targetNumber = ""
    @State private var selectedActions: Set<String> = []
    @State private var responseMessage = ""
    @State private var matchMessage = ""
    @State private var submissionFailed = false


    // Inactivity / Auto-Logout
    @State private var autoLogoutTask: Task<Void, Never>?
    @State private var secondsRemaining = 30
    private let autoLogoutSeconds = 30

    // UI State
    @State private var showKeyboard = false
    @State private var showTextKeyboard = false

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
            let isShort = !isCompact && proxy.size.height < 760

            content(isCompact: isCompact, isShort: isShort, availableHeight: proxy.size.height)
        }
    }

    private func content(isCompact: Bool, isShort: Bool, availableHeight: CGFloat) -> some View {
        ZStack {
            BrandBackground()

            if isLoading {
                LoadingOverlay(message: "Wird geprüft…")
                    .zIndex(10)
            }

            if showKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showKeyboard = false
                        resetInactivityTimer()
                    }
                    .zIndex(20)
                VStack {
                    Spacer()

                    CustomNumberKeyboard(
                        text: $targetNumber,
                        onActivity: resetInactivityTimer,
                        onClose: {
                            showKeyboard = false
                            resetInactivityTimer()
                        }
                    ) {
                        showKeyboard = false
                        resetInactivityTimer()
                    }
                    .frame(maxWidth: 740)
                    .padding()
                    .cornerRadius(16)
                    .shadow(radius: 20)

                    Spacer()
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(30)
            }

            if showTextKeyboard {
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showTextKeyboard = false
                        resetInactivityTimer()
                    }
                    .zIndex(20)

                VStack {
                    Spacer(minLength: 12)
                    CustomTextKeyboard(
                        text: $matchMessage,
                        onActivity: resetInactivityTimer,
                        onClose: {
                            showTextKeyboard = false
                            resetInactivityTimer()
                        }
                    )
                    .padding(18)
                    Spacer(minLength: 12)
                }
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(30)
            }

            mainLayout(isCompact: isCompact, isShort: isShort, availableHeight: availableHeight)
                .onAppear {
                    resetInactivityTimer()
                }
            
            if showOverviewOverlay {
                ParticipantOverviewView(
                    isPresented: $showOverviewOverlay,
                    selectedSection: selectedOverviewSection
                )
                    .environmentObject(api)
                    .zIndex(5)
            }

            if showGuideOverlay {
                Color.black.opacity(0.84)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showGuideOverlay = false
                        resetInactivityTimer()
                    }

                HowToUseView(
                    isPresented: $showGuideOverlay,
                    registerActivity: resetInactivityTimer
                )
                .zIndex(5)
            }

            if showRulesOverlay {
                Color.black.opacity(0.84)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showRulesOverlay = false
                        resetInactivityTimer()
                    }

                RulesSlideshowView(
                    isPresented: $showRulesOverlay,
                    registerActivity: resetInactivityTimer
                )
                .zIndex(5)
            }

            if showInfoOverlay {
                InfoSupportView(isPresented: $showInfoOverlay)
                    .environmentObject(api)
                    .onAppear { pauseInactivityTimer() }
                    .onDisappear { resetInactivityTimer() }
                    .zIndex(6)
            }
            
        }.onTapGesture {
            withAnimation {
                showKeyboard = false
                showTextKeyboard = false
                resetInactivityTimer()
            }
        }
        .onDisappear {
            autoLogoutTask?.cancel()
        }
        .preference(
            key: SecretMatchAccessibilityControlsHiddenPreferenceKey.self,
            value: showKeyboard
                || showTextKeyboard
                || showOverviewOverlay
                || showGuideOverlay
                || showRulesOverlay
                || showInfoOverlay
        )
    }

    @ViewBuilder
    private func mainLayout(isCompact: Bool, isShort: Bool, availableHeight: CGFloat) -> some View {
        if isCompact {
            ScrollView {
                VStack(spacing: 0) {
                    sidebar(isCompact: true, isShort: false, availableHeight: availableHeight)

                    MatchInputBox(
                        targetNumber: $targetNumber,
                        showKeyboard: $showKeyboard,
                        showTextKeyboard: $showTextKeyboard,
                        selectedActions: $selectedActions,
                        matchMessage: $matchMessage,
                        quickMessages: api.matchMessageOptions,
                        onSend: sendInteractions,
                        queuedSendCount: api.queuedSendCount,
                        queuedBatchCount: api.queuedBatchCount,
                        isRetryingQueuedSends: api.isRetryingQueuedSends,
                        deliveryStatus: submissionFailed ? .failed : api.interactionDeliveryStatus,
                        deliveryErrorMessage: submissionFailed ? responseMessage : api.interactionDeliveryErrorMessage,
                        onRetryQueuedSends: retryQueuedSends
                    )
                    .padding(18)
                }
            }
        } else {
            HStack(spacing: 0) {
                sidebar(isCompact: false, isShort: isShort, availableHeight: availableHeight)

                Divider().background(Color.white.opacity(0.3))

                MatchInputBox(
                    targetNumber: $targetNumber,
                    showKeyboard: $showKeyboard,
                    showTextKeyboard: $showTextKeyboard,
                    selectedActions: $selectedActions,
                    matchMessage: $matchMessage,
                    quickMessages: api.matchMessageOptions,
                    onSend: sendInteractions,
                    queuedSendCount: api.queuedSendCount,
                    queuedBatchCount: api.queuedBatchCount,
                    isRetryingQueuedSends: api.isRetryingQueuedSends,
                    deliveryStatus: submissionFailed ? .failed : api.interactionDeliveryStatus,
                    deliveryErrorMessage: submissionFailed ? responseMessage : api.interactionDeliveryErrorMessage,
                    onRetryQueuedSends: retryQueuedSends,
                    fillsAvailableSpace: true,
                    availableHeight: availableHeight
                )
                .frame(maxWidth: .infinity)
                .background(SecretMatchTheme.surface.opacity(0.97))
            }
        }
    }

    private func sidebar(isCompact: Bool, isShort: Bool, availableHeight: CGFloat) -> some View {
        SidebarView(
            secondsRemaining: secondsRemaining,
            registerActivity: resetInactivityTimer,
            logout: { api.logout() },
            showOverviewOverlay: $showOverviewOverlay,
            selectedOverviewSection: $selectedOverviewSection,
            showGuideOverlay: $showGuideOverlay,
            showRulesOverlay: $showRulesOverlay,
            showInfoOverlay: $showInfoOverlay,
            isCompact: isCompact,
            isShort: isShort,
            availableHeight: availableHeight
        )
    }

    func sendInteractions() {
        Task {
            guard !targetNumber.isEmpty, !selectedActions.isEmpty else { return }
            submissionFailed = false
            pauseInactivityTimer()
            isLoading = true

            defer {
                isLoading = false
                targetNumber = ""
                selectedActions = []
                resetInactivityTimer()
                showKeyboard = false
                showTextKeyboard = false
            }

            if targetNumber.normalizedEventNumber == api.number.normalizedEventNumber {
                responseMessage = "Du kannst keine Aktion an dich selbst senden 😅"
                submissionFailed = true
                return
            }

            do {
                let orderedTypes = ["normal", "hot", "bjob", "hjob", "ljob"]
                    .filter(selectedActions.contains)
                let result = try await api.submitInteractions(
                    targetNumber: targetNumber,
                    types: orderedTypes,
                    message: matchMessage
                )
                responseMessage = result.userMessage
                matchMessage = ""
            } catch {
                responseMessage = api.interactionDeliveryErrorMessage
                    ?? "Das hat gerade nicht geklappt. Bitte prüfe deine Eingaben und versuche es noch einmal."
                submissionFailed = true
            }
        }
    }

    private func retryQueuedSends() {
        Task {
            submissionFailed = false
            pauseInactivityTimer()
            await api.retryPendingSends()
            resetInactivityTimer()
        }
    }
}
