import SwiftUI

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: AppSpace.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.85), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title)
                .font(AppText.label)
            Spacer()
            Text(value)
                .font(AppText.label)
                .foregroundStyle(.secondary)
        }
    }
}
