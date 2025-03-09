import SwiftUI

struct ScheduleSettingsSheet: View {
    @Binding var selectedDay: Int?
    @Binding var setAsToday: Bool
    @Binding var isHolidayMode: Bool
    @Binding var isPresented: Bool
    @Binding var holidayEndDate: Date
    @Binding var holidayHasEndDate: Bool
    @State private var showCountdownForFutureClasses = Configuration.showCountdownForFutureClasses
    
    var body: some View {
        NavigationStack {
            List {
                // Day selection section
                Section(header: Text("Day Selection")) {
                    Button {
                        selectedDay = nil
                        isHolidayMode = false
                        setAsToday = false
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
                            selectedDay = index
                            isHolidayMode = false
                        } label: {
                            HStack {
                                Text(dayName(for: index))
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
                
                // Preview/Current Day toggle
                if selectedDay != nil {
                    Section(header: Text("View Mode")) {
                        Toggle("Set as Current Day", isOn: $setAsToday)
                            .foregroundStyle(.primary)
                            .onChange(of: setAsToday) { _, newValue in
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
                    .onChange(of: isHolidayMode) { _, enabled in
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
                        .onChange(of: showCountdownForFutureClasses) { _, newValue in
                            Configuration.showCountdownForFutureClasses = newValue
                        }
                }
            }
            .navigationTitle("Schedule Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
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
