import Foundation

struct ClassInfo {
    let teacher: String?
    let subject: String?
    let room: String?
    let isSelfStudy: Bool
}

enum ClassInfoParser {
    static func parse(_ classData: String) -> ClassInfo {
        // Class data often comes as "Teacher\nSubject\nRoom" with optional <br> tags
        let normalized = classData
            .replacingOccurrences(of: "<br>", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.isEmpty {
            return ClassInfo(teacher: nil, subject: "Self-Study", room: nil, isSelfStudy: true)
        }

        let parts = normalized
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Common format: [teacher, subject, room]
        let teacher = parts.indices.contains(0) ? parts[0] : nil
        let subject = parts.indices.contains(1) ? parts[1] : parts.first
        let room = parts.indices.contains(2) ? parts[2] : nil

        let isSelfStudy = subject?.localizedCaseInsensitiveContains("self-study") == true
            || subject?.localizedCaseInsensitiveContains("self study") == true

        return ClassInfo(teacher: teacher, subject: isSelfStudy ? "Self-Study" : subject, room: room, isSelfStudy: isSelfStudy)
    }
}
