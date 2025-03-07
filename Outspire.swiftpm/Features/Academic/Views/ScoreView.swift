import SwiftUI
import LocalAuthentication

struct ScoreView: View {
    @StateObject private var viewModel = ScoreViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isUnlocked {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading scores...")
                    } else if viewModel.scores.isEmpty {
                        Text("No scores available.")
                            .foregroundStyle(.secondary)
                    } else {
                        List(viewModel.scores) { score in
                            VStack(alignment: .leading) {
                                Text(score.courseName)
                                    .font(.headline)
                                
                                HStack {
                                    Text(score.term)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Teacher: \(score.teacher)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Grade: \(score.grade)")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        ErrorView(
                            errorMessage: errorMessage,
                            retryAction: viewModel.authenticate
                        )
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("Authentication Required")
                            .font(.title2)
                        
                        Text("Your academic records are protected.")
                            .foregroundStyle(.secondary)
                        
                        Button("Authenticate", action: viewModel.authenticate)
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Academic Scores")
            .onAppear(perform: viewModel.authenticate)
        }
    }
}

#Preview {
    ScoreView()
}
