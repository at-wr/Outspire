import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var nextPage = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAppeared = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Outspire",
            description: "Your all-in-one companion for your school life and CAS activities in WFLA.",
            imageName: "sparkles.rectangle.stack",
            imageColor: .blue
        ),
        OnboardingPage(
            title: "Track Your Schedule",
            description: "View your class schedule, check upcoming classes, and never miss a deadline.",
            imageName: "calendar",
            imageColor: .orange
        ),
        OnboardingPage(
            title: "Club Activities",
            description: "Keep track of your club memberships, activities, and achievements.",
            imageName: "person.2.circle",
            imageColor: .green
        ),
        OnboardingPage(
            title: "Academic Performance",
            description: "Monitor your grades and academic progress securely and privately.",
            imageName: "chart.line.uptrend.xyaxis",
            imageColor: .purple
        ),
        OnboardingPage(
            title: "Stay Informed",
            description: "Access school arrangements, lunch menus, and campus information at your fingertips.",
            imageName: "info.circle",
            imageColor: .red
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            markOnboardingComplete()
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                
                // Custom page viewer with explicit animation control
                ZStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(for: pages[index])
                            .frame(width: geometry.size.width)
                            .offset(x: CGFloat(index - currentPage) * geometry.size.width)
                            .opacity(index == currentPage ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8),
                                value: currentPage
                            )
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(index == currentPage ? .accentColor : .gray.opacity(0.3))
                    }
                }
                .padding(.vertical, 20)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                markOnboardingComplete()
                                isPresented = false
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "checkmark.circle")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(
                colorScheme == .dark ?
                Color(UIColor.systemBackground) :
                    Color(UIColor.secondarySystemBackground)
            )
        }
        .onAppear {
            hasAppeared = true
        }
        .interactiveDismissDisabled(true)
        .onChange(of: isPresented) { _, newValue in
            if !newValue && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                        isPresented = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Image(systemName: page.imageName)
                .font(.system(size: 70))
                .foregroundStyle(page.imageColor)
                .padding()
                .background(
                    Circle()
                        .fill(page.imageColor.opacity(0.1))
                        .frame(width: 140, height: 140)
                )
                .scaleEffect(currentPage == pages.firstIndex(where: { $0.title == page.title }) ? 1.0 : 0.8)
            
            Text(page.title)
                .font(.largeTitle)
                .fontDesign(.rounded)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(page.description)
                .font(.title3)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
                .frame(maxWidth: 500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let imageColor: Color
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
