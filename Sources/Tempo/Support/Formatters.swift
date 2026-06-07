import Foundation

enum TempoFormatters {
    static let relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let remainder = total % 60
        return "\(minutes)m \(remainder)s"
    }
}
