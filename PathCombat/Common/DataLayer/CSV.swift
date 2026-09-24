import Foundation

enum CSVWriter {
    static func field(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    static func row(_ values: [String]) -> String {
        values.map(field).joined(separator: ",")
    }
}

enum CSVParser {
    /// Parses RFC4180-style CSV text (quoted fields may contain commas/newlines,
    /// and `""` is an escaped quote) into rows of raw field values.
    static func parseRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var hasContentOnLine = false

        let chars = Array(text)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    }
                    inQuotes = false
                    i += 1
                    continue
                }
                currentField.append(c)
                i += 1
                continue
            }

            switch c {
            case "\"":
                inQuotes = true
                hasContentOnLine = true
                i += 1
            case ",":
                currentRow.append(currentField)
                currentField = ""
                hasContentOnLine = true
                i += 1
            case "\n", "\r":
                if hasContentOnLine || !currentField.isEmpty || !currentRow.isEmpty {
                    currentRow.append(currentField)
                    rows.append(currentRow)
                }
                currentRow = []
                currentField = ""
                hasContentOnLine = false
                if c == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1
                }
                i += 1
            default:
                currentField.append(c)
                hasContentOnLine = true
                i += 1
            }
        }

        if hasContentOnLine || !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }
}
