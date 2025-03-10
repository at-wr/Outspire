import SwiftUI
import Toasts
import QuickLook

struct SchoolArrangementView: View {
    @StateObject private var viewModel = SchoolArrangementViewModel()
    @Environment(\.presentToast) var presentToast
    @State private var searchText = ""
    @State private var refreshRotation = 0.0
    @State private var showDetailSheet = false
    @State private var hasFirstAppeared = false
    
    // Animation namespace for matching animation
    @Namespace private var animation
    
    // Track content status
    private var isEmptyState: Bool {
        return filteredGroups.isEmpty && !viewModel.isLoading
    }
    
    // Device adaptive settings
    private let isSmallDevice = UIDevice.isSmallScreen
    private let animationDelay = UIDevice.isSmallScreen ? 0.0 : 0.1
    
    private var filteredGroups: [ArrangementGroup] {
        if searchText.isEmpty {
            return viewModel.arrangementGroups
        } else {
            return viewModel.arrangementGroups.compactMap { group in
                let filteredItems = group.items.filter { item in
                    item.title.localizedCaseInsensitiveContains(searchText) ||
                    item.weekNumbers.contains(where: { String($0).contains(searchText) })
                }
                
                if filteredItems.isEmpty {
                    return nil
                } else {
                    return ArrangementGroup(id: group.id, title: group.title, items: filteredItems, isExpanded: group.isExpanded)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content layers
                Group {
                    if viewModel.isLoading && viewModel.arrangements.isEmpty {
                        loadingView
                            .transition(.opacity)
                    } else if isEmptyState {
                        emptyStateView
                            .transition(.opacity)
                    } else {
                        contentListView
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                .animation(.easeInOut(duration: 0.3), value: isEmptyState)
            }
            .navigationTitle("School Arrangement")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by week number or title"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .sheet(isPresented: $showDetailSheet, onDismiss: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if viewModel.selectedDetail == nil {
                        viewModel.pdfURL = nil
                    }
                }
            }) {
                detailSheetContent
            }
            .onChange(of: viewModel.pdfURL) { _, newURL in
                showDetailSheet = newURL != nil
            }
            .onChange(of: viewModel.selectedDetail) { _, newDetail in
                showDetailSheet = newDetail != nil
            }
            .onChange(of: viewModel.errorMessage) { _, errorMessage in
                if let message = errorMessage {
                    showToast(message)
                }
            }
            .onAppear {
                if !hasFirstAppeared {
                    // Trigger animation only once when view first appears
                    hasFirstAppeared = true
                    viewModel.triggerInitialAnimation(isSmallScreen: isSmallDevice)
                }
            }
            // Assign a stable ID to prevent SwiftUI from rebuilding the view hierarchy
            .id("SchoolArrangementViewStableID")
        }
    }
    
    // MARK: - View Components
    
    private var refreshButton: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            } else {
                RefreshButton(
                    isLoadingActivities: viewModel.isLoading,
                    isLoadingGroups: false,
                    groupsEmpty: false,
                    rotation: $refreshRotation,
                    action: {
                        withAnimation {
                            refreshRotation += 360
                        }
                        viewModel.refreshData()
                    }
                )
            }
        }
    }
    
    private var loadingView: some View {
        SchoolArrangementSkeletonView()
            .id("LoadingSkeletonStableID")
    }
    
    private var contentListView: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                // Group sections
                ForEach(filteredGroups) { group in
                    MonthSection(
                        group: group,
                        toggleGroup: { viewModel.toggleGroupExpansion(group.id) },
                        toggleItem: { viewModel.toggleItemExpansion($0) },
                        fetchDetail: { viewModel.fetchArrangementDetail(for: $0) },
                        isLoadingDetail: viewModel.isLoadingDetail,
                        shouldAnimate: viewModel.shouldAnimate,
                        isSmallScreen: isSmallDevice
                    )
                    .id(group.id)
                }
                
                if viewModel.currentPage < viewModel.totalPages && !viewModel.isLoading {
                    loadMoreIndicator
                }
            }
            .padding()
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    private var loadMoreIndicator: some View {
        ProgressView("Loading more...")
            .padding()
            .onAppear {
                viewModel.fetchNextPage()
            }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            searchText: searchText,
            isAnimated: viewModel.shouldAnimate,
            isSmallScreen: isSmallDevice,
            refreshAction: { viewModel.refreshData() }
        )
        .id("EmptyStateStableID")
    }
    
    private var detailSheetContent: some View {
        Group {
            if let pdfURL = viewModel.pdfURL {
                QuickLookPreview(url: pdfURL)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
            } else if viewModel.isLoadingDetail {
                detailLoadingView
            } else {
                detailErrorView
            }
        }
    }
    
    private var detailLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Preparing document...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var detailErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Content Unavailable")
                .font(.headline)
            
            Text("Unable to load the requested content")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Dismiss") {
                showDetailSheet = false
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Auto-dismiss if no data loaded after a timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if viewModel.pdfURL == nil && !viewModel.isLoadingDetail {
                    showDetailSheet = false
                    viewModel.errorMessage = "Failed to load content"
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performRefresh() async {
        viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func showToast(_ message: String) {
        let toast = ToastValue(
            icon: Image(systemName: "exclamationmark.triangle").foregroundStyle(.red),
            message: message
        )
        presentToast(toast)
        
        // Clear the error message after showing toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.errorMessage = nil
        }
    }
}

// MARK: - Extracted Components

struct EmptyStateView: View {
    let searchText: String
    let isAnimated: Bool
    let isSmallScreen: Bool
    let refreshAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Only animate if we're not on a small screen or if this is the first load
            let animationEnabled = !isSmallScreen || AnimationManager.shared.hasAnimated(viewId: "SchoolArrangementView")
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .opacity(isAnimated ? 1 : 0)
                .scaleEffect(isAnimated ? 1 : 0.8)
                .animation(animationEnabled ? .spring(response: 0.6).delay(0.1) : nil, value: isAnimated)
            
            Text("No Arrangements Found")
                .font(.title3)
                .fontWeight(.medium)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(animationEnabled ? .easeOut.delay(0.2) : nil, value: isAnimated)
            
            Text(searchText.isEmpty ? "Pull to refresh or tap the refresh button" : "Try changing your search terms")
                .foregroundStyle(.secondary)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(animationEnabled ? .easeOut.delay(0.3) : nil, value: isAnimated)
            
            Button(action: refreshAction) {
                Text("Refresh")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
            }
            .buttonStyle(BorderlessButtonStyle())
            .opacity(isAnimated ? 1 : 0)
            .scaleEffect(isAnimated ? 1 : 0.9)
            .animation(animationEnabled ? .spring(response: 0.6).delay(0.4) : nil, value: isAnimated)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct MonthSection: View {
    let group: ArrangementGroup
    let toggleGroup: () -> Void
    let toggleItem: (String) -> Void
    let fetchDetail: (SchoolArrangementItem) -> Void
    let isLoadingDetail: Bool
    let shouldAnimate: Bool
    let isSmallScreen: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Button(action: toggleGroup) {
                HStack {
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: group.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(BorderlessButtonStyle())
            .id("header-\(group.id)")
            
            // Items for this month
            if group.isExpanded {
                VStack(spacing: 12) {
                    ForEach(group.items) { item in
                        ArrangementItemView(
                            item: item,
                            toggleItem: { toggleItem(item.id) },
                            fetchDetail: { fetchDetail(item) },
                            isLoadingDetail: isLoadingDetail
                        )
                        .id("item-\(item.id)")
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 4)
        .opacity(shouldAnimate ? 1 : 0)
        .offset(y: shouldAnimate ? 0 : 20)
        // Only animate on larger screens or first appearance
        .animation(
            (isSmallScreen && AnimationManager.shared.hasAnimated(viewId: "SchoolArrangementView")) 
            ? nil 
            : .spring(response: 0.6, dampingFraction: 0.7).delay(0.1), 
            value: shouldAnimate
        )
    }
}

struct ArrangementItemView: View {
    let item: SchoolArrangementItem
    let toggleItem: () -> Void
    let fetchDetail: () -> Void
    let isLoadingDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with title and date
            Button(action: toggleItem) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Text(item.publishDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .contentShape(Rectangle())
    }
    
    private var weekNumbersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(item.weekNumbers, id: \.self) { week in
                    Text("W\(week)")
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
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
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
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
}
