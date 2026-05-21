import SwiftUI

struct WidgetSlotPickerView: View {
    let slotIndex: Int
    let allEntries: [FavoriteEntry]
    let liveStations: [BikeStation]
    let currentCityId: String
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(\.dismiss) var dismiss

    private var currentCityEntries: [FavoriteEntry] {
        let liveIds = Set(liveStations.map { $0.id })
        return allEntries
            .filter { liveIds.contains($0.stationId) }
            .sorted { $0.stationName < $1.stationName }
    }

    var body: some View {
        NavigationStack {
            List {
                if favoritesStore.widgetSlots(for: currentCityId)[slotIndex] != nil {
                    Section {
                        Button(role: .destructive) {
                            favoritesStore.setWidgetSlot(slotIndex, stationId: nil, cityId: currentCityId)
                            dismiss()
                        } label: {
                            Label("widget_slot_remove", systemImage: "minus.circle")
                        }
                    }
                }

                Section("widget_slot_pick_section") {
                    ForEach(currentCityEntries) { entry in
                        let isCurrentSlot = favoritesStore.widgetSlots(for: currentCityId)[slotIndex] == entry.stationId
                        let otherSlot: Int? = {
                            guard let slot = favoritesStore.widgetSlot(for: entry.stationId, cityId: currentCityId) else { return nil }
                            return slot != slotIndex + 1 ? slot : nil
                        }()
                        let live = liveStations.first { $0.id == entry.stationId }

                        Button {
                            favoritesStore.setWidgetSlot(slotIndex, stationId: entry.stationId, cityId: currentCityId)
                            dismiss()
                        } label: {
                            WidgetSlotEntryRow(
                                entry: entry,
                                liveStation: live,
                                isCurrentSlot: isCurrentSlot,
                                otherSlot: otherSlot
                            )
                        }
                    }
                }
            }
            .navigationTitle("widget_slot_title \(slotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
            }
        }
    }
}

private struct WidgetSlotEntryRow: View {
    let entry: FavoriteEntry
    let liveStation: BikeStation?
    let isCurrentSlot: Bool
    let otherSlot: Int?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "bicycle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.indigo)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.stationName.isEmpty ? entry.stationId : entry.stationName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !entry.stationAddress.isEmpty {
                    Text(entry.stationAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let bikes = liveStation?.bikesAvailable, let docks = liveStation?.docksAvailable {
                HStack(spacing: 4) {
                    liveBadge(count: bikes, icon: "bicycle", color: .green)
                    liveBadge(count: docks, icon: "parkingsign", color: .blue)
                }
            }

            if isCurrentSlot {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.indigo)
            } else if let other = otherSlot {
                Text("W\(other)")
                    .font(.caption2.bold())
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.indigo.opacity(0.10), in: Capsule())
            }
        }
    }

    private func liveBadge(count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text("\(count)")
                .font(.caption.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}
