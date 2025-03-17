import SwiftUI

struct TravelTimeInfoView: View {
    let travelTime: TimeInterval?
    let distance: Double?
    
    // Add state properties to animate changes
    @State private var animatedTravelMinutes: Double = 0
    @State private var animatedDistance: Double = 0
    @State private var isVisible: Bool = false
    
    var formattedTravelTime: String {
        let minutes = Int(animatedTravelMinutes)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hr \(remainingMinutes) min"
        }
    }
    
    var formattedDistance: String {
        if animatedDistance >= 1000 {
            let km = animatedDistance / 1000
            return String(format: "%.1f km", km)
        } else {
            return "\(Int(animatedDistance)) m"
        }
    }
    
    // Calculate actual travel minutes for animation target
    private var actualTravelMinutes: Double {
        guard let time = travelTime else { return 0 }
        return Double(Int(ceil(time / 60)))
    }
    
    // Calculate actual distance for animation target
    private var actualDistance: Double {
        guard let distance = distance else { return 0 }
        return distance
    }
    
    var body: some View {
        HStack {
            Image(systemName: "car.fill")
                .font(.system(size: 14))
                .foregroundStyle(.blue)
                .symbolEffect(.bounce, options: .repeat(2), value: actualTravelMinutes)
            
            Text("\(formattedTravelTime)")
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
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            // Start with zero values
            animatedTravelMinutes = 0
            animatedDistance = 0
            
            // Appear animation
            withAnimation(.easeInOut(duration: 0.5)) {
                isVisible = true
            }
            
            // Start numeric animations
            animateToActualValues()
        }
        .onChange(of: actualTravelMinutes) {
            animateToActualValues()
        }
        .onChange(of: actualDistance) {
            animateToActualValues()
        }
    }
    
    private func animateToActualValues() {
        // Animate travel time
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            animatedTravelMinutes = actualTravelMinutes
        }
        
        // Animate distance with slight delay for visual appeal
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
            animatedDistance = actualDistance
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TravelTimeInfoView(travelTime: 1200, distance: 5600)
        TravelTimeInfoView(travelTime: 3500, distance: 25000)
        TravelTimeInfoView(travelTime: 600, distance: 2800)
    }
    .padding()
    .background(Color(UIColor.secondarySystemBackground))
}
