import SwiftUI

struct UpcomingClassSkeletonView: View {
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

            // Loading message
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading schedule...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.vertical, 8)
        .paddedGlassmorphicCard(horizontalPadding: 0, verticalPadding: 0)
        .shimmering()
    }
}
