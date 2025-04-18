import SwiftUI
#if !targetEnvironment(macCatalyst)
import ColorfulX
#endif
import LocalAuthentication

struct ScoreView: View {
    @StateObject private var viewModel = ScoreViewModel()
    @State private var selectedSubjectId: String?
    @State private var animateIn = false
    @State private var refreshButtonRotation = 0.0
    @EnvironmentObject private var sessionService: SessionService
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager

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
            .opacity(colorScheme == .dark ? 0.15 : 0.3)

            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                .ignoresSafeArea()
#endif

            // Main content
            if !sessionService.isAuthenticated {
                ContentUnavailableView(
                    "Authentication Required",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Please sign in to view your academic grades.")
                )
                .padding()
            } else if viewModel.isUnlocked {
                mainContent
            } else {
                authenticationView
            }
        }
        .navigationTitle("Academic Grades")
        .toolbar {
            toolbarItems
        }
        .onAppear {
            // Only attempt to fetch data if user is logged in
            if sessionService.isAuthenticated && viewModel.isUnlocked && viewModel.terms.isEmpty {
                viewModel.fetchTerms()
            }
            updateGradientForScoreView()
        }
    }

    private var notLoggedInView: some View {
        ContentUnavailableView(
            "Authentication Required",
            systemImage: "person.crop.circle.badge.exclamationmark",
            description: Text("Please sign in to view your academic grades.")
        )
        .padding()
    }

    private var mainContent: some View {
        Group {
            if viewModel.isLoadingTerms && viewModel.terms.isEmpty {
                LoadingView(message: "Loading terms...")
            } else if viewModel.terms.isEmpty && !viewModel.isLoadingTerms {
                ContentUnavailableView(
                    "No Academic Terms",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("No academic terms are available.")
                )
            } else {
                VStack(spacing: 0) {
                    termSelector
                    scoreContent
                }
            }
        }
        .transition(.opacity)
    }

    private var termSelector: some View {
        Group {
            if !viewModel.terms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.terms) { term in
                            TermButton(
                                term: term,
                                isSelected: viewModel.selectedTermId == term.W_YearID,
                                action: {
                                    withAnimation {
                                        // Only fetch if we're changing terms
                                        if viewModel.selectedTermId != term.W_YearID {
                                            viewModel.selectedTermId = term.W_YearID
                                            viewModel.fetchScores()
                                            animateIn = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                    animateIn = true
                                                }
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(UIColor.tertiarySystemBackground))
            }
        }
    }

    private var scoreContent: some View {
        Group {
            if viewModel.isLoading {
                ScoreSkeletonView()
                    .transition(.opacity)
            } else if viewModel.scores.isEmpty {
                ContentUnavailableView(
                    "No Scores Available",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("There are no scores available for this term yet.")
                )
                .transition(.opacity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.scores.enumerated()), id: \.element.id) { index, subject in
                            SubjectScoreCard(
                                subject: subject,
                                isExpanded: selectedSubjectId == subject.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if selectedSubjectId == subject.id {
                                            selectedSubjectId = nil
                                        } else {
                                            selectedSubjectId = subject.id
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .offset(y: animateIn ? 0 : 30)  // Reduced offset for smoother animation
                            .opacity(animateIn ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(index) * 0.04),  // Slightly faster staggered delay
                                value: animateIn
                            )
                        }

                        // Add space at the bottom for better scrolling
                        Color.clear.frame(height: 20)
                    }
                    .padding(.top)
                    .id(viewModel.selectedTermId) // This ensures scrolling resets when term changes
                }
                .transition(.opacity)
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorView(
                    errorMessage: errorMessage,
                    retryAction: viewModel.refreshData
                )
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            // Reset animation state when appearing
            animateIn = false

            // Use a shorter delay for better perceived performance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    animateIn = true
                }
            }
        }
        .onChange(of: viewModel.isLoading) { oldValue, isLoading in
            if !isLoading && !viewModel.scores.isEmpty && oldValue {
                // Reset and re-trigger animation when loading completes
                animateIn = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        animateIn = true
                    }
                }
            }
        }
    }

    private var authenticationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Authentication Required")
                .font(.title2)

            Text("Your academic records are protected.")
                .foregroundStyle(.secondary)

            Button("Authenticate", action: viewModel.authenticate)
                .buttonStyle(.borderedProminent)
                .padding(.top)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isLoading || viewModel.isLoadingTerms {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        refreshButtonRotation += 360
                    }

                    // Check if we need to authenticate first
                    if !viewModel.isUnlocked {
                        viewModel.authenticate()
                    } else {
                        viewModel.refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(refreshButtonRotation))
                        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
                }
                .disabled(!sessionService.isAuthenticated || viewModel.isLoading || viewModel.isLoadingTerms)
            }
        }
    }

    // Add method to update gradient for score view
    private func updateGradientForScoreView() {
        gradientManager.updateGradientForView(.score, colorScheme: colorScheme)
    }
}

struct TermButton: View {
    let term: Term
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(term.W_Year)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)

                Text("Term \(term.W_Term)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                        .padding(.top, 2)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SubjectScoreCard: View {
    let subject: Score
    let isExpanded: Bool
    let onTap: () -> Void

    private var subjectColor: Color {
        ClasstableView.getSubjectColor(from: subject.subjectName)
    }

    // Check if this subject has any valid scores
    private var hasAnyScores: Bool {
        return subject.examScores.contains { $0.hasScore }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(subjectColor)
                    .frame(width: 12, height: 12)

                Text(subject.subjectName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // Average score pill
                if subject.averageScore > 0 {
                    HStack(spacing: 4) {
                        Text("Avg: \(String(format: "%.1f", subject.averageScore))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(subjectColor.opacity(0.8))
                    .clipShape(Capsule())
                } else {
                    Text("No scores")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .opacity(hasAnyScores ? 1 : 0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                if hasAnyScores {
                    onTap()
                }
            }

            // Expanded content
            if isExpanded && hasAnyScores {
                Divider()
                    .padding(.horizontal)

                VStack(spacing: 14) {
                    ForEach(subject.examScores.filter { $0.hasScore }) { exam in
                        HStack {
                            Text(exam.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)

                            Spacer()

                            Text(exam.score)
                                .font(.title3.bold())

                            if !exam.level.isEmpty && exam.level != "0" {
                                Text(exam.level)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        scoreGradeColor(exam.level)
                                            .opacity(0.2)
                                    )
                                    .clipShape(Capsule())
                                    .frame(width: 30)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(hasAnyScores ? 1 : 0.7)
    }

    private func scoreGradeColor(_ grade: String) -> Color {
        switch grade {
        case "A*", "A+":
            return .purple
        case "A":
            return .indigo
        case "B":
            return .blue
        case "C":
            return .green
        case "D":
            return .orange
        case "E", "F":
            return .red
        default:
            return .gray
        }
    }
}

struct ScoreSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 12, height: 12)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 16)
                            .frame(width: 100)

                        Spacer()

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 24)
                            .frame(width: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    NavigationStack {
        ScoreView()
    }
}
