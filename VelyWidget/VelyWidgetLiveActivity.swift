import ActivityKit
import WidgetKit
import SwiftUI

struct VelyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            TripLockScreenView(context: context)
                .activityBackgroundTint(Color.indigo.opacity(0.12))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.tripDisplayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(context.attributes.originName)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.departureDate, style: .time)
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        StatusBadgeView(statusKind: context.state.statusKind, style: .compact)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label {
                            Text(context.state.departureDate, style: .timer)
                                .monospacedDigit()
                                .font(.subheadline.bold())
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Label {
                            Text(context.attributes.destinationName)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                compactLeadingIcon(statusKind: context.state.statusKind)
            } compactTrailing: {
                Text(context.state.departureDate, style: .timer)
                    .monospacedDigit()
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(minWidth: 36)
            } minimal: {
                compactLeadingIcon(statusKind: context.state.statusKind)
            }
            .widgetURL(URL(string: "vely://trips"))
            .keylineTint(.indigo)
        }
    }

    @ViewBuilder
    private func compactLeadingIcon(statusKind: StatusKind?) -> some View {
        switch statusKind {
        case .weather(let symbol, _):
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.caption.weight(.semibold))
        default:
            Image(systemName: "bicycle")
                .foregroundStyle(.indigo)
                .font(.caption.weight(.semibold))
        }
    }
}

// MARK: - Status Badge

private enum StatusBadgeStyle { case compact, full }

private struct StatusBadgeView: View {
    let statusKind: StatusKind?
    let style: StatusBadgeStyle

    var body: some View {
        switch statusKind {
        case .bikes(let count):
            Label("\(count)", systemImage: "bicycle")
                .font(style == .compact ? .caption2.weight(.medium) : .caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
        case .weather(let symbol, let temp):
            HStack(spacing: 3) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(style == .compact ? .caption2 : .caption)
                Text(temp)
                    .font(style == .compact ? .caption2.weight(.medium) : .caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        case nil:
            EmptyView()
        }
    }
}

// MARK: - Lock Screen

private struct TripLockScreenView: View {
    let context: ActivityViewContext<TripActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                lockScreenLeadingIcon
                Text(context.attributes.tripDisplayName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(context.state.departureDate, style: .time)
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label(context.attributes.originName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Label(context.attributes.destinationName, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.state.departureDate, style: .timer)
                        .monospacedDigit()
                        .font(.title2.bold())
                        .foregroundStyle(.indigo)
                    StatusBadgeView(statusKind: context.state.statusKind, style: .full)
                }
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var lockScreenLeadingIcon: some View {
        switch context.state.statusKind {
        case .weather(let symbol, _):
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
        default:
            Image(systemName: "bicycle.circle.fill")
                .font(.title3)
                .foregroundStyle(.indigo)
        }
    }
}
