import Foundation
import ActivityKit
import SwiftUI

#if !targetEnvironment(macCatalyst)
class ClassActivityManager {
    static let shared = ClassActivityManager()
    
    private init() {}
    
    // Store active classes to prevent duplicates - change from fileprivate to internal
    internal var activeClassActivities: [String: Activity<ClassActivityAttributes>] = [:]
    
    // Add a new method to check if activity exists and recycle it if needed
    func startOrUpdateClassActivity(
        className: String,
        periodNumber: Int,
        roomNumber: String,
        teacherName: String,
        startTime: Date,
        endTime: Date
    ) {
        // Create a unique identifier for this class
        let activityId = "\(periodNumber)_\(className)"
        
        // End all other active activities if starting a new one
        if activeClassActivities[activityId] == nil {
            endAllActivitiesExcept(activityId: activityId)
        }
        
        // Check if activity already exists
        if let existingActivity = activeClassActivities[activityId] {
            // Update existing activity instead of creating a new one
            updateExistingActivity(
                activity: existingActivity,
                activityId: activityId,
                startTime: startTime,
                endTime: endTime
            )
            return
        }
        
        // If no existing activity, create a new one
        startClassActivity(
            className: className,
            periodNumber: periodNumber,
            roomNumber: roomNumber,
            teacherName: teacherName,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // Helper to end all activities except for a specific one
    internal func endAllActivitiesExcept(activityId: String) {
        for (id, activity) in activeClassActivities where id != activityId {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
                print("Ended Live Activity with ID: \(activity.id)")
                activeClassActivities.removeValue(forKey: id)
            }
        }
    }
    
    // Method to update an existing activity with new times - change from fileprivate to internal
    internal func updateExistingActivity(
        activity: Activity<ClassActivityAttributes>,
        activityId: String,
        startTime: Date,
        endTime: Date
    ) {
        let now = Date()
        var newStatus: ClassActivityAttributes.ClassStatus
        let timeRemaining: TimeInterval
        let progress: Double
        
        // Determine status based on current time
        if now < startTime {
            newStatus = .upcoming
            timeRemaining = startTime.timeIntervalSince(now)
            progress = 0.0
        } else if now >= startTime && now < endTime {
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
            // If class has ended, end the activity
            endActivity(for: activityId)
            return
        }
        
        // Update the activity with new content state
        Task {
            if #available(iOS 16.2, *) {
                // Set staleDate to after the class ends
                let staleDate = endTime.addingTimeInterval(60) // 1 minute after class ends
                
                await activity.update(
                    .init(state: ClassActivityAttributes.ContentState(
                        startTime: startTime,
                        endTime: endTime,
                        currentStatus: newStatus,
                        periodNumber: activity.content.state.periodNumber,
                        progress: progress,
                        timeRemaining: timeRemaining
                    ), staleDate: staleDate) // Add staleDate here
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
            
            // Reschedule updates based on new times
            scheduleUpdatesForActivity(activity: activity, activityId: activityId, startTime: startTime, endTime: endTime)
        }
        
        print("Updated existing Live Activity with ID: \(activity.id)")
    }
    
    // Schedule all needed updates for an activity (new or recycled)
    private func scheduleUpdatesForActivity(activity: Activity<ClassActivityAttributes>, activityId: String, startTime: Date, endTime: Date) {
        // Cancel any existing timers for this activity
        cancelExistingTimers(for: activityId)
        
        // Schedule periodic updates
        schedulePeriodicUpdates(activityId: activityId, startTime: startTime, endTime: endTime)
        
        // Schedule end of activity
        scheduleEndOfActivity(activity: activity, endTime: endTime)
        
        let now = Date()
        // If it's an upcoming class, schedule a status update when it starts
        if now < startTime {
            scheduleStatusUpdate(activity: activity, activityId: activityId, startTime: startTime, endTime: endTime)
        } else if now < endTime {
            // If already ongoing, schedule a status update for "ending soon" when appropriate
            scheduleEndingSoonUpdate(activity: activity, activityId: activityId, endTime: endTime)
        }
    }
    
    // Store timers for activities
    private var activityTimers: [String: [Timer]] = [:]
    
    // Cancel existing timers for an activity
    private func cancelExistingTimers(for activityId: String) {
        activityTimers[activityId]?.forEach { $0.invalidate() }
        activityTimers[activityId] = []
    }
    
    // Modified schedulePeriodicUpdates to store references to timers
    private func schedulePeriodicUpdates(activityId: String, startTime: Date, endTime: Date) {
        let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] timer in
            guard let self = self, let activity = self.activeClassActivities[activityId] else {
                timer.invalidate()
                return
            }
            
            let now = Date()
            
            // Increase update frequency for transitions
            if (activity.content.state.currentStatus == .upcoming && startTime.timeIntervalSince(now) < 300) ||
               (activity.content.state.currentStatus != .upcoming && endTime.timeIntervalSince(now) < 300) {
                timer.tolerance = 5  // Higher frequency updates near transitions
            } else {
                timer.tolerance = 15  // Normal frequency
            }
            
            self.updateActivityState(activityId: activityId, startTime: startTime, endTime: endTime)
        }
        
        // Store the timer
        if activityTimers[activityId] == nil {
            activityTimers[activityId] = []
        }
        activityTimers[activityId]?.append(timer)
        
        // Make sure timer runs in background
        RunLoop.current.add(timer, forMode: .common)
    }
    
    // Update an activity's status based on a specific transition event
    func transitionClassStatus(activityId: String, to status: ClassActivityAttributes.ClassStatus) {
        guard let activity = activeClassActivities[activityId] else { return }
        
        let now = Date()
        let startTime = activity.content.state.startTime
        let endTime = activity.content.state.endTime
        
        var timeRemaining: TimeInterval
        var progress: Double
        
        switch status {
        case .upcoming:
            timeRemaining = startTime.timeIntervalSince(now)
            progress = 0.0
        case .ongoing:
            timeRemaining = endTime.timeIntervalSince(now)
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsed = now.timeIntervalSince(startTime)
            progress = max(0, min(1, elapsed / totalDuration))
        case .ending:
            timeRemaining = endTime.timeIntervalSince(now)
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsed = now.timeIntervalSince(startTime)
            progress = max(0, min(1, elapsed / totalDuration))
        }
        
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(
                    .init(state: ClassActivityAttributes.ContentState(
                        startTime: startTime,
                        endTime: endTime,
                        currentStatus: status,
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
                        currentStatus: status,
                        periodNumber: activity.content.state.periodNumber,
                        progress: progress,
                        timeRemaining: timeRemaining
                    )
                )
            }
        }
        
        print("Transitioned Live Activity to \(status) state")
    }
    
    // Clean up when app terminates
    func cleanup() {
        // Cancel all timers
        for (activityId, timers) in activityTimers {
            timers.forEach { $0.invalidate() }
            activityTimers[activityId] = []
        }
    }
    
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
                // Set staleDate to right after the class ends
                let staleDate = endTime.addingTimeInterval(60) // 1 minute after class ends
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: staleDate),
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
                    // Set staleDate to right after the class ends
                    let staleDate = endTime.addingTimeInterval(60) // 1 minute after class ends
                    
                    await activity.update(
                        .init(state: ClassActivityAttributes.ContentState(
                            startTime: startTime,
                            endTime: endTime,
                            currentStatus: newStatus,
                            periodNumber: activity.content.state.periodNumber,
                            progress: progress,
                            timeRemaining: timeRemaining
                        ), staleDate: staleDate) // Add staleDate here
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
#endif
