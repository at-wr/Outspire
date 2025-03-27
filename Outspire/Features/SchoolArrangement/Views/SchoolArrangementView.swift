import SwiftUI
import ColorfulX
import Toasts
import QuickLook

struct SchoolArrangementView: View {
    @StateObject private var viewModel = SchoolArrangementViewModel()
    @Environment(\.presentToast) var presentToast
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager // Add gradient manager
    @State private var searchText = ""
    @State private var refreshButtonRotation = 0.0
    @State private var showDetailSheet = false
    @State private var hasFirstAppeared = false

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

    // Animation constants for consistent timing
    private let transitionDuration = 0.35
    private let staggerDelay = 0.05

    var body: some View {
        NavigationStack {
            ZStack {
                // Add ColorfulX as background
                ColorfulView(
                    color: $gradientManager.gradientColors,
                    speed: $gradientManager.gradientSpeed,
                    noise: $gradientManager.gradientNoise,
                    transitionSpeed: $gradientManager.gradientTransitionSpeed
                )
                .ignoresSafeArea()
                .opacity(colorScheme == .dark ? 0.15 : 0.3) // Reduce opacity more in dark mode

                // Semi-transparent background for better contrast
                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                    .ignoresSafeArea()

                // Content layers
                Group {
                    if viewModel.isLoading && viewModel.arrangements.isEmpty {
                        loadingView
                            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .center)))
                    } else if isEmptyState {
                        emptyStateView
                            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .center)))
                    } else {
                        contentListView
                            .transition(.opacity.combined(with: .asymmetric(
                                insertion: .scale(scale: 0.98, anchor: .top).combined(with: .opacity),
                                removal: .opacity
                            )))
                    }
                }
                .animation(.spring(response: transitionDuration, dampingFraction: 0.86), value: viewModel.isLoading)
                .animation(.spring(response: transitionDuration, dampingFraction: 0.86), value: isEmptyState)
            }
            .navigationTitle("School Arrangements")
            .toolbarBackground(Color(UIColor.secondarySystemBackground))
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by week number or title"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoadingDetail {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        LoadingIndicator(isLoading: viewModel.isLoading)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    RefreshButton(isLoading: viewModel.isLoading, rotation: $refreshButtonRotation, action: {
                        withAnimation {
                            refreshButtonRotation += 360
                        }

                        // Add subtle haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()

                        viewModel.refreshData()
                    })
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
                    .presentationDetents([.large, .medium])
                    .presentationDragIndicator(.visible)
                    .if(UIDevice.current.userInterfaceIdiom == .pad) { view in
                        view.presentationDetents([.large])
                            .presentationContentInteraction(.scrolls)
                    }
            }
            .onChange(of: viewModel.pdfURL) { _, newURL in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetailSheet = newURL != nil
                }
            }
            .onChange(of: viewModel.selectedDetail) { _, newDetail in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetailSheet = newDetail != nil
                }
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
                updateGradientForSchoolArrangements()
            }
            // Assign a stable ID to prevent SwiftUI from rebuilding the view hierarchy
            .id("SchoolArrangementViewStableID")
        }
    }

    // MARK: - View Components

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
                        isSmallScreen: isSmallDevice,
                        transitionDuration: transitionDuration,
                        staggerDelay: staggerDelay
                    )
                    .id(group.id)
                }

                if viewModel.currentPage < viewModel.totalPages && !viewModel.isLoading {
                    loadMoreIndicator
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
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
            .opacity(0.8)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
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

        // Add subtle haptic feedback for errors
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        // Clear the error message after showing toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.errorMessage = nil
        }
    }

    // Add the detail sheet content
    private var detailSheetContent: some View {
        Group {
            if let pdfURL = viewModel.pdfURL {
                UnifiedPDFPreview(url: pdfURL, title: viewModel.selectedDetail?.title ?? "Document")
            } else if viewModel.isLoadingDetail {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Preparing document...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("Content Unavailable")
                        .font(.headline)

                    Text("Unable to load the document content")
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
        }
    }

    // Add method to update gradient for school arrangements
    private func updateGradientForSchoolArrangements() {
        gradientManager.updateGradientForView(.schoolArrangements, colorScheme: colorScheme)
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
