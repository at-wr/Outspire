import Foundation
import ActivityKit
import SwiftUI

class ClassActivityManager {
    static let shared = ClassActivityManager()
    
    private init() {}
    
    // Store active classes to prevent duplicates
    private var activeClassActivities: [String: Activity<ClassActivityAttributes>] = [:]
    
    // Start a new class activity
    func startClassActivity(
        className: String,
        periodNumber: Int,
        roomNumber: String,
        teacherName: String,
        startTime: Date,
        endTime: Date
    ) {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // Create a unique identifier for this class
        let activityId = "\(periodNumber)_\(className)"
        
        // Don't start if we already have an active activity for this class
        guard activeClassActivities[activityId] == nil else {
            print("Activity already exists for this class")
            return
        }
        
        // Determine initial status
        let initialStatus: ClassActivityAttributes.ClassStatus = Date() < startTime ? .upcoming : .ongoing
        
        // Calculate time remaining and progress
        let now = Date()
        let timeRemaining: TimeInterval
        let progress: Double
        
        if initialStatus == .upcoming {
            timeRemaining = startTime.timeIntervalSince(now)
            progress = 0.0
        } else {
            timeRemaining = endTime.timeIntervalSince(now)
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsed = now.timeIntervalSince(startTime)
            progress = max(0, min(1, elapsed / totalDuration))
        }
        
        // Create attributes and initial content state
        let attributes = ClassActivityAttributes(
            className: className,
            roomNumber: roomNumber,
            teacherName: teacherName
        )
        
        let contentState = ClassActivityAttributes.ContentState(
            startTime: startTime,
            endTime: endTime,
            currentStatus: initialStatus,
            periodNumber: periodNumber,
            progress: progress,
            timeRemaining: timeRemaining
        )
        
        // Start the Live Activity
        do {
            let activity: Activity<ClassActivityAttributes>
            
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            }
            
            // Save reference to the activity
            activeClassActivities[activityId] = activity
            
            print("Started Live Activity with ID: \(activity.id)")
            
            // Schedule periodic updates to keep the countdown and progress accurate
            schedulePeriodicUpdates(activityId: activityId, startTime: startTime, endTime: endTime)
            
            // Schedule end of activity
            scheduleEndOfActivity(activity: activity, endTime: endTime)
            
            // If it's an upcoming class, schedule a status update when it starts
            if initialStatus == .upcoming {
                scheduleStatusUpdate(activity: activity, activityId: activityId, startTime: startTime, endTime: endTime)
            } else {
                // If already ongoing, schedule a status update for "ending soon" when appropriate
                scheduleEndingSoonUpdate(activity: activity, activityId: activityId, endTime: endTime)
            }
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Schedule periodic updates that increase frequency as time gets closer to transitions
    private func schedulePeriodicUpdates(activityId: String, startTime: Date, endTime: Date) {
        // Create a repeating timer that updates the activity state
        let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] timer in
            guard let self = self, let activity = self.activeClassActivities[activityId] else {
                timer.invalidate()
                return
            }
            
            let now = Date()
            
            // Increase update frequency for transitions
            if (activity.content.state.currentStatus == .upcoming && startTime.timeIntervalSince(now) < 300) ||
               (activity.content.state.currentStatus != .upcoming && endTime.timeIntervalSince(now) < 300) {
                // If within 5 minutes of a transition, update more frequently
                timer.tolerance = 5  // Allow some tolerance for system optimization
            } else {
                timer.tolerance = 15  // Default tolerance
            }
            
            self.updateActivityState(activityId: activityId, startTime: startTime, endTime: endTime)
        }
        
        // Make sure the timer continues running even when app is in background
        RunLoop.current.add(timer, forMode: .common)
    }
    
    // Update activity state with current progress and time remaining
    private func updateActivityState(activityId: String, startTime: Date, endTime: Date) {
        guard let activity = activeClassActivities[activityId] else { return }
        
        let now = Date()
        var newStatus = activity.content.state.currentStatus
        let timeRemaining: TimeInterval
        let progress: Double
        
        // Update status based on current time - check and handle transitions
        if now < startTime {
            newStatus = .upcoming
            timeRemaining = startTime.timeIntervalSince(now)
            progress = 0.0
        } else if now >= startTime && now < endTime {
            // Class is in progress
            if endTime.timeIntervalSince(now) <= 300 {
                newStatus = .ending
            } else {
                newStatus = .ongoing
            }
            timeRemaining = max(0, endTime.timeIntervalSince(now))
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsed = now.timeIntervalSince(startTime)
            progress = max(0, min(1, elapsed / totalDuration))
        } else {
            // Class has ended - prepare to end activity
            timeRemaining = 0
            progress = 1.0
            
            // End the activity after the update
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.endActivity(for: activityId)
            }
            return
        }
        
        // Only update if status or progress changed significantly
        let shouldUpdate = newStatus != activity.content.state.currentStatus ||
                          abs(progress - activity.content.state.progress) > 0.01
        
        if shouldUpdate {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.update(
                        .init(state: ClassActivityAttributes.ContentState(
                            startTime: startTime,
                            endTime: endTime,
                            currentStatus: newStatus,
                            periodNumber: activity.content.state.periodNumber,
                            progress: progress,
                            timeRemaining: timeRemaining
                        ), staleDate: nil)
                    )
                } else {
                    await activity.update(
                        using: ClassActivityAttributes.ContentState(
                            startTime: startTime,
                            endTime: endTime,
                            currentStatus: newStatus,
                            periodNumber: activity.content.state.periodNumber,
                            progress: progress,
                            timeRemaining: timeRemaining
                        )
                    )
                }
            }
        }
    }
    
    // Update activity status based on current time
    func updateClassStatus(activityId: String, startTime: Date, endTime: Date) {
        updateActivityState(activityId: activityId, startTime: startTime, endTime: endTime)
    }
    
    // Schedule status update when class starts
    private func scheduleStatusUpdate(activity: Activity<ClassActivityAttributes>, activityId: String, startTime: Date, endTime: Date) {
        let now = Date()
        
        // Only schedule if start time is in the future
        guard startTime > now else { return }
        
        let delay = startTime.timeIntervalSince(now)
        
        // Schedule the status update when class starts
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.activeClassActivities[activityId] != nil else { return }
            
            self.updateClassStatus(activityId: activityId, startTime: startTime, endTime: endTime)
        }
    }
    
    // Schedule status update when class is ending soon (last 5 minutes)
    private func scheduleEndingSoonUpdate(activity: Activity<ClassActivityAttributes>, activityId: String, endTime: Date) {
        let now = Date()
        let endingSoonTime = endTime.addingTimeInterval(-300) // 5 minutes before end
        
        // Only schedule if ending soon time is in the future
        guard endingSoonTime > now else { return }
        
        let delay = endingSoonTime.timeIntervalSince(now)
        
        // Schedule the status update
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.activeClassActivities[activityId] != nil else { return }
            
            self.updateClassStatus(activityId: activityId, startTime: activity.content.state.startTime, endTime: endTime)
        }
    }
    
    // Schedule end of activity
    private func scheduleEndOfActivity(activity: Activity<ClassActivityAttributes>, endTime: Date) {
        let now = Date()
        
        // Add a small buffer after class ends (30 seconds)
        let activityEndTime = endTime.addingTimeInterval(30)
        
        // Only schedule if end time is in the future
        guard activityEndTime > now else {
            // If class has already ended, end the activity right away
            endActivity(for: activity.id)
            return
        }
        
        let delay = activityEndTime.timeIntervalSince(now)
        
        // Schedule the activity to end
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.endActivity(for: activity.id)
        }
    }
    
    // End a specific activity
    func endActivity(for activityId: String) {
        // Find the activity with this ID
        for (id, activity) in activeClassActivities where activity.id == activityId {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
                activeClassActivities.removeValue(forKey: id)
                print("Ended Live Activity with ID: \(activityId)")
            }
            break
        }
    }
    
    // End all activities
    func endAllActivities() {
        for (_, activity) in activeClassActivities {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
                print("Ended Live Activity with ID: \(activity.id)")
            }
        }
        activeClassActivities.removeAll()
    }
}
