import ActivityKit
import Foundation
import SwiftUI
import ClassActivityModule

class LiveActivityService {
    static let shared = LiveActivityService()
    private var currentActivity: Activity<ClassActivityAttributes>?
    
    private init() {}
    
    func startClassActivity(
        day: String,
        periodNumber: Int,
        subject: String,
        teacher: String,
        room: String,
        startTime: Date,
        endTime: Date,
        isCurrentClass: Bool
    ) {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // First end any existing activity
        endCurrentActivity()
        
        // Create the initial content state
        let contentState = ClassActivityAttributes.ContentState(
            isCurrentClass: isCurrentClass,
            periodNumber: periodNumber,
            subject: subject,
            teacher: teacher,
            room: room,
            endTime: endTime,
            startTime: startTime
        )
        
        // Create the activity attributes
        let attributes = ClassActivityAttributes(classDay: day)
        
        // Start the Live Activity
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: .token
            )
            print("Started Live Activity: \(String(describing: currentActivity?.id))")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateClassActivity(
        isCurrentClass: Bool,
        periodNumber: Int,
        subject: String,
        teacher: String,
        room: String,
        startTime: Date,
        endTime: Date
    ) {
        guard let activity = currentActivity else {
            print("No activity to update")
            return
        }
        
        let updatedContentState = ClassActivityAttributes.ContentState(
            isCurrentClass: isCurrentClass,
            periodNumber: periodNumber,
            subject: subject,
            teacher: teacher,
            room: room,
            endTime: endTime,
            startTime: startTime
        )
        
        Task {
            await activity.update(using: updatedContentState)
        }
    }
    
    func endCurrentActivity() {
        if let activity = currentActivity {
            Task {
                await activity.end(dismissalPolicy: .immediate)
                currentActivity = nil
            }
        }
    }
    
    func endAllActivities() {
        Task {
            for activity in Activity<ClassActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}