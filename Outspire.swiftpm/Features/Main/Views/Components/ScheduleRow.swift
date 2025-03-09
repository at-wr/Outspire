import SwiftUI

struct ScheduleRow: View {
    let period: Int
    let time: String
    let subject: String
    let room: String
    let isSelfStudy: Bool
    
    init(period: Int, time: String, subject: String, room: String, isSelfStudy: Bool = false) {
        self.period = period
        self.time = time
        self.subject = subject
        self.room = room
        self.isSelfStudy = isSelfStudy
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Period indicator
            ZStack {
                Circle()
                    .fill(isSelfStudy ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Text("\(period)")
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(isSelfStudy ? .purple : .blue)
            }
            
            // Class details
            VStack(alignment: .leading, spacing: 2) {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelfStudy ? Color.purple : Color.primary)
                
                HStack(spacing: 8) {
                    Text(room)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !room.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSelfStudy {
                Text("Self-Study")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.1))
                    )
                    .foregroundStyle(.purple)
            }
        }
    }
}
