import SwiftUI

struct UpcomingClassSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 18)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 14)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 30)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Class title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 24)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            // Teacher and room skeleton
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 16, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 16)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 16, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 16)
                }
            }
            .padding(.horizontal, 16)
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            // Countdown skeleton
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 12)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 20)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .opacity(isAnimating ? 0.6 : 1)
        .animation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}
