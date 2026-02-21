import SpotcastPluginKit
import SwiftUI

struct PluginFormView: View {
    let session: PluginFormSession
    let onCancel: () -> Void
    let onSubmit: ([String: PluginFieldValue]) -> Void

    @State private var values: [String: PluginFieldValue]
    @State private var errorMessage: String?

    init(
        session: PluginFormSession, onCancel: @escaping () -> Void,
        onSubmit: @escaping ([String: PluginFieldValue]) -> Void
    ) {
        self.session = session
        self.onCancel = onCancel
        self.onSubmit = onSubmit
        _values = State(initialValue: Self.initialValues(fields: session.plugin.fields))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(session.plugin.metadata.title)
                .font(.system(size: 17, weight: .semibold))

            Text(session.plugin.metadata.subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(session.plugin.fields) { field in
                        fieldView(field)
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Run") {
                    guard validate() else {
                        return
                    }
                    onSubmit(values)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func fieldView(_ field: PluginField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label)
                .font(.system(size: 13, weight: .medium))

            switch field.type {
            case .text(let multiline):
                if multiline {
                    TextEditor(text: stringBinding(field.id))
                        .font(.system(size: 13, weight: .regular))
                        .frame(minHeight: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                } else {
                    TextField(field.placeholder ?? "", text: stringBinding(field.id))
                        .textFieldStyle(.roundedBorder)
                }
            case .number:
                TextField(field.placeholder ?? "", value: numberBinding(field.id), format: .number)
                    .textFieldStyle(.roundedBorder)
            case .toggle:
                Toggle(isOn: boolBinding(field.id)) {
                    Text(field.placeholder ?? "Enabled")
                }
            case .select(let options):
                Picker(
                    selection: stringBinding(field.id), label: Text(field.placeholder ?? "Select")
                ) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 280, alignment: .leading)
            }
        }
    }

    private func stringBinding(_ id: String) -> Binding<String> {
        Binding {
            guard case .string(let value)? = values[id] else {
                return ""
            }
            return value
        } set: { value in
            values[id] = .string(value)
        }
    }

    private func numberBinding(_ id: String) -> Binding<Double> {
        Binding {
            guard case .number(let value)? = values[id] else {
                return 0
            }
            return value
        } set: { value in
            values[id] = .number(value)
        }
    }

    private func boolBinding(_ id: String) -> Binding<Bool> {
        Binding {
            guard case .bool(let value)? = values[id] else {
                return false
            }
            return value
        } set: { value in
            values[id] = .bool(value)
        }
    }

    private func validate() -> Bool {
        for field in session.plugin.fields where field.required {
            switch values[field.id] {
            case .string(let value):
                if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errorMessage = "\(field.label) is required"
                    return false
                }
            case .none:
                errorMessage = "\(field.label) is required"
                return false
            default:
                continue
            }
        }

        errorMessage = nil
        return true
    }

    private static func initialValues(fields: [PluginField]) -> [String: PluginFieldValue] {
        var output: [String: PluginFieldValue] = [:]

        for field in fields {
            if let defaultValue = field.defaultValue {
                output[field.id] = defaultValue
                continue
            }

            switch field.type {
            case .text:
                output[field.id] = .string("")
            case .number:
                output[field.id] = .number(0)
            case .toggle:
                output[field.id] = .bool(false)
            case .select(let options):
                output[field.id] = .string(options.first ?? "")
            }
        }

        return output
    }
}
