import Foundation

#if !targetEnvironment(macCatalyst)
    import ActivityKit

    class ClassActivityManager {
        static let shared = ClassActivityManager()

        private init() {}

        var activeClassActivities: [String: Activity<ClassActivityAttributes>] = [:]
        private var scheduledEndTasks: [String: Task<Void, Never>] = [:]

        func startOrUpdateClassActivity(
            className: String,
            periodNumber: Int,
            roomNumber: String,
            teacherName: String,
            schedule: [ClassActivityAttributes.ScheduledClass]
        ) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                print("Live Activities are not enabled")
                return
            }

            guard !schedule.isEmpty else {
                print("Skipping Live Activity start because schedule is empty")
                return
            }

            let activityId = "\(periodNumber)_\(className)"

            if activeClassActivities[activityId] == nil {
                endAllActivitiesExcept(activityId: activityId)
            }

            let finalEndDate = schedule.map(\.endTime).max() ?? Date()

            if let existingActivity = activeClassActivities[activityId] {
                update(
                    activity: existingActivity,
                    activityId: activityId,
                    schedule: schedule,
                    finalEndDate: finalEndDate
                )
            } else {
                start(
                    activityId: activityId,
                    className: className,
                    roomNumber: roomNumber,
                    teacherName: teacherName,
                    schedule: schedule,
                    finalEndDate: finalEndDate
                )
            }
        }

        func toggleActivityForClass(
            className: String,
            periodNumber: Int,
            roomNumber: String,
            teacherName: String,
            schedule: [ClassActivityAttributes.ScheduledClass]
        ) -> Bool {
            let activityId = "\(periodNumber)_\(className)"

            if activeClassActivities[activityId] != nil {
                endActivity(for: activityId, dismissalPolicy: .immediate)
                print("Manually ended Live Activity for id: \(activityId)")
                return false
            } else {
                startOrUpdateClassActivity(
                    className: className,
                    periodNumber: periodNumber,
                    roomNumber: roomNumber,
                    teacherName: teacherName,
                    schedule: schedule
                )
                return true
            }
        }

        func endAllActivitiesExcept(activityId: String) {
            for (id, activity) in activeClassActivities where id != activityId {
                Task {
                    if #available(iOS 16.2, *) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await activity.end(dismissalPolicy: .immediate)
                    }
                }
                activeClassActivities.removeValue(forKey: id)
                scheduledEndTasks[id]?.cancel()
                scheduledEndTasks.removeValue(forKey: id)
                print("Ended Live Activity with ID: \(activity.id)")
            }
        }

        func endActivity(for activityId: String, dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
            guard let activity = activeClassActivities[activityId] else { return }

            scheduledEndTasks[activityId]?.cancel()
            scheduledEndTasks.removeValue(forKey: activityId)

            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: dismissalPolicy)
                } else {
                    await activity.end(dismissalPolicy: dismissalPolicy)
                }
                activeClassActivities.removeValue(forKey: activityId)
                print("Ended Live Activity with ID: \(activity.id) using policy: \(dismissalPolicy)")
            }
        }

        func endAllActivities() {
            for (id, activity) in activeClassActivities {
                Task {
                    if #available(iOS 16.2, *) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await activity.end(dismissalPolicy: .immediate)
                    }
                    print("Ended Live Activity with ID: \(activity.id)")
                }
                scheduledEndTasks[id]?.cancel()
            }
            scheduledEndTasks.removeAll()
            activeClassActivities.removeAll()
        }

        func cleanup() {
            for task in scheduledEndTasks.values {
                task.cancel()
            }
            scheduledEndTasks.removeAll()
        }

        // MARK: - Private helpers

        private func start(
            activityId: String,
            className: String,
            roomNumber: String,
            teacherName: String,
            schedule: [ClassActivityAttributes.ScheduledClass],
            finalEndDate: Date
        ) {
            let attributes = ClassActivityAttributes(
                className: className,
                roomNumber: roomNumber,
                teacherName: teacherName
            )

            let contentState = makeContentState(
                from: schedule,
                finalEndDate: finalEndDate
            )

            do {
                let activity: Activity<ClassActivityAttributes>

                if #available(iOS 16.2, *) {
                    activity = try Activity.request(
                        attributes: attributes,
                        content: .init(state: contentState, staleDate: finalEndDate),
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
                scheduleAutomaticEnd(for: activityId, finalEndDate: finalEndDate)
                print("Started Live Activity with ID: \(activity.id)")
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }

        private func update(
            activity: Activity<ClassActivityAttributes>,
            activityId: String,
            schedule: [ClassActivityAttributes.ScheduledClass],
            finalEndDate: Date
        ) {
            let contentState = makeContentState(
                from: schedule,
                finalEndDate: finalEndDate
            )

            Task {
                if #available(iOS 16.2, *) {
                    await activity.update(
                        .init(state: contentState, staleDate: finalEndDate)
                    )
                } else {
                    await activity.update(using: contentState)
                }
            }

            scheduleAutomaticEnd(for: activityId, finalEndDate: finalEndDate)
            print("Updated Live Activity with ID: \(activity.id)")
        }

        private func makeContentState(
            from schedule: [ClassActivityAttributes.ScheduledClass],
            finalEndDate: Date
        ) -> ClassActivityAttributes.ContentState {
            ClassActivityAttributes.ContentState(
                schedule: schedule.sorted(by: { $0.startTime < $1.startTime }),
                generatedAt: Date(),
                finalEndDate: finalEndDate
            )
        }

        private func scheduleAutomaticEnd(for activityId: String, finalEndDate: Date) {
            scheduledEndTasks[activityId]?.cancel()

            let task = Task.detached { [weak self] in
                let remaining = finalEndDate.timeIntervalSinceNow
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }

                await self?.finishActivityIfNeeded(activityId: activityId)
            }

            scheduledEndTasks[activityId] = task
        }

        @MainActor
        private func finishActivityIfNeeded(activityId: String) async {
            guard let activity = activeClassActivities[activityId] else { return }

            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .default)
            } else {
                await activity.end(dismissalPolicy: .default)
            }

            activeClassActivities.removeValue(forKey: activityId)
            scheduledEndTasks[activityId]?.cancel()
            scheduledEndTasks.removeValue(forKey: activityId)
            print("Automatically ended Live Activity with ID: \(activity.id)")
        }
    }
#endif
