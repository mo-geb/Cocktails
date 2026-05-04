import Foundation

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case ml
    case oz
    case dash
    case bsp
    case piece
    case part
    case leaf
    case fill
    case none
    
    var id: String { rawValue }
    
    func displayText(for value: Double) -> String {
        if self == .fill { return String(localized: "fill") }
        if self == .none { return value == 0 ? "" : formatAmount(value) }

        if value.truncatingRemainder(dividingBy: 1) == 0 {
            let count = Int(value)
            switch self {
            case .ml:    return String(localized: "\(count) ml")
            case .oz:    return String(localized: "\(count) oz")
            case .dash:  return String(localized: "\(count) dash")
            case .bsp:   return String(localized: "\(count) bsp")
            case .piece: return String(localized: "\(count) piece")
            case .part:  return String(localized: "\(count) part")
            case .leaf:  return String(localized: "\(count) leaf")
            default: return formatAmount(value)
            }
        } else {
            let formatted = formatAmount(value)
            switch self {
            case .ml:    return "\(formatted) ml"
            case .oz:    return "\(formatted) oz"
            case .dash:  return "\(formatted) dash"
            case .bsp:   return "\(formatted) bsp"
            case .piece: return "\(formatted) piece"
            case .part:  return "\(formatted) part"
            case .leaf:  return "\(formatted) leaf"
            default: return formatted
            }
        }
    }

    private func formatAmount(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}
