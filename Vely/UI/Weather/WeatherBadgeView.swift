import SwiftUI
import WeatherKit

struct WeatherBadgeView: View {
    let weather: WeatherManager
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Group {
                if weather.isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else if let current = weather.current {
                    HStack(spacing: 5) {
                        Image(systemName: current.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 16, weight: .semibold))
                        Text(current.temperature.formatted(.measurement(width: .abbreviated, usage: .weather)))
                            .font(.subheadline.weight(.semibold))
                    }
                } else {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
