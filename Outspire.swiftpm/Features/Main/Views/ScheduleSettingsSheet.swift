import SwiftUI

struct ScheduleSettingsSheet: View {
    @Binding var selectedDay: Int?
    @Binding var setAsToday: Bool
    @Binding var isHolidayMode: Bool
    @Binding var isPresented: Bool
    @Binding var holidayEndDate: Date
    @Binding var holidayHasEndDate: Bool
    @State private var showCountdownForFutureClasses = Configuration.showCountdownForFutureClasses
    
    @Environment(\.dismiss) private var dismiss
    
    private var currentWeekday: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Convert to 0-based index (0 = Monday)
        return weekday == 1 ? 6 : weekday - 2
    }
    
    private var isCurrentDayWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Day selection section
                Section(header: Text("Day Selection")) {
                    Button {
                        selectedDay = nil
                        isHolidayMode = false
                        setAsToday = false
                        
                        // Use a slight delay for dismissal to show the selection UI feedback
                        withAnimation {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Text("Today")
                            Spacer()
                            if selectedDay == nil && !isHolidayMode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    ForEach(0..<5) { index in
                        Button {
                            // Only change selection if it's not the same day or we're on a weekend
                            if index != currentWeekday || isCurrentDayWeekend {
                                selectedDay = index
                                isHolidayMode = false
                                
                                // Use a slight delay for dismissal to show the selection UI feedback
                                withAnimation {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        dismiss()
                                    }
                                }
                            } else {
                                // If selecting the current weekday when not a weekend, just reset to "today" mode
                                selectedDay = nil
                                
                                // Use a slight delay for dismissal to show the selection UI feedback
                                withAnimation {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        dismiss()
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(dayName(for: index))
                                
                                // Add "Today" label for current weekday
                                if index == currentWeekday && !isCurrentDayWeekend {
                                    Text("(Today)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                if selectedDay == index && !isHolidayMode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                // Only show View Mode if selectedDay is set and not the same as today
                if let day = selectedDay, day != currentWeekday || isCurrentDayWeekend {
                    Section(header: Text("View Mode")) {
                        Toggle("Set as Current Day", isOn: $setAsToday)
                            .foregroundStyle(.primary)
                            .onChange(of: setAsToday) { newValue in
                                // When toggling setAsToday, immediately save to configuration
                                Configuration.setAsToday = newValue
                            }
                    }
                }
                
                // Holiday mode section
                Section(header: Text("Holiday Mode")) {
                    Toggle(isOn: $isHolidayMode) {
                        Label("Enable Holiday Mode", systemImage: "sun.max.fill")
                            .foregroundStyle(isHolidayMode ? .orange : .primary)
                    }
                    .onChange(of: isHolidayMode) { enabled in
                        if enabled {
                            selectedDay = nil
                            setAsToday = false
                        }
                    }
                    
                    if isHolidayMode {
                        Toggle("Set End Date", isOn: $holidayHasEndDate)
                        if holidayHasEndDate {
                            DatePicker(
                                "Holiday Ends",
                                selection: $holidayEndDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                }
                
                // Display options
                Section(header: Text("Display Options")) {
                    Toggle("Show Countdown for Future Classes", isOn: $showCountdownForFutureClasses)
                        .onChange(of: showCountdownForFutureClasses) { newValue in
                            Configuration.showCountdownForFutureClasses = newValue
                        }
                }
            }
            .navigationTitle("Schedule Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        return days[index]
    }
}
