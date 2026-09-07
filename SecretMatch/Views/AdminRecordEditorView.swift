import SwiftUI

struct AdminRecordTypeOption: Identifiable, Hashable {
    let value: String
    let title: String

    var id: String { value }
}

struct AdminRecordEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let firstNumberLabel: String
    let secondNumberLabel: String
    let typeOptions: [AdminRecordTypeOption]
    let onSave: (String, String, String) async throws -> Void

    @State private var firstNumber: String
    @State private var secondNumber: String
    @State private var selectedType: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        title: String,
        firstNumberLabel: String,
        secondNumberLabel: String,
        typeOptions: [AdminRecordTypeOption],
        initialFirstNumber: String = "",
        initialSecondNumber: String = "",
        initialType: String? = nil,
        onSave: @escaping (String, String, String) async throws -> Void
    ) {
        self.title = title
        self.firstNumberLabel = firstNumberLabel
        self.secondNumberLabel = secondNumberLabel
        self.typeOptions = typeOptions
        self.onSave = onSave
        _firstNumber = State(initialValue: initialFirstNumber.displayEventNumber)
        _secondNumber = State(initialValue: initialSecondNumber.displayEventNumber)
        _selectedType = State(initialValue: initialType ?? typeOptions.first?.value ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Teilnehmernummern") {
                    TextField(firstNumberLabel, text: $firstNumber)
                        .keyboardType(.numberPad)
                    TextField(secondNumberLabel, text: $secondNumber)
                        .keyboardType(.numberPad)
                    if sameNumber {
                        Label("Die beiden Nummern müssen unterschiedlich sein.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                Section("Typ") {
                    Picker("Typ", selection: $selectedType) {
                        ForEach(typeOptions) { option in
                            Text(option.title).tag(option.value)
                        }
                    }
                    .pickerStyle(.inline)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Speichern")
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var firstNormalized: String { firstNumber.normalizedEventNumber }
    private var secondNormalized: String { secondNumber.normalizedEventNumber }
    private var sameNumber: Bool {
        !firstNormalized.isEmpty && firstNormalized == secondNormalized
    }

    private var isValid: Bool {
        isValidNumber(firstNumber)
            && isValidNumber(secondNumber)
            && !sameNumber
            && typeOptions.contains(where: { $0.value == selectedType })
    }

    private func isValidNumber(_ value: String) -> Bool {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        return !cleaned.isEmpty
            && cleaned.count <= 10
            && cleaned.allSatisfy(\.isNumber)
            && cleaned.normalizedEventNumber != "0"
    }

    @MainActor
    private func save() async {
        guard isValid else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await onSave(firstNormalized, secondNormalized, selectedType)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
