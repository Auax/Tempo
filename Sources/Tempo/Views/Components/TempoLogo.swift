import SwiftUI

struct TempoLogo: View {
    var compact = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [.tempoBlueSoft, .tempoBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)
            .shadow(color: .tempoBlue.opacity(0.24), radius: 8, y: 4)

            if !compact {
                Text("Tempo")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tempo")
    }
}
