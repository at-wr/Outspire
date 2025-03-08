import SwiftUI

struct ScheduleRow: View {
    let period: Int
    let time: String
    let subject: String
    let room: String
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Period \(period)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(width: 90, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if !room.isEmpty {
                    Text(room)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}