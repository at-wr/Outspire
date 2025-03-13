import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var nextPage = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAppeared = false
    
    // Add states for tracking permission status
    @State private var locationPermissionGranted = false
    @State private var notificationPermissionGranted = false
    
    // Add reference to manager objects
    @StateObject private var permissionManager = PermissionManager()
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Outspire",
            description: "Your all-in-one companion for your school life and CAS activities in WFLA.",
            imageName: "sparkles.rectangle.stack",
            imageColor: .blue,
            pageType: .information
        ),
        OnboardingPage(
            title: "Track Your Schedule",
            description: "View your class schedule, check upcoming classes, and never miss a deadline.",
            imageName: "calendar",
            imageColor: .orange,
            pageType: .information
        ),
        OnboardingPage(
            title: "Club Activities",
            description: "Keep track of your club memberships, activities, and achievements.",
            imageName: "person.2.circle",
            imageColor: .green,
            pageType: .information
        ),
        OnboardingPage(
            title: "Academic Performance",
            description: "Monitor your grades and academic progress securely and privately.",
            imageName: "chart.line.uptrend.xyaxis",
            imageColor: .purple,
            pageType: .information
        ),
        OnboardingPage(
            title: "Stay Informed",
            description: "Access school arrangements, lunch menus, and campus information at your fingertips.",
            imageName: "info.circle",
            imageColor: .red,
            pageType: .information
        ),
        OnboardingPage(
            title: "Location Services",
            description: "Enable location to calculate your travel time to school and receive timely reminders.",
            imageName: "location.circle.fill",
            imageColor: .blue,
            pageType: .locationPermission
        ),
        OnboardingPage(
            title: "Notifications",
            description: "Stay informed with morning travel time updates and important school alerts.",
            imageName: "bell.badge.fill",
            imageColor: .red,
            pageType: .notificationPermission
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
                        handleNextAction()
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
            checkPermissionStatus()
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
    
    // Handle checking current permission status
    private func checkPermissionStatus() {
        // Check location permission
        permissionManager.checkLocationPermission { status in
            DispatchQueue.main.async {
                locationPermissionGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            }
        }
        
        // Check notification permission
        permissionManager.checkNotificationPermission { status in
            DispatchQueue.main.async {
                notificationPermissionGranted = (status == .authorized)
            }
        }
    }
    
    // Handle next button action based on current page type
    private func handleNextAction() {
        let currentPageInfo = pages[currentPage]
        
        switch currentPageInfo.pageType {
        case .information:
            // For regular information pages, just go to next page
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
            
        case .locationPermission:
            // For location permission page
            if locationPermissionGranted {
                // Already granted, move to next page
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            } else {
                // Request permission then move to next page
                permissionManager.requestLocationPermission { granted in
                    DispatchQueue.main.async {
                        locationPermissionGranted = granted
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    }
                }
            }
            
        case .notificationPermission:
            // For notification permission page
            if notificationPermissionGranted {
                // Already granted, finish onboarding
                markOnboardingComplete()
                isPresented = false
            } else {
                // Request permission then finish onboarding
                permissionManager.requestNotificationPermission { granted in
                    DispatchQueue.main.async {
                        notificationPermissionGranted = granted
                        
                        // Schedule notifications if permission granted
                        if granted {
                            NotificationManager.shared.scheduleMorningETANotification()
                        }
                        
                        // Complete onboarding regardless of choice
                        markOnboardingComplete()
                        isPresented = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func pageView(for page: OnboardingPage) -> some View {
        switch page.pageType {
        case .information:
            standardPageView(for: page)
        case .locationPermission:
            permissionPageView(
                for: page,
                isGranted: locationPermissionGranted,
                grantedText: "Thank you! This helps calculate your travel time to school.",
                deniedText: "This helps us show your travel time to school and provide timely morning notifications."
            )
        case .notificationPermission:
            permissionPageView(
                for: page,
                isGranted: notificationPermissionGranted,
                grantedText: "Great! You'll receive helpful morning travel notifications.",
                deniedText: "Notifications help you arrive at school on time with morning travel alerts."
            )
        }
    }
    
    @ViewBuilder
    func standardPageView(for page: OnboardingPage) -> some View {
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
    
    @ViewBuilder
    func permissionPageView(for page: OnboardingPage, isGranted: Bool, grantedText: String, deniedText: String) -> some View {
        VStack(spacing: 30) {
            // Icon with permission status indicator
            ZStack {
                Image(systemName: page.imageName)
                    .font(.system(size: 70))
                    .foregroundStyle(page.imageColor)
                    .padding()
                    .background(
                        Circle()
                            .fill(page.imageColor.opacity(0.1))
                            .frame(width: 140, height: 140)
                    )
                
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.green)
                        .background(
                            Circle()
                                .fill(Color(UIColor.systemBackground))
                                .frame(width: 32, height: 32)
                        )
                        .offset(x: 50, y: 50)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGranted)
            
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
            
            // Status text
            Text(isGranted ? grantedText : deniedText)
                .font(.body)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .foregroundStyle(isGranted ? .green : .secondary)
                .padding(.horizontal, 32)
                .frame(maxWidth: 500)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// Updated OnboardingPage struct with page type
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let imageColor: Color
    let pageType: OnboardingPageType
    
    // Default to information type for backward compatibility
    init(title: String, description: String, imageName: String, imageColor: Color, pageType: OnboardingPageType = .information) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.imageColor = imageColor
        self.pageType = pageType
    }
}

// Page type to distinguish between information and permission pages
enum OnboardingPageType {
    case information
    case locationPermission
    case notificationPermission
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
