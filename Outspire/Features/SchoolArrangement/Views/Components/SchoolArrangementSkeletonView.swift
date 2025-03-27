import SwiftUI

struct SchoolArrangementSkeletonView: View {
    // Animation states
    @State private var animateItems = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { sectionIndex in
                // Section header skeleton
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 22)
                        .frame(width: 150)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, sectionIndex > 0 ? 16 : 0)

                // Items for this section
                VStack(spacing: 12) {
                    ForEach(0..<(sectionIndex == 0 ? 2 : 1), id: \.self) { itemIndex in
                        VStack(alignment: .leading, spacing: 12) {
                            // Title skeleton
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 22)
                                    .frame(width: 250)

                                Spacer()
                            }

                            // Date skeleton
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 16)
                                    .frame(width: 120)

                                Spacer()
                            }

                            // Week numbers skeleton
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 32)
                                    }
                                }
                                .padding(.bottom, 4)
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
                                .delay(Double(sectionIndex * 2 + itemIndex) * 0.07),
                            value: animateItems
                        )
                    }
                }
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
