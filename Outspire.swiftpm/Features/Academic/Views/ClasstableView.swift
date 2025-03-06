import SwiftUI

struct ClasstableView: View {
    @StateObject private var viewModel = ClasstableViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.years.isEmpty {
                        if viewModel.isLoadingYears {
                            LoadingView(message: "Loading available time range...")
                        } else {
                            Text("No available classtable.")
                                .foregroundColor(.red)
                                .padding()
                        }
                    } else {
                        Picker("Select Year", selection: $viewModel.selectedYearId) {
                            ForEach(viewModel.years) { year in
                                Text(year.W_Year).tag(year.W_YearID)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.selectedYearId) {
                            viewModel.fetchTimetable()
                        }
                        
                        if viewModel.isLoadingTimetable {
                            LoadingView(message: "Loading Timetable...")
                        } else if viewModel.timetable.isEmpty {
                            Text("No timetable available for the selected range.")
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            timetableView
                                .padding()
                        }
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Classtable")
            .onAppear(perform: viewModel.fetchYears)
        }
    }
    
    private var timetableView: some View {
        VStack(spacing: 10) {
            ForEach(Array(viewModel.timetable.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 10) {
                    if index > 0 {
                        Text("\(index)")
                            .frame(width: 30, alignment: .leading)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("")
                            .frame(width: 30, alignment: .leading)
                    }
                    
                    ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, cell in
                        if columnIndex > 0 {
                            Text(cell.replacingOccurrences(of: "<br>", with: "\n"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(index == 0 ? .headline : .body)
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(.vertical, index == 0 ? 5 : 10)
                .background(index == 0 ? Color.gray.opacity(0.1) : Color.clear)
                .cornerRadius(8)
                
                if index == 4 {
                    Divider()
                        .padding(.vertical, 10)
                }
            }
        }
    }
}