import SwiftUI

struct TravelTimeInfoView: View {
    let travelTime: TimeInterval?
    let distance: Double?
    
    var formattedTravelTime: String {
        guard let time = travelTime else { return "Unknown" }
        
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hr \(remainingMinutes) min"
        }
    }
    
    var formattedDistance: String {
        guard let distance = distance else { return "Unknown" }
        
        if distance >= 1000 {
            let km = distance / 1000
            return String(format: "%.1f km", km)
        } else {
            return "\(Int(distance)) m"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "car.fill")
                .font(.system(size: 14))
                .foregroundStyle(.blue)
            
            Text("To School: \(formattedTravelTime)")
                .font(.caption)
                .fontWeight(.medium)
            
            Text("•")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Text("\(formattedDistance)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
}
