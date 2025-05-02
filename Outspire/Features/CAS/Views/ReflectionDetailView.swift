import SwiftUI
import Toasts

struct ReflectionDetailView: View {
    let reflection: Reflection
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.presentToast) var presentToast

    private var learningOutcomes: [(String, String, String)] {
        var outcomes: [(String, String, String)] = []
        if let v = reflection.c_lo1, !v.isEmpty { outcomes.append(("brain.head.profile", "Awareness", "Increase your awareness of your strengths and areas for growth")) }
        if let v = reflection.c_lo2, !v.isEmpty { outcomes.append(("figure.walk.motion", "Challenge", "Undertaken new challenges")) }
        if let v = reflection.c_lo3, !v.isEmpty { outcomes.append(("lightbulb", "Initiative", "Planned and initiated activities")) }
        if let v = reflection.c_lo4, !v.isEmpty { outcomes.append(("person.2", "Collaboration", "Worked collaboratively with others")) }
        if let v = reflection.c_lo5, !v.isEmpty { outcomes.append(("checkmark.seal", "Commitment", "Shown perseverance and commitment on your activities")) }
        if let v = reflection.c_lo6, !v.isEmpty { outcomes.append(("globe.americas", "Global Value", "Engaged with issues of global importance")) }
        if let v = reflection.c_lo7, !v.isEmpty { outcomes.append(("shield.lefthalf.filled", "Ethics", "Considered the ethical implications of your actions")) }
        if let v = reflection.c_lo8, !v.isEmpty { outcomes.append(("wrench.and.screwdriver", "New Skills", "Developed new skills")) }
        return outcomes
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reflection.C_Title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(formatDate(reflection.C_Date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Summary Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(reflection.C_Summary)
                            .font(.body)
                    }

                    Divider()

                    // Content Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(reflection.C_Content)
                            .font(.body)
                    }

                    if !learningOutcomes.isEmpty {
                        Divider()

                        // Learning Outcomes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Learning Outcomes")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            ForEach(learningOutcomes, id: \.1) { icon, title, description in
                                LearningOutcomeExplanationRow(
                                    icon: icon,
                                    title: title,
                                    explanation: description
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reflection Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = reflection.C_Title
                            let toast = ToastValue(
                                icon: Image(systemName: "doc.on.clipboard"),
                                message: "Title Copied to Clipboard"
                            )
                            presentToast(toast)
                        } label: {
                            Label("Copy Title", systemImage: "textformat")
                        }

                        Button {
                            UIPasteboard.general.string = reflection.C_Summary
                            let toast = ToastValue(
                                icon: Image(systemName: "doc.on.clipboard"),
                                message: "Summary Copied to Clipboard"
                            )
                            presentToast(toast)
                        } label: {
                            Label("Copy Summary", systemImage: "doc.text")
                        }

                        Button {
                            UIPasteboard.general.string = reflection.C_Content
                            let toast = ToastValue(
                                icon: Image(systemName: "doc.on.clipboard"),
                                message: "Content Copied to Clipboard"
                            )
                            presentToast(toast)
                        } label: {
                            Label("Copy Content", systemImage: "doc.text")
                        }

                        Button {
                            let all = """
                            Title: \(reflection.C_Title)
                            Date: \(formatDate(reflection.C_Date))
                            Summary: \(reflection.C_Summary)
                            Content: \(reflection.C_Content)
                            """
                            UIPasteboard.general.string = all
                            let toast = ToastValue(
                                icon: Image(systemName: "doc.on.clipboard"),
                                message: "Reflection Copied to Clipboard"
                            )
                            presentToast(toast)
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = formatter.date(from: dateString) ?? Date()
        let output = DateFormatter()
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }
}

#if DEBUG
struct ReflectionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleReflection = Reflection(
            C_RefID: "1",
            C_Title: "My Reflection on Leadership",
            C_Summary: "This is a summary of my experiences as a team leader during the club activities.",
            C_Content: "During this semester, I had the opportunity to lead our team in various activities. It was challenging but rewarding to organize events, delegate tasks, and ensure everyone was engaged and contributing. I learned that effective communication is key to successful leadership, and I've improved my ability to listen to team members and incorporate their feedback. The experience has made me more confident in my leadership abilities while also teaching me to be humble and open to learning from others.",
            C_Date: "2023-10-15 12:00:00",
            C_GroupNo: "G123",
            c_lo1: "Awareness",
            c_lo2: "Challenge",
            c_lo3: "Initiative",
            c_lo4: "Collaboration",
            c_lo5: nil,
            c_lo6: nil,
            c_lo7: nil,
            c_lo8: nil
        )

        ReflectionDetailView(reflection: sampleReflection)
    }
}
#endif
