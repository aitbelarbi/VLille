import SwiftUI

struct TripWaypointPickerView: View {
    let items: [any FavoriteItem]
    let selectedWaypoint: TripWaypoint?
    let onSelect: (TripWaypoint) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "trip_picker_empty_title",
                        systemImage: "star.slash",
                        description: Text("trip_picker_empty_hint")
                    )
                } else {
                    List {
                        ForEach(items, id: \.id) { item in
                            Button {
                                guard let waypoint = tripWaypoint(from: item) else { return }
                                onSelect(waypoint)
                            } label: {
                                HStack {
                                    FavoriteItemRowView(item: item)
                                    if isSelected(item) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.indigo)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("trip_picker_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_cancel") { dismiss() }
                }
            }
        }
    }

    private func tripWaypoint(from item: any FavoriteItem) -> TripWaypoint? {
        if let station = item as? StationFavorite { return .from(station) }
        if let address = item as? AddressFavorite { return .from(address) }
        return nil
    }

    private func isSelected(_ item: any FavoriteItem) -> Bool {
        guard let wp = selectedWaypoint, let itemWp = tripWaypoint(from: item) else { return false }
        switch (wp, itemWp) {
        case (.stationFavorite(let a), .stationFavorite(let b)): return a == b
        case (.addressFavorite(let a), .addressFavorite(let b)): return a == b
        default: return false
        }
    }
}
