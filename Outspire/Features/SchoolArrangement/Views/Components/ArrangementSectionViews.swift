import SwiftUI

struct MonthSection: View {
    let group: ArrangementGroup
    let toggleGroup: () -> Void
    let toggleItem: (String) -> Void
    let fetchDetail: (SchoolArrangementItem) -> Void
    let isLoadingDetail: Bool
    let shouldAnimate: Bool
    let isSmallScreen: Bool
    let transitionDuration: Double
    let staggerDelay: Double
    
    @State private var headerHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Button(action: {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                    toggleGroup()
                }
            }) {
                HStack {
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    
                    Image(systemName: group.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(group.isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: group.isExpanded)
                        .scaleEffect(headerHovered ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: headerHovered)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .onHover { isHovered in
                    headerHovered = isHovered
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .contentTransition(.opacity)
            .id("header-\(group.id)")
            
            // Items for this month
            if group.isExpanded {
                VStack(spacing: 12) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        ArrangementItemView(
                            item: item,
                            toggleItem: { toggleItem(item.id) },
                            fetchDetail: { fetchDetail(item) },
                            isLoadingDetail: isLoadingDetail,
                            shouldAnimate: shouldAnimate,
                            staggerDelay: staggerDelay,
                            itemIndex: index
                        )
                        .id("item-\(item.id)")
                        .transition(.asymmetric(
                            insertion: .opacity
                                .combined(with: .scale(scale: 0.95, anchor: .top))
                                .combined(with: .offset(y: -5))
                                .animation(.spring(response: 0.4, dampingFraction: 0.65)
                                    .delay(Double(index) * 0.05)),
                            removal: .opacity
                                .combined(with: .scale(scale: 0.95, anchor: .top))
                                .animation(.easeOut(duration: 0.2))
                        ))
                    }
                }
            }
        }
        .padding(.top, 4)
        .opacity(shouldAnimate ? 1 : 0)
        .offset(y: shouldAnimate ? 0 : 20)
        // Only animate on larger screens or first appearance
        .animation(
            (isSmallScreen && AnimationManager.shared.hasAnimated(viewId: "SchoolArrangementView"))
            ? nil
            : .spring(response: 0.5, dampingFraction: 0.8).delay(transitionDuration * 0.2),
            value: shouldAnimate
        )
    }
}

struct ArrangementItemView: View {
    let item: SchoolArrangementItem
    let toggleItem: () -> Void
    let fetchDetail: () -> Void
    let isLoadingDetail: Bool
    let shouldAnimate: Bool
    let staggerDelay: Double
    let itemIndex: Int
    
    @State private var buttonHovered = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with title and date
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isPressed = true
                    // Small haptic feedback for toggle action
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.5)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isPressed = false
                            toggleItem()
                        }
                    }
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Text(item.publishDate)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                        .rotationEffect(.degrees(item.isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: item.isExpanded)
                        .scaleEffect(buttonHovered ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: buttonHovered)
                }
                .contentTransition(.opacity)
                .onHover { isHovered in
                    buttonHovered = isHovered
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Week numbers
            if !item.weekNumbers.isEmpty {
                weekNumbersView
            }
            
            // View details button when expanded
            if item.isExpanded {
                ViewDetailButton(
                    action: fetchDetail,
                    isLoading: isLoadingDetail
                )
                .padding(.top, 4)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: item.isExpanded)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .contentShape(Rectangle())
        .opacity(shouldAnimate ? 1 : 0)
        .offset(y: shouldAnimate ? 0 : 20)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(itemIndex) * staggerDelay),
            value: shouldAnimate
        )
    }
    
    private var weekNumbersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(item.weekNumbers, id: \.self) { week in
                    Text("Week \(week)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                }
            }
        }
    }
}

struct ViewDetailButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    @State private var isPressed = false
    @State private var hovered = false
    @State private var opacity: Double = 0
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            // Reset press state after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack {
                Text("View as PDF")
                Image(systemName: "doc.viewfinder")
                    .font(.caption)
            }
            .font(.callout)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(hovered ? 0.15 : 0.1))
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
        .opacity(opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1), value: isLoading)
        .onAppear {
            // Fade in animation when button appears
            withAnimation(.easeOut(duration: 0.3).delay(0.05)) {
                opacity = 1
            }
        }
        .onHover { isHovered in
            withAnimation(.easeOut(duration: 0.2)) {
                hovered = isHovered
            }
        }
    }
}
