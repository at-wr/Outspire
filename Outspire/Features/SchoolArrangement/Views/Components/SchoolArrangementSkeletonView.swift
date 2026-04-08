import SwiftUI

struct SchoolArrangementSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 16)

                ForEach(0 ..< 3, id: \.self) { sectionIndex in
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
                        ForEach(0 ..< (sectionIndex == 0 ? 2 : 1), id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 22)
                                        .frame(width: 250)
                                    Spacer()
                                }
                                HStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 16)
                                        .frame(width: 120)
                                    Spacer()
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(0 ..< 3, id: \.self) { _ in
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
                        }
                    }
                }
            }
            .padding()
            .shimmering()
        }
    }
}
