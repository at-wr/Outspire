import SwiftUI
import Toasts

struct ReflectionCardView: View {
    let reflection: Reflection
    let onDelete: () -> Void
    @Environment(\.presentToast) var presentToast
    @State private var showingDetailSheet = false

    private var learningOutcomeIcons: [Image] {
        var icons: [Image] = []
        if let v = reflection.c_lo1, !v.isEmpty { icons.append(Image(systemName: "brain.head.profile")) }
        if let v = reflection.c_lo2, !v.isEmpty { icons.append(Image(systemName: "figure.walk.motion")) }
        if let v = reflection.c_lo3, !v.isEmpty { icons.append(Image(systemName: "lightbulb")) }
        if let v = reflection.c_lo4, !v.isEmpty { icons.append(Image(systemName: "person.2")) }
        if let v = reflection.c_lo5, !v.isEmpty { icons.append(Image(systemName: "checkmark.seal")) }
        if let v = reflection.c_lo6, !v.isEmpty { icons.append(Image(systemName: "globe.americas")) }
        if let v = reflection.c_lo7, !v.isEmpty { icons.append(Image(systemName: "shield.lefthalf.filled")) }
        if let v = reflection.c_lo8, !v.isEmpty { icons.append(Image(systemName: "wrench.and.screwdriver")) }
        return icons
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reflection.C_Title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(formatDate(reflection.C_Date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(learningOutcomeIcons.indices, id: \.self) { idx in
                        learningOutcomeIcons[idx]
                            .foregroundColor(.accentColor)
                            .imageScale(.medium)
                    }
                }
            }
            Text(reflection.C_Summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            HapticManager.shared.playFeedback(.light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingDetailSheet = true
            }
        }
        .sheet(isPresented: $showingDetailSheet) {
            ReflectionDetailView(reflection: reflection)
        }
        .contextMenu {
            // Request deletion confirmation instead of immediate deletion
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            // Group Copy options in a submenu like in Activities
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
                Label("Copy", systemImage: "doc.on.clipboard")
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
