import CoreLocation
import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var nextPage = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAppeared = false
    @Environment(\.dismiss) private var dismiss

    // Add states for tracking permission status
    @State private var locationPermissionGranted = false
    @State private var notificationPermissionGranted = false

    // Add reference to manager objects
    @StateObject private var permissionManager = PermissionManager()

    // Focus state for keyboard controls
    @FocusState private var buttonFocused: OnboardingButtonFocus?

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Outspire",
            description:
                "Your ultimate companion for WFLA school life! Everything you need, all in one place. \nLet's get started!",
            imageName: "sparkles.rectangle.stack",
            imageColor: .blue,
            pageType: .information
        ),
        OnboardingPage(
            title: "Schedule & Widgets",
            description:
                "Stay on top of your classes and deadlines with smart scheduling. Never miss what matters most.",
            imageName: "calendar",
            imageColor: .orange,
            pageType: .information
        ),
        OnboardingPage(
            title: "CAS Made Simple",
            description:
                "Track your clubs, activities, and achievements effortlessly. Complete with artificial intelligent insights to help you succeed.",
            imageName: "person.2.circle",
            imageColor: .green,
            pageType: .information
        ),
        OnboardingPage(
            title: "Academic Performance",
            description:
                "Track your grades and progress with complete privacy. Your data stays secure and belongs to you.",
            imageName: "lock.document",
            imageColor: .purple,
            pageType: .information
        ),
        OnboardingPage(
            title: "Smart Reminders",
            description:
                "Get personalized travel time calculations and never be late again. We'll help you plan your perfect morning routine.",
            imageName: "location.circle.fill",
            imageColor: .blue,
            pageType: .locationPermission
        ),
        OnboardingPage(
            title: "Stay Connected",
            description:
                "Receive timely updates about your commute and important school news. Stay ahead of what's happening.",
            imageName: "bell.badge.fill",
            imageColor: .red,
            pageType: .notificationPermission
        ),
        OnboardingPage(
            title: "You're All Set!",
            description:
                "Welcome to your enhanced school experience! Everything is ready for you to explore and succeed.",
            imageName: "checkmark.circle.fill",
            imageColor: .green,
            pageType: .information
        ),
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
                        #if targetEnvironment(macCatalyst)
                            Text("Close")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(.tertiarySystemFill))
                                .cornerRadius(6)
                                .foregroundStyle(.primary)
                        #else
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        #endif
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding()
                    .focused($buttonFocused, equals: .close)
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
                            .foregroundColor(
                                index == currentPage ? .accentColor : .gray.opacity(0.3))
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
                            #if targetEnvironment(macCatalyst)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(.quaternarySystemFill))
                                .cornerRadius(8)
                            #endif
                            .foregroundStyle(.secondary)
                        }
                        .keyboardShortcut(.leftArrow, modifiers: [])
                        .focused($buttonFocused, equals: .previous)
                    }

                    Spacer()

                    Button(action: {
                        handleNextAction()
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            Image(
                                systemName: currentPage < pages.count - 1
                                    ? "chevron.right" : "checkmark.circle")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        #if targetEnvironment(macCatalyst)
                            .background(
                                Capsule().fill(Color.accentColor.opacity(0.8))
                            )
                        #else
                            .background(
                                Capsule().fill(Color.accentColor)
                            )
                        #endif
                        .foregroundStyle(.white)
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .keyboardShortcut(.return, modifiers: [])
                    .keyboardShortcut(.space, modifiers: [])
                    .focused($buttonFocused, equals: .next)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(
                colorScheme == .dark
                    ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground)
            )
        }
        .onAppear {
            hasAppeared = true
            checkPermissionStatus()

            // Mark onboarding as active to prevent alerts during onboarding
            ConnectivityManager.shared.setOnboardingActive(true)

            // Set initial focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                buttonFocused = .next
            }
        }
        .interactiveDismissDisabled(true)
        .onDisappear {
            // Mark onboarding as inactive when view disappears
            ConnectivityManager.shared.setOnboardingActive(false)
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                        isPresented = true
                    }
                }
            }
        }
        .onKeyPress(.rightArrow) {
            if currentPage < pages.count - 1 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage += 1
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.leftArrow) {
            if currentPage > 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage -= 1
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            markOnboardingComplete()
            isPresented = false
            return .handled
        }
    }

    // Handle checking current permission status
    private func checkPermissionStatus() {
        // Check location permission
        permissionManager.checkLocationPermission { status in
            DispatchQueue.main.async {
                locationPermissionGranted =
                    (status == .authorizedWhenInUse || status == .authorizedAlways)
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
            // For regular information pages
            if currentPage == pages.count - 1 {
                // This is the final page, complete onboarding
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                markOnboardingComplete()
                isPresented = false
            } else {
                // Move to next page
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            }

        case .locationPermission:
            // For location permission page
            if locationPermissionGranted {
                // Already granted, move to next page
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            } else {
                // Request permission then move to next page
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                permissionManager.requestLocationPermission { granted in
                    DispatchQueue.main.async {
                        locationPermissionGranted = granted

                        // Haptic feedback for permission result
                        let resultFeedback = UINotificationFeedbackGenerator()
                        if granted {
                            resultFeedback.notificationOccurred(.success)
                        } else {
                            resultFeedback.notificationOccurred(.warning)
                        }

                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    }
                }
            }

        case .notificationPermission:
            // For notification permission page
            if notificationPermissionGranted {
                // Already granted, move to final page
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            } else {
                // Request permission then move to final page
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                permissionManager.requestNotificationPermission { granted in
                    DispatchQueue.main.async {
                        notificationPermissionGranted = granted

                        // Use centralized notification management
                        NotificationManager.shared.handleNotificationSettingsChange()

                        // Haptic feedback for permission result
                        let resultFeedback = UINotificationFeedbackGenerator()
                        if granted {
                            resultFeedback.notificationOccurred(.success)
                        } else {
                            resultFeedback.notificationOccurred(.warning)
                        }

                        // Move to final page regardless of permission choice
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
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
                deniedText:
                    "Remember, we never store your privacy!\nThis helps us show your travel time to school and provide timely morning notifications."
            )
        case .notificationPermission:
            permissionPageView(
                for: page,
                isGranted: notificationPermissionGranted,
                grantedText: "Great! You'll receive helpful morning travel notifications.",
                deniedText:
                    "I'll never spam you!\nNotifications help you arrive at school on time with morning travel alerts."
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
                .scaleEffect(
                    currentPage == pages.firstIndex(where: { $0.title == page.title }) ? 1.0 : 0.8)

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
    func permissionPageView(
        for page: OnboardingPage, isGranted: Bool, grantedText: String, deniedText: String
    ) -> some View {
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
        // Make sure to mark onboarding as inactive
        ConnectivityManager.shared.setOnboardingActive(false)
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
    init(
        title: String, description: String, imageName: String, imageColor: Color,
        pageType: OnboardingPageType = .information
    ) {
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

// Enum for focus management
enum OnboardingButtonFocus {
    case previous, next, close
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
