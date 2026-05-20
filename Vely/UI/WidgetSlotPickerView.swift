import SwiftUI

struct WidgetSlotPickerView: View {
    let slotIndex: Int
    let allEntries: [FavoriteEntry]
    let liveStations: [BikeStation]
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if favoritesStore.widgetSlotIds[slotIndex] != nil {
                    Section {
                        Button(role: .destructive) {
                            favoritesStore.setWidgetSlot(slotIndex, stationId: nil)
                            dismiss()
                        } label: {
                            Label("widget_slot_remove", systemImage: "minus.circle")
                        }
                    }
                }

                Section("widget_slot_pick_section") {
                    ForEach(allEntries.sorted { $0.stationName < $1.stationName }) { entry in
                        let isCurrentSlot = favoritesStore.widgetSlotIds[slotIndex] == entry.stationId
                        let otherSlot = favoritesStore.widgetSlot(for: entry.stationId).map {
                            $0 != slotIndex + 1 ? $0 : nil
                        } ?? nil

                        Button {
                            favoritesStore.setWidgetSlot(slotIndex, stationId: entry.stationId)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.stationName.isEmpty ? entry.stationId : entry.stationName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(entry.stationAddress.isEmpty ? "—" : entry.stationAddress)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isCurrentSlot {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                } else if let other = otherSlot {
                                    Text("W\(other)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.accentColor)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                                }
                            }
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
