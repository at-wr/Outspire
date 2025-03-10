import SwiftUI
import Toasts

struct SchoolArrangementView: View {
    @StateObject private var viewModel = SchoolArrangementViewModel()
    @Environment(\.presentToast) var presentToast
    @State private var searchText = ""
    @State private var refreshButtonRotation = 0.0
    @State private var animateList = false
    
    private var filteredArrangements: [SchoolArrangementItem] {
        if searchText.isEmpty {
            return viewModel.arrangements
        } else {
            return viewModel.arrangements.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.weekNumbers.contains(where: { String($0).contains(searchText) })
            }
        }
    }
    
    private var groupedArrangements: [String: [SchoolArrangementItem]] {
        var groups: [String: [SchoolArrangementItem]] = [:]
        
        // Group by month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for item in filteredArrangements {
            if let date = dateFormatter.date(from: item.publishDate) {
                dateFormatter.dateFormat = "MMMM yyyy"
                let key = dateFormatter.string(from: date)
                if groups[key] == nil {
                    groups[key] = []
                }
                groups[key]!.append(item)
            } else {
                let key = "Unknown Date"
                if groups[key] == nil {
                    groups[key] = []
                }
                groups[key]!.append(item)
            }
        }
        
        // Sort items within each group by publish date (newest first)
        for key in groups.keys {
            groups[key]!.sort { 
                $0.publishDate > $1.publishDate
            }
        }
        
        return groups
    }
    
    private var sortedGroupKeys: [String] {
        // Sort months chronologically (newest first)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        return groupedArrangements.keys.sorted { key1, key2 in
            if key1 == "Unknown Date" { return false }
            if key2 == "Unknown Date" { return true }
            
            if let date1 = dateFormatter.date(from: key1),
               let date2 = dateFormatter.date(from: key2) {
                return date1 > date2
            }
            return key1 > key2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    if viewModel.isLoading && filteredArrangements.isEmpty {
                        SchoolArrangementSkeletonView()
                    } else if filteredArrangements.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(sortedGroupKeys, id: \.self) { key in
                                    groupSection(title: key, items: groupedArrangements[key] ?? [])
                                }
                                
                                if viewModel.currentPage < viewModel.totalPages {
                                    ProgressView("Loading more...")
                                        .padding()
                                        .onAppear {
                                            viewModel.fetchNextPage()
                                        }
                                }
                            }
                            .padding()
                            .opacity(animateList ? 1 : 0)
                            .offset(y: animateList ? 0 : 20)
                        }
                        .refreshable {
                            await withCheckedContinuation { continuation in
                                viewModel.refreshData()
                                continuation.resume()
                            }
                        }
                    }
                }
            }
            .navigationTitle("School Arrangement")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by week number or title")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(action: {
                            withAnimation {
                                refreshButtonRotation += 360
                            }
                            viewModel.refreshData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(refreshButtonRotation))
                                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
                        }
                    }
                }
            }
            .sheet(item: $viewModel.selectedDetailWrapper) { detailWrapper in
                NavigationStack {
                    SchoolArrangementDetailView(detail: detailWrapper.detail)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .onChange(of: viewModel.errorMessage) { newValue in
                if let errorMessage = newValue {
                    let toast = ToastValue(
                        icon: Image(systemName: "exclamationmark.triangle").foregroundStyle(.red),
                        message: errorMessage
                    )
                    presentToast(toast)
                    
                    // Clear the error message after showing toast
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .onAppear {
                // Animate items in when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateList = true
                    }
                }
            }
            .onDisappear {
                animateList = false
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Arrangements Found")
                .font(.title3)
                .fontWeight(.medium)
            
            if !searchText.isEmpty {
                Text("Try changing your search terms")
                    .foregroundStyle(.secondary)
            } else {
                Text("Pull to refresh or tap the refresh button")
                    .foregroundStyle(.secondary)
            }
            
            Button(action: {
                viewModel.refreshData()
            }) {
                Text("Refresh")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func groupSection(title: String, items: [SchoolArrangementItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    arrangementItemView(item: item)
                }
            }
        }
    }
    
    private func arrangementItemView(item: SchoolArrangementItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    viewModel.toggleExpand(item: item)
                } label: {
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }
            
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
            viewModel.toggleExpand(item: item)
        }
        .animation(.spring(response: 0.3), value: item.isExpanded)
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
        .overlay(
            viewModel.isLoadingDetail ? 
            ProgressView()
                .controlSize(.small) : nil
        )
    }
}
