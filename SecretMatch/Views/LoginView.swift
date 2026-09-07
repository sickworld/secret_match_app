import SwiftUI
import Combine

struct LoginView: View {
    @Environment(\.secretMatchInterfaceScale) private var interfaceScale
    @State private var number: String = ""
    @State private var pin: String = ""
    @State private var requiresLoginPIN = false
    @State private var activeField: LoginField = .number
    @EnvironmentObject var api: APIService
    @State private var showKeyboard = false
    @State private var isLoading = false
    @State private var showAdminLogin = false
    @State private var showInfoSupport = false
    @State private var showGenderChoice = false
    @State private var showPINSetup = false
    @State private var pinSetupSubmitting = false
    @State private var pinSetupError: String?
    @State private var needsGenderAfterPIN = false
    @State private var genderSubmitting = false
    @State private var genderError: String?
    @State private var errorMessage: String?
    @State private var showScreensaver = false
    @State private var screensaverTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            SecretMatchTheme.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let isHeightConstrained = interfaceScale >= 1.29 || proxy.size.height < 700

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: isHeightConstrained ? 20 : 34) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: loginLogoWidth,
                            height: loginLogoHeight
                        )
                        .shadow(color: SecretMatchTheme.primary.opacity(0.22), radius: 24)
                        .onTapGesture(count: 2) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showAdminLogin = true
                        }

                    VStack(spacing: 12) {
                        Text("DEIN EVENT. DEIN MATCH.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(2.2)
                            .foregroundStyle(SecretMatchTheme.secondary)

                        Text("Bereit für Match&Play?")
                            .font(.system(size: isHeightConstrained ? 34 : 40, weight: .bold, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.text)

                        Text(requiresLoginPIN
                             ? "Gib jetzt deine persönliche PIN ein."
                             : "Gib zuerst deine Event-Nummer ein.")
                            .font(.system(size: isHeightConstrained ? 18 : 20, weight: .medium, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.muted)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        if requiresLoginPIN {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DEINE EVENTNUMMER")
                                        .font(.caption.bold())
                                        .tracking(1.5)
                                        .foregroundStyle(SecretMatchTheme.secondary)
                                    Text(number.displayEventNumber)
                                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                                        .foregroundStyle(SecretMatchTheme.text)
                                }
                                Spacer()
                                Button("Ändern") { editNumber() }
                                    .font(.callout.bold())
                                    .foregroundStyle(SecretMatchTheme.secondary)
                            }
                            .padding(.horizontal, 18)

                            Text(pin.isEmpty ? "Deine 2-stellige PIN" : String(repeating: "•", count: pin.count))
                                .foregroundStyle(pin.isEmpty ? SecretMatchTheme.muted : SecretMatchTheme.text)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .secretInput(highlighted: showKeyboard)
                                .onTapGesture {
                                    activeField = .pin
                                    showKeyboard = true
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            Text(number.isEmpty ? "Deine Nummer eingeben" : number.displayEventNumber)
                                .foregroundStyle(number.isEmpty ? SecretMatchTheme.muted : SecretMatchTheme.text)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.75)
                                .secretInput(highlighted: showKeyboard)
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        activeField = .number
                                        showKeyboard = true
                                    }
                                }
                        }
                    }
                    .animation(.easeInOut(duration: 0.22), value: requiresLoginPIN)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(SecretMatchTheme.text)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(SecretMatchTheme.danger.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SecretMatchTheme.danger.opacity(0.4)))
                    }

                    Button(action: submitLogin) {
                        HStack {
                            Text(requiresLoginPIN ? "Anmelden" : "Weiter")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(SecretPrimaryButtonStyle(
                        fontSize: isHeightConstrained ? 19 : 21,
                        minHeight: isHeightConstrained ? 68 : 78
                    ))
                    .disabled(loginIsDisabled)
                    .opacity(loginIsDisabled ? 0.55 : 1)

                    Button {
                            showKeyboard = false
                            showInfoSupport = true
                    } label: {
                        Label("Info, Datenschutz & Impressum", systemImage: "info.circle.fill")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.secondary)
                    .accessibilityHint("Öffnet Info, Feedback, Datenschutz und Impressum")
                        }
                        .frame(maxWidth: 680)
                        .padding(.horizontal, isHeightConstrained ? 36 : 50)
                        .padding(.vertical, isHeightConstrained ? 20 : 36)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .padding(.horizontal, 28)
                }
            }

            if isLoading {
                LoadingOverlay(message: "Wird angemeldet…")
                    .zIndex(10)
            }

            if showKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showKeyboard = false
                        }
                    }
                    .zIndex(20)

                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        if activeField == .pin {
                            loginPINPrompt
                        }
                        CustomNumberKeyboard(
                            text: activeField == .number ? $number : $pin,
                            doneLabel: requiresLoginPIN ? "Anmelden" : "Weiter",
                            placeholder: activeField == .number ? "Nummer…" : "PIN…",
                            maxDigits: activeField == .number ? 3 : 2,
                            obscuresText: activeField == .pin,
                            onClose: { withAnimation { showKeyboard = false } }
                        ) {
                            submitLogin()
                        }
                        .frame(maxWidth: 740)
                        .cornerRadius(16)
                        .shadow(radius: 20)
                    }
                    .padding()
                    Spacer()
                }
                .zIndex(30)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            if showInfoSupport {
                InfoSupportView(isPresented: $showInfoSupport)
                    .environmentObject(api)
                    .zIndex(40)
            }

            if showGenderChoice {
                ParticipantGenderView(isSubmitting: genderSubmitting, errorMessage: genderError) { gender in
                    submitGender(gender)
                }
                .zIndex(45)
            }

            if showPINSetup {
                ParticipantPINSetupView(
                    isSubmitting: pinSetupSubmitting,
                    errorMessage: pinSetupError,
                    onCancel: cancelPINSetup
                ) { newPIN, confirmation in
                    submitNewPIN(newPIN, confirmation: confirmation)
                }
                .zIndex(46)
            }

            if showScreensaver {
                LoginScreensaverView {
                    restartScreensaverTimer()
                }
                .transition(.opacity)
                .zIndex(50)
            }
        }
        .animation(.easeInOut(duration: 0.24), value: showKeyboard)
        .animation(.easeInOut(duration: 0.7), value: showScreensaver)
        .preference(key: SecretMatchScaleControlsHiddenPreferenceKey.self, value: showScreensaver)
        .simultaneousGesture(
            TapGesture().onEnded {
                guard !showScreensaver else { return }
                restartScreensaverTimer()
            }
        )
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            restartScreensaverTimer()
        }
        .onDisappear {
            screensaverTask?.cancel()
            screensaverTask = nil
            showScreensaver = false
        }
        .onChange(of: number) { _, _ in restartScreensaverTimer() }
        .onChange(of: showKeyboard) { _, _ in restartScreensaverTimer() }
        .onChange(of: showInfoSupport) { _, _ in restartScreensaverTimer() }
        .onChange(of: showGenderChoice) { _, _ in restartScreensaverTimer() }
        .onChange(of: showPINSetup) { _, _ in restartScreensaverTimer() }
        .onChange(of: showAdminLogin) { _, isPresented in
            if isPresented {
                suspendScreensaver()
            } else {
                restartScreensaverTimer()
            }
        }
        .fullScreenCover(isPresented: $showAdminLogin) {
            AdminLoginView(isPresented: $showAdminLogin)
                .environmentObject(api)
        }
    }

    private var loginPINPrompt: some View {
        HStack(spacing: 15) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SecretMatchTheme.secondary)
                .frame(width: 48, height: 48)
                .background(SecretMatchTheme.secondary.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("ANMELDUNG · PIN")
                    .font(.caption.bold())
                    .tracking(1.5)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("PIN für \(number.displayEventNumber) eingeben")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(SecretMatchTheme.danger)
                        .accessibilityLabel("Fehler: \(errorMessage)")
                } else {
                    Text("Nutze deine selbst gewählte zweistellige PIN.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(SecretMatchTheme.muted)
                }
            }

            Spacer(minLength: 8)

            Button("Nummer ändern") {
                editNumber()
            }
            .font(.callout.bold())
            .foregroundStyle(SecretMatchTheme.secondary)
        }
        .padding(16)
        .frame(maxWidth: 700)
        .background(SecretMatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SecretMatchTheme.secondary.opacity(0.42)))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
    }

    private func submitLogin() {
        guard !loginIsDisabled else { return }

        showKeyboard = false
        errorMessage = nil
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let requirements = try await api.login(number: number, pin: pin)
                needsGenderAfterPIN = requirements.needsGender
                if requirements.needsPin {
                    showPINSetup = true
                } else if requirements.needsGender {
                    showGenderChoice = true
                } else {
                    api.finishParticipantLogin()
                }
            } catch ParticipantLoginError.pinRequired {
                requiresLoginPIN = true
                pin = ""
                activeField = .pin
                showKeyboard = true
            } catch ParticipantLoginError.tooManyAttempts {
                errorMessage = "Zu viele Login-Versuche. Bitte 20 Sekunden warten."
            } catch ParticipantLoginError.invalidCredentials {
                if requiresLoginPIN {
                    pin = ""
                    activeField = .pin
                    showKeyboard = true
                    errorMessage = "Die PIN ist nicht gültig. Bitte erneut versuchen."
                } else {
                    errorMessage = "Diese Eventnummer ist nicht gültig."
                }
            } catch {
                errorMessage = "Login fehlgeschlagen. Bitte Verbindung prüfen und erneut versuchen."
            }
        }
    }

    private var loginIsDisabled: Bool {
        isLoading || number.isEmpty || (requiresLoginPIN && pin.count != 2)
    }

    private var loginLogoWidth: CGFloat {
        300 * loginLogoRenderedScale / interfaceScale
    }

    private var loginLogoHeight: CGFloat {
        240 * loginLogoRenderedScale / interfaceScale
    }

    private var loginLogoRenderedScale: CGFloat {
        1 + max(0, interfaceScale - 1) * 0.5
    }

    private func editNumber() {
        requiresLoginPIN = false
        pin = ""
        errorMessage = nil
        activeField = .number
        showKeyboard = true
    }

    private func submitNewPIN(_ newPIN: String, confirmation: String) {
        guard !pinSetupSubmitting else { return }
        pinSetupSubmitting = true
        pinSetupError = nil
        Task {
            defer { pinSetupSubmitting = false }
            do {
                try await api.setParticipantPIN(newPIN, confirmation: confirmation)
                showPINSetup = false
                if needsGenderAfterPIN {
                    showGenderChoice = true
                } else {
                    api.finishParticipantLogin()
                }
            } catch {
                pinSetupError = "Die PIN konnte nicht gespeichert werden. Bitte prüfe beide Eingaben."
            }
        }
    }

    private func cancelPINSetup() {
        guard !pinSetupSubmitting else { return }
        pinSetupSubmitting = true
        Task {
            await api.cancelParticipantLogin()
            showPINSetup = false
            pinSetupError = nil
            needsGenderAfterPIN = false
            number = ""
            pin = ""
            requiresLoginPIN = false
            activeField = .number
            showKeyboard = false
            pinSetupSubmitting = false
            restartScreensaverTimer()
        }
    }

    private func submitGender(_ gender: ParticipantGender) {
        guard !genderSubmitting else { return }
        genderSubmitting = true
        genderError = nil

        Task {
            defer { genderSubmitting = false }
            do {
                try await api.submitParticipantGender(gender)
                showGenderChoice = false
                api.finishParticipantLogin()
            } catch {
                genderError = "Die Auswahl konnte nicht gespeichert werden. Bitte erneut versuchen."
            }
        }
    }

    private func restartScreensaverTimer() {
        screensaverTask?.cancel()
        showScreensaver = false

        guard !showAdminLogin else {
            screensaverTask = nil
            return
        }

        screensaverTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                return
            }

            guard !showKeyboard,
                  !showInfoSupport,
                  !showGenderChoice,
                  !showPINSetup,
                  !showAdminLogin,
                  !isLoading else { return }

            showScreensaver = true
        }
    }

    private func suspendScreensaver() {
        screensaverTask?.cancel()
        screensaverTask = nil
        showScreensaver = false
    }
}

private struct ParticipantPINSetupView: View {
    let isSubmitting: Bool
    let errorMessage: String?
    let onCancel: () -> Void
    let onSave: (String, String) -> Void
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var activeField = PINSetupField.pin

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()
                if proxy.size.width > 900 {
                    HStack(spacing: 24) {
                        setupDetails
                            .frame(maxWidth: 420)
                        numberKeyboard
                            .frame(maxWidth: 620)
                    }
                    .padding(28)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            setupDetails
                            numberKeyboard
                        }
                        .padding(24)
                    }
                }
            }
        }
    }

    private var setupDetails: some View {
        VStack(spacing: 18) {
            HStack {
                Text("DEINE PERSÖNLICHE PIN")
                    .font(.caption.bold()).tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Spacer()
                Button(action: onCancel) {
                    Label("Abbrechen", systemImage: "xmark")
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(SecretMatchTheme.border))
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
                .accessibilityHint("Bricht die PIN-Anlage ab und kehrt zur Nummerneingabe zurück")
            }
            Text(activeField == .pin ? "Lege deine PIN fest" : "PIN wiederholen")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Du brauchst diese zweistellige PIN bei jedem weiteren Login.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)

            pinField("Neue PIN", value: pin, field: .pin)
            pinField("PIN wiederholen", value: confirmation, field: .confirmation)

            Button("PIN speichern") { saveIfValid() }
                .buttonStyle(SecretPrimaryButtonStyle())
                .disabled(!canSave)
            if isSubmitting { ProgressView().tint(.white) }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
            } else if !confirmation.isEmpty && pin != confirmation {
                Text("Die beiden PINs stimmen noch nicht überein.")
                    .font(.footnote.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
            }
        }
        .frame(maxWidth: 620)
        .secretCard(cornerRadius: 28, padding: 28)
    }

    private var numberKeyboard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(activeField == .pin ? "1" : "2")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(SecretMatchTheme.secondary)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(activeField == .pin ? "SCHRITT 1 VON 2" : "SCHRITT 2 VON 2")
                        .font(.caption.bold())
                        .tracking(1.3)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text(activeField == .pin ? "Neue PIN eingeben" : "Dieselbe PIN bestätigen")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            CustomNumberKeyboard(
                text: activePIN,
                doneLabel: activeField == .pin ? "Weiter zur Bestätigung" : "PIN speichern",
                placeholder: "PIN…",
                maxDigits: 2,
                obscuresText: true,
                showsCloseButton: false
            ) {
                if activeField == .pin, pin.count == 2 {
                    activeField = .confirmation
                } else {
                    saveIfValid()
                }
            }
        }
        .disabled(isSubmitting)
    }

    private var activePIN: Binding<String> {
        Binding(
            get: { activeField == .pin ? pin : confirmation },
            set: { value in
                if activeField == .pin {
                    pin = value
                } else {
                    confirmation = value
                }
            }
        )
    }

    private func pinField(_ title: String, value: String, field: PINSetupField) -> some View {
        Button {
            activeField = field
        } label: {
            HStack {
                Text(title)
                    .font(.callout.bold())
                    .foregroundStyle(field == activeField ? SecretMatchTheme.secondary : SecretMatchTheme.muted)
                Spacer()
                Text(value.isEmpty ? "– –" : String(repeating: "•", count: value.count))
                    .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(SecretMatchTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(field == activeField ? SecretMatchTheme.secondary : SecretMatchTheme.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value.isEmpty ? "Leer" : "\(value.count) Stellen eingegeben")
    }

    private var canSave: Bool {
        !isSubmitting && pin.count == 2 && confirmation.count == 2 && pin == confirmation
    }

    private func saveIfValid() {
        guard canSave else { return }
        onSave(pin, confirmation)
    }
}

private enum PINSetupField {
    case pin
    case confirmation
}

private enum LoginField {
    case number
    case pin
}
