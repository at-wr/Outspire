import SwiftUI

struct SchoolArrangementSkeletonView: View {
    // Animation states
    @State private var animateItems = false
    
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
                .opacity(animateItems ? 1 : 0.4)
                .offset(y: animateItems ? 0 : 10)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * 0.07),
                    value: animateItems
                )
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animateItems = true
            }
        }
        .onDisappear {
            animateItems = false
        }
    }
}
