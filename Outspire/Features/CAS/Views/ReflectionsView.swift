import SwiftUI
import Toasts
#if !targetEnvironment(macCatalyst)
import ColorfulX
#endif

struct ReflectionsView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = ReflectionsViewModel()
    @State private var showingAddSheet = false
    @State private var animateList = false
    @State private var refreshButtonRotation = 0.0
    @Environment(\.presentToast) var presentToast
    @EnvironmentObject var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            #if !targetEnvironment(macCatalyst)
            ColorfulView(
                color: $gradientManager.gradientColors,
                speed: $gradientManager.gradientSpeed,
                noise: $gradientManager.gradientNoise,
                transitionSpeed: $gradientManager.gradientTransitionSpeed
            )
            .ignoresSafeArea()
            .opacity(colorScheme == .dark ? 0.1 : 0.3)
            #else
            Color(.systemBackground)
                .ignoresSafeArea()
            #endif

            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                .ignoresSafeArea()

            contentView
        }
        .navigationTitle("Reflections")
        .contentMargins(.vertical, 10.0)
        .toolbar {
            ToolbarItem(id: "loadingIndicator", placement: .navigationBarTrailing) {
                if viewModel.isLoadingGroups || viewModel.isLoadingReflections {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            ToolbarItem(id: "refreshButton", placement: .navigationBarTrailing) {
                Button(action: handleRefreshAction) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(refreshButtonRotation))
                }
                .disabled(viewModel.isLoadingGroups || viewModel.isLoadingReflections)
            }
            ToolbarItem(id: "addButton", placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet.toggle() }) {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(viewModel.isLoadingGroups || viewModel.isLoadingReflections || sessionService.userInfo == nil)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            addReflectionSheet
                .environmentObject(sessionService)
        }
        .confirmationDialog(
            "Delete Reflection",
            isPresented: $viewModel.showingDeleteConfirmation,
            actions: { deleteConfirmationActions },
            message: { Text("Are you sure you want to delete this reflection?") }
        )
        .onAppear(perform: {
            handleOnAppear()
            updateGradientForReflections()
        })
        .onChange(of: viewModel.isLoadingReflections) { _ in
            handleLoadingChange()
        }
        .onChange(of: viewModel.errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                let icon = errorMessage.contains("copied") ?
                    "checkmark.circle.fill" : "exclamationmark.circle.fill"
                let toast = ToastValue(
                    icon: Image(systemName: icon).foregroundStyle(.red),
                    message: errorMessage
                )
                presentToast(toast)
            }
        }
    }

    private var contentView: some View {
        Form {
            ReflectionGroupSelectorSection(viewModel: viewModel)
            ReflectionsSection(
                viewModel: viewModel,
                sessionService: sessionService,
                showingAddSheet: $showingAddSheet,
                animateList: animateList
            )
        }
        .scrollContentBackground(.hidden)
        .animation(.spring(response: 0.4), value: viewModel.isLoadingReflections)
        .animation(.spring(response: 0.4), value: viewModel.reflections.isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorMessage)
        .refreshable(action: handleRefresh)
    }

    @ViewBuilder
    private var addReflectionSheet: some View {
        if let studentId = sessionService.userInfo?.studentid {
            AddReflectionSheet(
                availableGroups: viewModel.groups,
                studentId: studentId
            ) {
                viewModel.fetchReflections(forceRefresh: true)
            }
        } else {
            VStack(spacing: 10) {
                Text(">_<")
                    .foregroundStyle(.primary)
                    .font(.title2)
                Text("Maybe you haven't logged in yet?")
                    .foregroundStyle(.primary)
                Text("Unable to retrieve user ID.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private var deleteConfirmationActions: some View {
        Group {
            Button("Delete", role: .destructive) {
                if let reflection = viewModel.reflectionToDelete {
                    viewModel.confirmDelete()
                    let toast = ToastValue(
                        icon: Image(systemName: "trash.fill").foregroundStyle(.red),
                        message: "Reflection Deleted"
                    )
                    presentToast(toast)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func handleOnAppear() {
        if viewModel.groups.isEmpty {
            viewModel.fetchGroups()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateList = true
            }
        }
    }

    private func handleLoadingChange() {
        if !viewModel.isLoadingReflections {
            animateList = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateList = true
                }
            }
        }
    }

    private func handleRefreshAction() {
        withAnimation {
            refreshButtonRotation += 360
        }
        if viewModel.isLoadingReflections { return }

        if viewModel.groups.isEmpty {
            viewModel.fetchGroups(forceRefresh: true)
        } else {
            viewModel.fetchReflections(forceRefresh: true)
        }
    }

    @Sendable private func handleRefresh() async {
        HapticManager.shared.playFeedback(.medium)
        if viewModel.groups.isEmpty {
            viewModel.fetchGroups(forceRefresh: true)
        } else {
            viewModel.fetchReflections(forceRefresh: true)
        }
    }

    private func updateGradientForReflections() {
        #if !targetEnvironment(macCatalyst)
        gradientManager.updateGradientForView(.clubActivities, colorScheme: colorScheme)
        #else
        gradientManager.updateGradient(
            colors: [Color(.systemBackground)],
            speed: 0.0,
            noise: 0.0
        )
        #endif
    }
}

struct ReflectionGroupSelectorSection: View {
    @ObservedObject var viewModel: ReflectionsViewModel

    var body: some View {
        Section {
            if !viewModel.groups.isEmpty {
                Picker("Club", selection: $viewModel.selectedGroupId) {
                    ForEach(viewModel.groups) { group in
                        Text(group.displayName).tag(group.id)
                    }
                }
                .onChange(of: viewModel.selectedGroupId) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.fetchReflections(forceRefresh: true)
                    }
                }
                .disabled(viewModel.isLoadingReflections)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.groups.isEmpty)
            }
        }
    }
}

struct ReflectionsSection: View {
    @ObservedObject var viewModel: ReflectionsViewModel
    let sessionService: SessionService
    @Binding var showingAddSheet: Bool
    let animateList: Bool
    @State private var hasCompletedInitialLoad = false
    @State private var loadAttempted = false
    @Environment(\.presentToast) var presentToast

    var body: some View {
        Section {
            if viewModel.groups.isEmpty && !viewModel.isLoadingGroups {
                Group {
                    if sessionService.userInfo != nil {
                        ErrorView(
                            errorMessage: "No clubs available. Try joining some to continue?",
                            retryAction: {
                                viewModel.fetchGroups(forceRefresh: true)
                                let toast = ToastValue(
                                    icon: Image(systemName: "arrow.clockwise"),
                                    message: "Refreshing clubs..."
                                )
                                presentToast(toast)
                            }
                        )
                    } else {
                        ErrorView(errorMessage: "Please sign in with TSIMS to continue...")
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else if viewModel.isLoadingReflections || !loadAttempted {
                // Use a generic loading skeleton for reflections
                VStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 80)
                            .shimmering()
                            .padding(.horizontal)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isLoadingReflections)
                .onAppear {
                    if !loadAttempted {
                        loadAttempted = true
                        if viewModel.groups.isEmpty {
                            viewModel.fetchGroups()
                        } else if viewModel.reflections.isEmpty {
                            viewModel.fetchReflections(forceRefresh: true)
                        }
                    }
                }
            } else if viewModel.reflections.isEmpty {
                ReflectionEmptyStateView(action: { showingAddSheet.toggle() })
                    .transition(.scale.combined(with: .opacity))
            } else {
                ReflectionsList(viewModel: viewModel, animateList: animateList)
                    .transition(.opacity)
                    .blur(radius: viewModel.isLoadingReflections ? 1.0 : 0)
                    .opacity(viewModel.isLoadingReflections ? 0.7 : 1.0)
            }
        }
        .onChange(of: viewModel.isLoadingReflections) { isLoading in
            if !isLoading {
                hasCompletedInitialLoad = true
            }
        }
    }
}

struct ReflectionsList: View {
    @ObservedObject var viewModel: ReflectionsViewModel
    let animateList: Bool

    var body: some View {
        ForEach(Array(viewModel.reflections.enumerated()), id: \.element.id) { index, reflection in
            ReflectionCardView(
                reflection: reflection,
                onDelete: {
                    viewModel.deleteReflection(reflection)
                }
            )
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .offset(x: animateList ? 0 : 100)
            .opacity(animateList ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7)
                    .delay(Double(index) * 0.05),
                value: animateList
            )
            .contentTransition(.opacity)
        }
    }
}

struct ReflectionEmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
                .padding(.bottom, 8)
            Text("No reflections available")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add a new reflection using the + button")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: action) {
                Label("Add New Reflection", systemImage: "plus.circle")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

private extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
