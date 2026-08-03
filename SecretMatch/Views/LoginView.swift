import SwiftUI
import Combine

struct LoginView: View {
    @State private var number: String = ""
    @EnvironmentObject var api: APIService
    @State private var showKeyboard = false
    @State private var isLoading = false
    @State private var showAdminLogin = false
    @State private var showPrivacyNotice = false
    @State private var showGenderChoice = false
    @State private var genderSubmitting = false
    @State private var genderError: String?
    @State private var errorMessage: String?
    @State private var showScreensaver = false
    @State private var screensaverTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            BrandBackground()

            GeometryReader { proxy in
                ScrollView {
                    VStack {
                        Spacer(minLength: 28)

                VStack(spacing: 34) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 240)
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
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.text)

                        Text("Gib deine Event-Nummer ein und entdecke, wer mit dir matcht.")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.muted)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text(number.isEmpty ? "Deine Nummer eingeben" : number.displayEventNumber)
                            .foregroundStyle(number.isEmpty ? SecretMatchTheme.muted : SecretMatchTheme.text)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)
                            .secretInput(highlighted: showKeyboard)
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showKeyboard = true
                                }
                            }
                    }

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
                            Text("Anmelden")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(SecretPrimaryButtonStyle(fontSize: 21, minHeight: 78))
                    .disabled(isLoading || number.isEmpty)
                    .opacity(number.isEmpty ? 0.55 : 1)

                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Deine Nummer bleibt anonym ·")
                        Button("Datenschutz ansehen") {
                            showKeyboard = false
                            showPrivacyNotice = true
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Öffnet die Datenschutz-Kurzinfo")
                }
                .frame(maxWidth: 680)
                .secretCard(cornerRadius: 30, padding: 50)

                        Spacer(minLength: 28)
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
                        CustomNumberKeyboard(
                            text: $number,
                            doneLabel: "Einloggen",
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

            if showPrivacyNotice {
                PrivacyNoticeView(isPresented: $showPrivacyNotice)
                    .zIndex(40)
            }

            if showGenderChoice {
                ParticipantGenderView(isSubmitting: genderSubmitting, errorMessage: genderError) { gender in
                    submitGender(gender)
                }
                .zIndex(45)
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
        .onChange(of: showPrivacyNotice) { _, _ in restartScreensaverTimer() }
        .onChange(of: showGenderChoice) { _, _ in restartScreensaverTimer() }
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

    private func submitLogin() {
        guard !number.isEmpty, !isLoading else { return }

        showKeyboard = false
        errorMessage = nil
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let needsGender = try await api.login(number: number)
                if needsGender {
                    showGenderChoice = true
                } else {
                    api.finishParticipantLogin()
                }
            } catch {
                errorMessage = "Login fehlgeschlagen. Bitte Nummer prüfen und erneut versuchen."
            }
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
                  !showPrivacyNotice,
                  !showGenderChoice,
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
