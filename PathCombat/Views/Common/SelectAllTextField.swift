import SwiftUI
import AppKit

private final class FocusSelectingTextField: NSTextField {
    private var selectAllOnNextMouseDown = false

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            selectAllOnNextMouseDown = true
            currentEditor()?.selectAll(nil)
        }
        return result
    }

    override func mouseDown(with event: NSEvent) {
        let shouldReselect = selectAllOnNextMouseDown
        selectAllOnNextMouseDown = false
        super.mouseDown(with: event)
        if shouldReselect {
            currentEditor()?.selectAll(nil)
        }
    }
}

private extension View {
    func selectAllFieldStyle() -> some View {
        self
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(5)
    }
}

struct SelectAllTextField: View {
    var placeholder: String
    @Binding var text: String

    init(_ placeholder: String = "", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        SelectAllTextFieldRepresentable(placeholder: placeholder, text: $text)
            .selectAllFieldStyle()
    }
}

private struct SelectAllTextFieldRepresentable: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let field = FocusSelectingTextField()
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.stringValue = text
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        guard nsView.currentEditor() == nil, nsView.stringValue != text else { return }
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text = field.stringValue
        }
    }
}

struct SelectAllIntField: View {
    @Binding var value: Int
    let formatter: NumberFormatter

    var body: some View {
        SelectAllIntFieldRepresentable(value: $value, formatter: formatter)
            .selectAllFieldStyle()
    }
}

private struct SelectAllIntFieldRepresentable: NSViewRepresentable {
    @Binding var value: Int
    let formatter: NumberFormatter

    func makeNSView(context: Context) -> NSTextField {
        let field = FocusSelectingTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.stringValue = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        guard nsView.currentEditor() == nil else { return }
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(value)
        if nsView.stringValue != formatted {
            nsView.stringValue = formatted
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, formatter: formatter)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var value: Int
        let formatter: NumberFormatter

        init(value: Binding<Int>, formatter: NumberFormatter) {
            self._value = value
            self.formatter = formatter
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField,
                  let number = formatter.number(from: field.stringValue) else { return }
            value = number.intValue
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            field.stringValue = formatter.string(from: NSNumber(value: value)) ?? String(value)
        }
    }
}
