import SwiftUI

struct ActivitySkeletonView: View {
    var body: some View {
        VStack(spacing: 15) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    // Title
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .frame(width: 200)

                    // Date
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)
                        .frame(width: 120)

                    // CAS Badges
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 24)
                        }
                    }

                    // Reflection
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 10)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 10)
            }
        }
        .redacted(reason: .placeholder)
    }
}

// Use shared shimmering() from UI/Extensions/View+Shimmering.swift
