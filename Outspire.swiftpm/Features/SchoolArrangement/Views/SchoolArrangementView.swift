import SwiftUI
import Toasts

struct SchoolArrangementView: View {
    @StateObject private var viewModel = SchoolArrangementViewModel()
    @Environment(\.presentToast) var presentToast
    @State private var searchText = ""
    @State private var refreshRotation = 0.0
    @State private var animateIn = false
    @State private var showDetailSheet = false
    
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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.arrangements.isEmpty {
                    SchoolArrangementSkeletonView()
                } else if filteredGroups.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(filteredGroups) { group in
                                monthSection(group)
                            }
                            
                            if viewModel.currentPage < viewModel.totalPages && !viewModel.isLoading {
                                ProgressView("Loading more...")
                                    .padding()
                                    .onAppear {
                                        viewModel.fetchNextPage()
                                    }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await performRefresh()
                    }
                }
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
                    if viewModel.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Button {
                            withAnimation {
                                refreshRotation += 360
                            }
                            viewModel.refreshData()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(refreshRotation))
                                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshRotation)
                        }
                    }
                }
            }
            .sheet(isPresented: $showDetailSheet) {
                if let detail = viewModel.selectedDetail {
                    NavigationStack {
                        SchoolArrangementDetailView(detail: detail)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        animateIn = true
                    }
                }
            }
            .onDisappear {
                animateIn = false
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? 1 : 0.8)
                .animation(.spring(response: 0.6).delay(0.1), value: animateIn)
            
            Text("No Arrangements Found")
                .font(.title3)
                .fontWeight(.medium)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
                .animation(.easeOut.delay(0.2), value: animateIn)
            
            if !searchText.isEmpty {
                Text("Try changing your search terms")
                    .foregroundStyle(.secondary)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut.delay(0.3), value: animateIn)
            } else {
                Text("Pull to refresh or tap the refresh button")
                    .foregroundStyle(.secondary)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut.delay(0.3), value: animateIn)
            }
            
            Button {
                viewModel.refreshData()
            } label: {
                Text("Refresh")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
            }
            .buttonStyle(BorderlessButtonStyle())
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6).delay(0.4), value: animateIn)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func monthSection(_ group: ArrangementGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Button {
                withAnimation(.spring(response: 0.4)) {
                    viewModel.toggleGroupExpansion(group.id)
                }
            } label: {
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
            
            // Items for this month
            if group.isExpanded {
                VStack(spacing: 12) {
                    ForEach(group.items) { item in
                        arrangementItemView(item)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 4)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateIn)
    }
    
    private func arrangementItemView(_ item: SchoolArrangementItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with title and date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(item.publishDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        viewModel.toggleItemExpansion(item.id)
                    }
                } label: {
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Week numbers
            if !item.weekNumbers.isEmpty {
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
            
            // View details button when expanded
            if item.isExpanded {
                viewDetailButton(for: item)
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
        .onTapGesture {
            withAnimation(.spring(response: 0.4)) {
                viewModel.toggleItemExpansion(item.id)
            }
        }
    }
    
    private func viewDetailButton(for item: SchoolArrangementItem) -> some View {
        Button {
            viewModel.fetchArrangementDetail(for: item)
        } label: {
            HStack {
                Text("View Details")
                Image(systemName: "chevron.right")
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
        .disabled(viewModel.isLoadingDetail)
        .overlay {
            if viewModel.isLoadingDetail {
                ProgressView().controlSize(.small)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performRefresh() async {
        viewModel.refreshData()
        // Give some time for the UI to update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
