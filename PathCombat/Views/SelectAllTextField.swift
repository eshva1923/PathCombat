import SwiftUI
import AppKit

/// An `NSTextField` subclass that selects all its text whenever it becomes first responder,
/// giving these fields the "click to replace" behavior standard in native macOS apps — the
/// first keystroke replaces the whole value instead of requiring a manual select-all or
/// character-by-character backspacing (which fights formatter-based fields on every
/// unparseable intermediate state, e.g. a briefly-empty number field).
private final class FocusSelectingTextField: NSTextField {
    /// Set when focus is gained via `becomeFirstResponder` (keyboard/programmatic focus, e.g.
    /// Tab) so we can select-all immediately. For a mouse click, the same click's `mouseDown`
    /// arrives right after and would otherwise collapse that selection back to a caret at the
    /// click point, so `mouseDown` re-applies the selection *after* `super` finishes placing
    /// the caret — selecting-all inside `becomeFirstResponder` alone loses the race.
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

/// Shared chrome for every search field and single-value input in the app: a darker rounded
/// background instead of the plain NSTextField look, applied once here so all call sites stay
/// consistent.
private extension View {
    func selectAllFieldStyle() -> some View {
        self
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(5)
    }
}

/// A single-value text field (not for comma-separated lists) that selects all its text on
/// focus. See `FocusSelectingTextField` for why.
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

/// An `Int`-valued text field that selects all its text on focus. Tolerates transient
/// unparseable states while editing (e.g. briefly empty) without fighting the user's
/// keystrokes, and snaps back to the canonical formatted value once editing ends.
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
