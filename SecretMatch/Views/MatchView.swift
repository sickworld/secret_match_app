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
    @State private var lastWithdrawableActionIDs: [UUID] = []
    @State private var isWithdrawingLastActions = false
    @State private var withdrawalConfirmationMessage: String?
    @State private var targetIsConfirmed = false
    @State private var allowedActionTypes: Set<String> = Set(ActionDefinition.fallbacks.map(\.id))
    @State private var usesOfflineSelectionFallback = false


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
                        confirmTargetNumber()
                    }
                    .frame(maxWidth: 740)
                    .padding()
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
                        matchDefinitions: api.matchDefinitions,
                        actionDefinitions: api.actionDefinitions,
                        onSend: sendInteractions,
                        targetIsConfirmed: targetIsConfirmed,
                        allowedActionTypes: allowedActionTypes,
                        usesOfflineSelectionFallback: usesOfflineSelectionFallback,
                        onEditTarget: editTargetNumber,
                        queuedSendCount: api.queuedSendCount,
                        queuedBatchCount: api.queuedBatchCount,
                        isRetryingQueuedSends: api.isRetryingQueuedSends,
                        deliveryStatus: submissionFailed ? .failed : api.interactionDeliveryStatus,
                        deliveryErrorMessage: submissionFailed ? responseMessage : api.interactionDeliveryErrorMessage,
                        onRetryQueuedSends: retryQueuedSends,
                        canUndoLastActions: !lastWithdrawableActionIDs.isEmpty,
                        isUndoingLastActions: isWithdrawingLastActions,
                        withdrawalConfirmationMessage: withdrawalConfirmationMessage,
                        onUndoLastActions: undoLastActions
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
                    matchDefinitions: api.matchDefinitions,
                    actionDefinitions: api.actionDefinitions,
                    onSend: sendInteractions,
                    targetIsConfirmed: targetIsConfirmed,
                    allowedActionTypes: allowedActionTypes,
                    usesOfflineSelectionFallback: usesOfflineSelectionFallback,
                    onEditTarget: editTargetNumber,
                    queuedSendCount: api.queuedSendCount,
                    queuedBatchCount: api.queuedBatchCount,
                    isRetryingQueuedSends: api.isRetryingQueuedSends,
                    deliveryStatus: submissionFailed ? .failed : api.interactionDeliveryStatus,
                    deliveryErrorMessage: submissionFailed ? responseMessage : api.interactionDeliveryErrorMessage,
                    onRetryQueuedSends: retryQueuedSends,
                    canUndoLastActions: !lastWithdrawableActionIDs.isEmpty,
                    isUndoingLastActions: isWithdrawingLastActions,
                    withdrawalConfirmationMessage: withdrawalConfirmationMessage,
                    onUndoLastActions: undoLastActions,
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
            lastWithdrawableActionIDs = []
            withdrawalConfirmationMessage = nil
            pauseInactivityTimer()
            isLoading = true

            defer {
                isLoading = false
                targetNumber = ""
                selectedActions = []
                targetIsConfirmed = false
                allowedActionTypes = activeActionTypes
                usesOfflineSelectionFallback = false
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
                let orderedTypes = (api.matchDefinitions.map(\.id) + api.actionDefinitions.map(\.id))
                    .filter(selectedActions.contains)
                let result = try await api.submitInteractions(
                    targetNumber: targetNumber,
                    types: orderedTypes,
                    message: matchMessage
                )
                responseMessage = result.userMessage
                lastWithdrawableActionIDs = result.actionRequestIDs
                withdrawalConfirmationMessage = nil
                matchMessage = ""
            } catch {
                responseMessage = api.interactionDeliveryErrorMessage
                    ?? "Das hat gerade nicht geklappt. Bitte prüfe deine Eingaben und versuche es noch einmal."
                submissionFailed = true
            }
        }
    }

    private func confirmTargetNumber() {
        let target = targetNumber.normalizedEventNumber
        showKeyboard = false

        guard !target.isEmpty else {
            responseMessage = "Bitte gib zuerst eine Zielnummer ein."
            submissionFailed = true
            resetInactivityTimer()
            return
        }
        guard target != api.number.normalizedEventNumber else {
            responseMessage = "Du kannst keine Aktion an dich selbst senden 😅"
            submissionFailed = true
            resetInactivityTimer()
            return
        }

        if api.connectionState == .offline || api.connectionState == .serverUnavailable {
            allowedActionTypes = activeActionTypes
            usesOfflineSelectionFallback = true
            withAnimation(.easeOut(duration: 0.2)) {
                targetIsConfirmed = true
            }
            resetInactivityTimer()
            return
        }

        Task {
            submissionFailed = false
            pauseInactivityTimer()
            isLoading = true
            defer {
                isLoading = false
                resetInactivityTimer()
            }

            do {
                let options = try await api.loadInteractionOptions(targetNumber: target)
                allowedActionTypes = options.actionTypes
                usesOfflineSelectionFallback = false
                selectedActions = Set(selectedActions.filter {
                    options.matchTypes.contains($0) || options.actionTypes.contains($0)
                })
                withAnimation(.easeOut(duration: 0.2)) {
                    targetIsConfirmed = true
                }
            } catch InteractionOptionsError.invalidTarget(let invalidNumber) {
                responseMessage = InteractionOptionsError.invalidTarget(invalidNumber).localizedDescription
                submissionFailed = true
                targetIsConfirmed = false
            } catch InteractionOptionsError.connectivityUnavailable {
                allowedActionTypes = activeActionTypes
                usesOfflineSelectionFallback = true
                selectedActions = Set(selectedActions.filter {
                    Set(api.matchDefinitions.filter(\.enabled).map(\.id)).contains($0) || allowedActionTypes.contains($0)
                })
                withAnimation(.easeOut(duration: 0.2)) {
                    targetIsConfirmed = true
                }
            } catch {
                responseMessage = "Die passenden Aktionen konnten gerade nicht geladen werden. Bitte bestätige die Nummer noch einmal."
                submissionFailed = true
                targetIsConfirmed = false
                usesOfflineSelectionFallback = false
            }
        }
    }

    private func editTargetNumber() {
        selectedActions = []
        matchMessage = ""
        submissionFailed = false
        allowedActionTypes = activeActionTypes
        usesOfflineSelectionFallback = false
        withAnimation(.easeOut(duration: 0.2)) {
            targetNumber = ""
            targetIsConfirmed = false
            showTextKeyboard = false
            showKeyboard = true
        }
        resetInactivityTimer()
    }

    private var activeActionTypes: Set<String> {
        Set(api.actionDefinitions.filter(\.enabled).map(\.id))
    }

    private func retryQueuedSends() {
        Task {
            submissionFailed = false
            pauseInactivityTimer()
            await api.retryPendingSends()
            resetInactivityTimer()
        }
    }

    private func undoLastActions() {
        let requestIDs = lastWithdrawableActionIDs
        guard !requestIDs.isEmpty, !isWithdrawingLastActions else { return }
        Task {
            isWithdrawingLastActions = true
            submissionFailed = false
            pauseInactivityTimer()
            defer {
                isWithdrawingLastActions = false
                resetInactivityTimer()
            }
            do {
                let count = try await api.withdrawActions(requestIDs: requestIDs)
                lastWithdrawableActionIDs = []
                withdrawalConfirmationMessage = count == 1
                    ? "Die Aktion wurde zurückgezogen."
                    : "Die Aktionen wurden zurückgezogen."
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    withdrawalConfirmationMessage = nil
                }
            } catch {
                responseMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Die Aktion konnte gerade nicht zurückgezogen werden. Bitte versuche es erneut."
                submissionFailed = true
            }
        }
    }
}
