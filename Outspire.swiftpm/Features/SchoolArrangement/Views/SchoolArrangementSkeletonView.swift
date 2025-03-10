import SwiftUI

struct SchoolArrangementSkeletonView: View {
    @State private var isAnimating = true
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { index in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Title skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 22)
                            .frame(width: 200)
                        
                        Spacer()
                        
                        // Date skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(width: 100)
                    }
                    
                    // Week numbers skeleton
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 24)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .opacity(isAnimating ? 0.6 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                    value: isAnimating
                )
            }
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}
