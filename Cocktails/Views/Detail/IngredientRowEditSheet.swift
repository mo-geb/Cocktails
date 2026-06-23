import SwiftUI

struct IngredientRowEditSheet: View {
    @Binding var draft: RecipeIngredientDraft

    @State private var showPicker = false
    @State private var selectedDetent: PresentationDetent = .medium
    @Environment(\.dismiss) private var dismiss

    private var isEmpty: Bool { draft.ingredient.name.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ingredientHero
                    measurementCard
                    noteCard
                }
                .padding()
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showPicker) {
                IngredientPickerView(
                    selection: $draft.ingredient,
                    onPicked: {
                        showPicker = false
                        selectedDetent = .medium
                    }
                )
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .onChange(of: showPicker) { _, showing in
            selectedDetent = showing ? .large : .medium
        }
    }

    // MARK: - Hero

    private var ingredientHero: some View {
        Button { showPicker = true } label: {
            HStack(spacing: 16) {
                draft.ingredient.displayImage
                    .view(placeholder: draft.ingredient.type.imageName)
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isEmpty ? "Select ingredient" : draft.ingredient.localizedName)
                        .font(.title3.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(isEmpty ? Color.accentColor : Color.primary)

                    Text("Tap to change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Measurement

    private var measurementCard: some View {
        HStack {
            Text("Amount")
            Spacer()
            TextField("0", value: Binding(
                get: { draft.amount ?? 0.0 },
                set: { draft.amount = $0 == 0 ? nil : $0 }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(minWidth: 44)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect()

            Picker("", selection: $draft.unit) {
                ForEach(MeasurementUnit.allCases) { unit in
                    Text(unit.localizedName).tag(unit)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Note

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Note")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.top, 13)
                .padding(.bottom, 6)

            Divider().padding(.leading, 16)

            TextField("e.g. Sweet Vermouth, fresh-squeezed", text: $draft.note, axis: .vertical)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var draft = RecipeIngredientDraft()
    IngredientRowEditSheet(draft: $draft)
}
