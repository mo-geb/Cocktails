import Foundation

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case ml, oz, dash, bsp, piece, part, leaf, fill, none

    var id: String { rawValue }

    func displayText(for value: Double) -> String {
        if self == .fill { return String(localized: "fill") }
        if self == .none { return value == 0 ? "" : formatAmount(value) }

        let number = value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : formatAmount(value)

        switch self {
        case .ml:    return "\(number) ml"
        case .oz:    return "\(number) oz"
        case .dash:  return "\(number) dash"
        case .bsp:   return "\(number) bsp"
        case .piece: return "\(number) piece"
        case .part:  return "\(number) part"
        case .leaf:  return "\(number) leaf"
        default:     return number
        }
    }

    private func formatAmount(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}
