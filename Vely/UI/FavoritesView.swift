import SwiftUI
import MapKit

struct FavoritesView: View {
    var viewModel: HomeViewModel
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(CityStore.self) var cityStore
    @Environment(PurchaseManager.self) var purchaseManager
    @Environment(ProfileStore.self) var profileStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition
    @State private var showPaywall = false
    @State private var pickerSlot: WidgetSlotSelection? = nil

    private var strategy: any ProfileStrategy { profileStore.strategy }

    private var widgetStationIds: Set<String> {
        Set(favoritesStore.widgetSlotIds.compactMap { $0 })
    }

    private var sections: [FavoriteSection] {
        strategy.favoriteSections(
            store: favoritesStore,
            liveStations: viewModel.stations,
            currentCity: viewModel.currentCity,
            cities: cityStore.cities,
            isPremium: purchaseManager.isPremium
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if !strategy.hasFavorites(in: favoritesStore) {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("tab_favorites")
            .onChange(of: viewModel.stations) { _, stations in
                favoritesStore.healEntries(with: stations)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $pickerSlot) { selection in
                WidgetSlotPickerView(
                    slotIndex: selection.index,
                    allEntries: Array(favoritesStore.entries.values),
                    liveStations: viewModel.stations
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            strategy.canAddAddressFavorites
                ? LocalizedStringKey("cyclist_addresses_empty_title")
                : LocalizedStringKey("favorites_empty_title"),
            systemImage: strategy.canAddAddressFavorites ? "mappin.slash" : "star.slash",
            description: Text(
                strategy.canAddAddressFavorites
                    ? LocalizedStringKey("cyclist_addresses_empty_hint")
                    : LocalizedStringKey("favorites_empty_hint")
            )
        )
    }

    private var favoritesList: some View {
        List {
            if strategy.supportsWidgets {
                Section {
                    WidgetSectionView(
                        slotIds: favoritesStore.widgetSlotIds,
                        entries: favoritesStore.entries,
                        liveStations: viewModel.stations,
                        isPremium: purchaseManager.isPremium,
                        onTapSlot: { pickerSlot = WidgetSlotSelection(index: $0) },
                        onUnlock: { showPaywall = true }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    HStack(spacing: 6) {
                        Text("favorites_widget_section")
                            .font(.footnote.bold())
                            .textCase(.uppercase)
                        Image(systemName: purchaseManager.isPremium ? "sparkles" : "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(purchaseManager.isPremium ? Color.accentColor : Color.secondary)
                    }
                }
            }

            ForEach(sections) { section in
                Section {
                    ForEach(section.items, id: \.id) { item in
                        Button { handleTap(item) } label: {
                            FavoriteItemRowView(item: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { section.items[$0].remove(from: favoritesStore) }
                    }
                } header: {
                    if !section.title.isEmpty {
                        Text(section.title)
                    }
                }
            }

            if strategy.canAddAddressFavorites {
                Section {
                    Button {
                        selectedTab = 2
                    } label: {
                        Label("cyclist_add_address", systemImage: "plus.circle")
                            .foregroundStyle(.indigo)
                    }
                }
            }
        }
    }

    private func handleTap(_ item: any FavoriteItem) {
        guard let coord = item.coordinate else { return }
        cameraPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        if let station = item.liveStationReference {
            viewModel.pendingStationToShow = station
        }
        selectedTab = 0
    }
}

// MARK: - FavoriteItemRowView

struct FavoriteItemRowView: View {
    let item: any FavoriteItem

    var body: some View {
        HStack(spacing: 12) {
            leadingView

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(item.subtitle.isEmpty ? "—" : item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let slot = item.widgetSlot {
                        WidgetBadge(slot: slot)
                    }
                }
            }

            Spacer()

            if let bikes = item.bikesAvailable, let docks = item.docksAvailable {
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Image(systemName: "bicycle").font(.subheadline)
                        Text("\(bikes)").font(.caption.bold())
                    }
                    .foregroundStyle(.green)
                    VStack(spacing: 2) {
                        Image(systemName: "parkingsign").font(.subheadline)
                        Text("\(docks)").font(.caption.bold())
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(item.isActive ? 1 : 0.5)
    }

    @ViewBuilder
    private var leadingView: some View {
        if let badgeText = item.rowLeadingBadgeText {
            ZStack {
                Circle()
                    .fill(item.rowLeadingColor)
                    .frame(width: 40, height: 40)
                Text(badgeText)
                    .font(.callout.bold())
                    .foregroundStyle(.white)
            }
        } else {
            Circle()
                .fill(item.rowLeadingColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: item.rowLeadingIcon)
                        .font(.caption)
                        .foregroundStyle(item.rowLeadingColor)
                )
        }
    }
}

// MARK: - Widget Section

struct WidgetSlotSelection: Identifiable {
    let id = UUID()
    let index: Int
}

struct WidgetSectionView: View {
    let slotIds: [String?]
    let entries: [String: FavoriteEntry]
    let liveStations: [BikeStation]
    let isPremium: Bool
    let onTapSlot: (Int) -> Void
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { index in
                    WidgetSlotCard(
                        slotNumber: index + 1,
                        entry: slotIds[index].flatMap { entries[$0] },
                        liveStation: slotIds[index].flatMap { id in liveStations.first { $0.id == id } },
                        isLocked: !isPremium,
                        onTap: isPremium ? { onTapSlot(index) } : onUnlock
                    )
                }
            }

            if !isPremium {
                PremiumWidgetBannerView(onTap: onUnlock)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct WidgetSlotCard: View {
    let slotNumber: Int
    let entry: FavoriteEntry?
    let liveStation: BikeStation?
    let isLocked: Bool
    let onTap: () -> Void

    var isEmpty: Bool { entry == nil }

    var statusColor: Color {
        guard let s = liveStation else { return .secondary }
        guard s.isOperational else { return .red }
        return s.bikesAvailable > 0 ? .green : .orange
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEmpty
                        ? AnyShapeStyle(Color(.systemGray5))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color.accentColor.opacity(0.85), Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isEmpty ? Color(.systemGray4) : Color.clear, lineWidth: 1)
                    )

                if isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("widget_slot_empty")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("W\(slotNumber)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            if liveStation != nil {
                                Circle().fill(statusColor).frame(width: 8, height: 8)
                            } else {
                                Image(systemName: "wifi.slash")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        Text(entry?.stationName.isEmpty == false ? entry!.stationName : (entry?.stationId ?? ""))
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer(minLength: 4)

                        if let station = liveStation {
                            HStack(spacing: 10) {
                                Label("\(station.bikesAvailable)", systemImage: "bicycle")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                Label("\(station.docksAvailable)", systemImage: "parkingsign")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        } else {
                            Text("widget_slot_no_live")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Row Views

struct PremiumWidgetBannerView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "rectangle.3.group")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("banner_widget_title")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("banner_widget_subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct StationRowView: View {
    let station: BikeStation
    var widgetSlot: Int? = nil

    var statusColor: Color {
        guard station.isOperational else { return .red }
        return station.bikesAvailable > 0 ? .green : .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)
                Text("\(station.bikesAvailable)")
                    .font(.callout.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name).font(.headline)
                HStack(spacing: 6) {
                    Text(station.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let slot = widgetSlot { WidgetBadge(slot: slot) }
                }
            }
            Spacer()
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Image(systemName: "bicycle").font(.subheadline)
                    Text("\(station.bikesAvailable)").font(.caption.bold())
                }
                .foregroundStyle(.green)
                VStack(spacing: 2) {
                    Image(systemName: "parkingsign").font(.subheadline)
                    Text("\(station.docksAvailable)").font(.caption.bold())
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WidgetBadge: View {
    let slot: Int
    var body: some View {
        Text("W\(slot)")
            .font(.caption2.bold())
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
    }
}
