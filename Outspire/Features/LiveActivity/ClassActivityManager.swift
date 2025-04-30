import Foundation
import SwiftUI

#if !targetEnvironment(macCatalyst)
import ActivityKit

class ClassActivityManager {
    static let shared = ClassActivityManager()

    private init() {}

    internal var activeClassActivities: [String: Activity<ClassActivityAttributes>] = [:]

    func startOrUpdateClassActivity(
        className: String,
        periodNumber: Int,
        roomNumber: String,
        teacherName: String,
        startTime: Date,
        endTime: Date
    ) {
        let now = Date()
if now < startTime && Calendar.current.component(.hour, from: now) < 6 {
    return
}
if #available(iOS 16.2, *) {
            for activity in Activity<ClassActivityAttributes>.activities {
                if activity.attributes.className == className && activity.content.state.periodNumber == periodNumber {
                    activeClassActivities["\(periodNumber)_\(className)"] = activity
                    return
                }
            }
        }
        let activityId = "\(periodNumber)_\(className)"

        if activeClassActivities[activityId] == nil {
            endAllActivitiesExcept(activityId: activityId)
        }

        if let existingActivity = activeClassActivities[activityId] {
            updateExistingActivity(
                activity: existingActivity,
                activityId: activityId,
                startTime: startTime,
                endTime: endTime
            )
            return
        }

        startClassActivity(
            className: className,
            periodNumber: periodNumber,
            roomNumber: roomNumber,
            teacherName: teacherName,
            startTime: startTime,
            endTime: endTime
        )
    }

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
            endActivity(for: activityId)
            return
        }

        Task {
            if #available(iOS 16.2, *) {
                let staleDate = endTime.addingTimeInterval(60)

                await activity.update(
                    .init(state: ClassActivityAttributes.ContentState(
                        startTime: startTime,
                        endTime: endTime,
                        currentStatus: newStatus,
                        periodNumber: activity.content.state.periodNumber,
                        progress: progress,
                        timeRemaining: timeRemaining
                    ), staleDate: staleDate)
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

            scheduleUpdatesForActivity(activity: activity, activityId: activityId, startTime: startTime, endTime: endTime)
        }

        print("Updated existing Live Activity with ID: \(activity.id)")
    }

    private func scheduleUpdatesForActivity(activity: Activity<ClassActivityAttributes>, activityId: String, startTime: Date, endTime: Date) {
        cancelExistingTimers(for: activityId)

        schedulePeriodicUpdates(activityId: activityId, startTime: startTime, endTime: endTime)

        let now = Date()
        if now < startTime {
            scheduleStatusUpdate(activity: activity, activityId: activityId, startTime: startTime, endTime: endTime)
        } else if now < endTime {
            scheduleEndingSoonUpdate(activity: activity, activityId: activityId, endTime: endTime)
        }
    }

    private var activityTimers: [String: [Timer]] = [:]

    private func cancelExistingTimers(for activityId: String) {
        activityTimers[activityId]?.forEach { $0.invalidate() }
        activityTimers[activityId] = []
    }

    private func schedulePeriodicUpdates(activityId: String, startTime: Date, endTime: Date) {
        // Update more frequently for smoother progress
        let timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] timer in
            guard let self = self, let activity = self.activeClassActivities[activityId] else {
                timer.invalidate()
                return
            }

            let now = Date()

            // Adjust tolerance based on new interval
            if (activity.content.state.currentStatus == .upcoming && startTime.timeIntervalSince(now) < 180) ||
               (activity.content.state.currentStatus != .upcoming && endTime.timeIntervalSince(now) < 180) {
                timer.tolerance = 2 // Tighter tolerance when close to start/end
            } else {
                timer.tolerance = 5  // Standard tolerance
            }

            self.updateActivityState(activityId: activityId, startTime: startTime, endTime: endTime)
        }

        if activityTimers[activityId] == nil {
            activityTimers[activityId] = []
        }
        activityTimers[activityId]?.append(timer)

        RunLoop.current.add(timer, forMode: .common)
    }

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

    func cleanup() {
        for (activityId, timers) in activityTimers {
            timers.forEach { $0.invalidate() }
            activityTimers[activityId] = []
        }
    }

    func startClassActivity(
        className: String,
        periodNumber: Int,
        roomNumber: String,
        teacherName: String,
        startTime: Date,
        endTime: Date
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let activityId = "\(periodNumber)_\(className)"

        guard activeClassActivities[activityId] == nil else {
            print("Activity already exists for this class")
            return
        }

        let initialStatus: ClassActivityAttributes.ClassStatus = Date() < startTime ? .upcoming : .ongoing

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

        do {
            let activity: Activity<ClassActivityAttributes>

            if #available(iOS 16.2, *) {
                let staleDate = endTime.addingTimeInterval(60)
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

            activeClassActivities[activityId] = activity

            print("Started Live Activity with ID: \(activity.id)")

            schedulePeriodicUpdates(activityId: activityId, startTime: startTime, endTime: endTime)

            if initialStatus == .upcoming {
                scheduleStatusUpdate(activity: activity, activityId: activityId, startTime: startTime, endTime: endTime)
            } else {
                scheduleEndingSoonUpdate(activity: activity, activityId: activityId, endTime: endTime)
            }
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateActivityState(activityId: String, startTime: Date, endTime: Date) {
        guard let activity = activeClassActivities[activityId] else { return }

        let now = Date()
        var newStatus = activity.content.state.currentStatus
        let timeRemaining: TimeInterval
        let progress: Double

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
            timeRemaining = 0
            progress = 1.0
            // End the activity directly when the time is up
            // Use .default dismissal policy for natural ending
            self.endActivity(for: activityId, dismissalPolicy: .default)
            return
        }

        // Update more frequently if progress changed noticeably or status changed
        let shouldUpdate = newStatus != activity.content.state.currentStatus ||
                          abs(progress - activity.content.state.progress) > 0.005 // Lower threshold for smoother updates

        if shouldUpdate {
            Task {
            if #available(iOS 16.2, *) {
                let staleDate = endTime.addingTimeInterval(60)

                await activity.update(
                    .init(state: ClassActivityAttributes.ContentState(
                        startTime: startTime,
                        endTime: endTime,
                        currentStatus: newStatus,
                        periodNumber: activity.content.state.periodNumber,
                        progress: progress,
                        timeRemaining: timeRemaining
                    ), staleDate: staleDate)
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

    func updateClassStatus(activityId: String, startTime: Date, endTime: Date) {
        updateActivityState(activityId: activityId, startTime: startTime, endTime: endTime)
    }

    private func scheduleStatusUpdate(activity: Activity<ClassActivityAttributes>, activityId: String, startTime: Date, endTime: Date) {
        let now = Date()

        guard startTime > now else { return }

        let delay = startTime.timeIntervalSince(now)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.activeClassActivities[activityId] != nil else { return }

            self.updateClassStatus(activityId: activityId, startTime: startTime, endTime: endTime)
        }
    }

    private func scheduleEndingSoonUpdate(activity: Activity<ClassActivityAttributes>, activityId: String, endTime: Date) {
        let now = Date()
        let endingSoonTime = endTime.addingTimeInterval(-300) // 5 minutes before end

        guard endingSoonTime > now else { return }

        let delay = endingSoonTime.timeIntervalSince(now)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.activeClassActivities[activityId] != nil else { return }

            self.updateClassStatus(activityId: activityId, startTime: activity.content.state.startTime, endTime: endTime)
        }
    }

    func endActivity(for activityId: String, dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
        for (id, activity) in activeClassActivities where activity.id == activityId {
            Task {
                let finalContent = activity.content // Use last known content or a specific 'ended' state if desired
                if #available(iOS 16.2, *) {
                    await activity.end(ActivityContent(state: finalContent.state, staleDate: Date()), dismissalPolicy: dismissalPolicy)
                } else {
                    // Prior to 16.2, content update on end is not directly supported, rely on dismissal policy
                    await activity.end(dismissalPolicy: dismissalPolicy)
                }
                activeClassActivities.removeValue(forKey: id)
                cancelExistingTimers(for: id) // Ensure timers are cancelled on end
                print("Ended Live Activity with ID: \(activityId) using policy: \(dismissalPolicy)")
            }
            break
        }
    }

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

    func toggleActivityForClass(
        className: String,
        periodNumber: Int,
        roomNumber: String,
        teacherName: String,
        startTime: Date,
        endTime: Date
    ) -> Bool {
        let activityId = "\(periodNumber)_\(className)"

        if let existingActivity = activeClassActivities[activityId] {
            // Manually ending should be immediate
            endActivity(for: activityId, dismissalPolicy: .immediate)
            print("Manually ended Live Activity with ID: \(existingActivity.id)")
        return false
        } else {
        startOrUpdateClassActivity(
            className: className,
            periodNumber: periodNumber,
            roomNumber: roomNumber,
            teacherName: teacherName,
            startTime: startTime,
            endTime: endTime
        )
        return true
        }
    }
}
#endif
