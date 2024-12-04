import SwiftUI

struct ClasstableView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    @State private var years: [Year] = []
    @State private var selectedYearId: String = ""
    @State private var timetable: [[String]] = []
    @State private var errorMessage: String?
    @State private var isLoadingYears: Bool = false
    @State private var isLoadingTimetable: Bool = false
    
    var body: some View {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if years.isEmpty {
                            if isLoadingYears {
                                ProgressView("Loading available time range...")
                                    .padding()
                            } else {
                                Text("No available classtable.")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        } else {
                            Picker("Select Year", selection: $selectedYearId) {
                                ForEach(years) { year in
                                    Text(year.W_Year).tag(year.W_YearID)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: selectedYearId) {
                                fetchTimetable()
                            }
                            
                            if isLoadingTimetable {
                                ProgressView("Loading Timetable...")
                            } else if timetable.isEmpty {
                                Text("No timetable available for the selected range.")
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                timetableView
                                    .padding()
                            }
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .navigationTitle("Classtable")
                .onAppear(perform: fetchYears)
            }
    }
    
    private var timetableView: some View {
        VStack(spacing: 10) {
            ForEach(Array(timetable.enumerated()), id: \.offset) { index, row in
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
    
    func fetchYears() {
        isLoadingYears = true
        guard let url = URL(string: "\(Configuration.baseURL)/php/init_year_dropdown.php") else {
            errorMessage = "Invalid URL."
            isLoadingYears = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let sessionId = sessionManager.sessionId {
            Configuration.headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = Configuration.headers
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoadingYears = false
                if let error = error {
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode([Year].self, from: data)
                    self.years = response
                    if let firstYear = self.years.first {
                        self.selectedYearId = firstYear.W_YearID
                        fetchTimetable()
                    }
                } catch {
                    self.errorMessage = "Unable to parse years: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchTimetable() {
        guard !selectedYearId.isEmpty else {
            errorMessage = "Please select a year."
            return
        }
        
        isLoadingTimetable = true
        guard let url = URL(string: "\(Configuration.baseURL)/php/school_student_timetable.php") else {
            errorMessage = "Invalid URL."
            isLoadingTimetable = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let sessionId = sessionManager.sessionId {
            Configuration.headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = Configuration.headers
        request.httpBody = "timetableType=teachertb&yearID=\(selectedYearId)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoadingTimetable = false
                if let error = error {
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    var response = try JSONDecoder().decode([[String]].self, from: data)
                    response[0] = ["", "Mon", "Tue", "Wed", "Thu", "Fri"]
                    self.timetable = response
                } catch {
                    self.errorMessage = "Unable to parse timetable: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct Year: Codable, Identifiable {
    let W_YearID: String
    let W_Year: String
    let W_Term: String
    let W_Yes: String
    let StartDate: String
    let EndDate: String
    
    var id: String { W_YearID }
}
