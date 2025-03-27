import Foundation

#if !targetEnvironment(macCatalyst)
import ActivityKit

extension ClassActivityManager {
    
    // Convenience method to handle class transitions
    func handleClassTransition(
        className: String,
        periodNumber: Int,
        roomNumber: String,
        teacherName: String,
        startTime: Date,
        endTime: Date,
        transitionType: ClassTransitionType
    ) {
        let activityId = "\(periodNumber)_\(className)"
        
        switch transitionType {
        case .start:
            // Starting a new class - either create new or recycle existing
            // End other activities first before starting this one
            endAllActivitiesExcept(activityId: activityId)
            
            startOrUpdateClassActivity(
                className: className,
                periodNumber: periodNumber,
                roomNumber: roomNumber,
                teacherName: teacherName,
                startTime: startTime,
                endTime: endTime
            )
            
        case .update:
            // Just update times for an existing activity
            if let existing = activeClassActivities[activityId] {
                updateExistingActivity(
                    activity: existing,
                    activityId: activityId,
                    startTime: startTime,
                    endTime: endTime
                )
            } else {
                // Create new if doesn't exist
                // End other activities first
                endAllActivitiesExcept(activityId: activityId)
                
                startClassActivity(
                    className: className,
                    periodNumber: periodNumber,
                    roomNumber: roomNumber,
                    teacherName: teacherName,
                    startTime: startTime,
                    endTime: endTime
                )
            }
            
        case .end:
            // End the activity
            endActivity(for: activityId)
        }
    }
    
    // Define transition types
    enum ClassTransitionType {
        case start   // Starting a new class
        case update  // Updating an existing class (e.g., times changed)
        case end     // Ending a class
    }
    
    // Check if an activity exists for a class
    func hasActivityForClass(periodNumber: Int, className: String) -> Bool {
        let activityId = "\(periodNumber)_\(className)"
        return activeClassActivities[activityId] != nil
    }
}
#endif
