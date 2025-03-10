import SwiftUI

// Remove duplicate ShimmeringEffect - use the one from UI/Extensions/View+Shimmering.swift instead

struct SchoolArrangementSkeletonView: View {
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
                            .shimmering()
                        
                        Spacer()
                        
                        // Date skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(width: 100)
                            .shimmering()
                    }
                    
                    // Week numbers skeleton
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 24)
                                .shimmering()
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
        }
        .padding()
    }
}
