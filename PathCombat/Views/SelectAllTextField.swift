import SwiftUI
import AppKit

/// An `NSTextField` subclass that selects all its text whenever it becomes first responder,
/// giving these fields the "click to replace" behavior standard in native macOS apps — the
/// first keystroke replaces the whole value instead of requiring a manual select-all or
/// character-by-character backspacing (which fights formatter-based fields on every
/// unparseable intermediate state, e.g. a briefly-empty number field).
private final class FocusSelectingTextField: NSTextField {
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            DispatchQueue.main.async { [weak self] in
                self?.currentEditor()?.selectAll(nil)
            }
        }
        return result
    }
}

/// A single-value text field (not for comma-separated lists) that selects all its text on
/// focus. See `FocusSelectingTextField` for why.
struct SelectAllTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String

    init(_ placeholder: String = "", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

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

/// An `Int`-valued text field that selects all its text on focus. Tolerates transient
/// unparseable states while editing (e.g. briefly empty) without fighting the user's
/// keystrokes, and snaps back to the canonical formatted value once editing ends.
struct SelectAllIntField: NSViewRepresentable {
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
