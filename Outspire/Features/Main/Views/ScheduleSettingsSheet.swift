import SwiftUI

struct ScheduleSettingsSheet: View {
    @EnvironmentObject var sessionService: SessionService
    @Binding var selectedDay: Int?
    @Binding var setAsToday: Bool
    @Binding var isHolidayMode: Bool
    @Binding var isPresented: Bool
    @Binding var holidayEndDate: Date
    @Binding var holidayHasEndDate: Bool
    @State private var showCountdownForFutureClasses = Configuration.showCountdownForFutureClasses

    @State private var debugOverrideMapView = Configuration.debugOverrideMapView
    @State private var debugShowMapView = Configuration.debugShowMapView

    // Add state for the new setting
    @State private var manuallyHideMapAtSchool = Configuration.manuallyHideMapAtSchool

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
            if !sessionService.isAuthenticated {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    Text("Authentication Required")
                        .font(.title2)
                        .bold()

                    Text("Please sign in to access schedule settings")
                        .foregroundStyle(.secondary)

                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
                .navigationTitle("Schedule Settings")
                .toolbarBackground(Color(UIColor.secondarySystemBackground))
            } else {
                List {
                    // Day selection section
                    Section(header: Text("Day Selection")) {
                        Button {
                            selectedDay = nil
                            isHolidayMode = false
                            setAsToday = false

                        } label: {
                            HStack {
                                if !isCurrentDayWeekend && currentWeekday >= 0 && currentWeekday < 5 {
                                    Text("Today (\(dayName(for: currentWeekday)))")
                                } else {
                                    Text("Today")
                                }

                                Spacer()
                                if selectedDay == nil && !isHolidayMode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)

                        ForEach(0..<5, id: \.self) { index in
                            if index == currentWeekday && !isCurrentDayWeekend {
                                EmptyView()
                            } else {
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
                    }

                    if let day = selectedDay, day != currentWeekday || isCurrentDayWeekend {
                        Section(header: Text("View Mode")) {
                            Toggle("Set as Current Day", isOn: $setAsToday)
                                .foregroundStyle(.primary)
                                .onChange(of: setAsToday) { newValue in
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

                        Toggle("Hide Map When at School", isOn: $manuallyHideMapAtSchool)
                            .onChange(of: manuallyHideMapAtSchool) { newValue in
                                Configuration.manuallyHideMapAtSchool = newValue
                            }
                    }

                    // Debug section
                    Section(header: Text("Developer Options")) {
                        Toggle("Override Map View Display", isOn: $debugOverrideMapView)
                            .onChange(of: debugOverrideMapView) { newValue in
                                Configuration.debugOverrideMapView = newValue
                            }

                        if debugOverrideMapView {
                            Toggle("Show Map View", isOn: $debugShowMapView)
                                .onChange(of: debugShowMapView) { newValue in
                                    Configuration.debugShowMapView = newValue
                                }
                        }
                    }
                }
                .navigationTitle("Schedule Settings")
                .toolbarBackground(Color(UIColor.secondarySystemBackground))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
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
