import SwiftUI

struct TripCreationView: View {
    var editingTrip: Trip? = nil

    @Environment(TripStore.self) var tripStore
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(AddressStore.self) var addressStore
    @Environment(ProfileStore.self) var profileStore
    @Environment(CityStore.self) var cityStore
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var departureDate: Date = {
        Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    }()
    @State private var originWaypoint: TripWaypoint?
    @State private var destinationWaypoint: TripWaypoint?
    @State private var pickingRole: WaypointRole?
    @State private var notificationsEnabled = false
    @State private var notificationLeadMinutes = 15
    @State private var showNotificationPermissionSheet = false

    private enum WaypointRole: Identifiable {
        case origin, destination
        var id: Self { self }
    }

    private var allFavoriteItems: [any FavoriteItem] {
        profileStore.strategy.tripWaypointCandidates(
            stores: FavoriteStores(favorites: favoritesStore, addresses: addressStore),
            currentCity: cityStore.selectedCity
        )
    }

    private var originItem: (any FavoriteItem)? { resolveWaypoint(originWaypoint) }
    private var destinationItem: (any FavoriteItem)? { resolveWaypoint(destinationWaypoint) }
    private var isValid: Bool {
        guard let o = originWaypoint, let d = destinationWaypoint else { return false }
        return o != d && !selectedDays.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    waypointRow(.origin, item: originItem, placeholder: "trip_origin_label")
                    waypointRow(.destination, item: destinationItem, placeholder: "trip_destination_label")
                } header: {
                    Text("trip_section_route")
                }

                Section {
                    DayPickerRow(selectedDays: $selectedDays)
                    DatePicker("trip_departure_time", selection: $departureDate, displayedComponents: .hourAndMinute)
                } header: {
                    Text("trip_section_schedule")
                }

                Section {
                    Toggle("trip_notification_toggle", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue { handleNotificationToggle() }
                        }
                    if notificationsEnabled {
                        Picker("trip_notification_lead", selection: $notificationLeadMinutes) {
                            ForEach([5, 15, 30, 60], id: \.self) { minutes in
                                Text(leadLabel(minutes)).tag(minutes)
                            }
                        }
                    }
                } header: {
                    Text("trip_section_notification")
                }

                Section {
                    HStack {
                        TextField("trip_name_placeholder", text: $name)
                        if !name.isEmpty {
                            Button { name = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("trip_section_name")
                } footer: {
                    Text("trip_name_footer")
                }

            }
            .navigationTitle(editingTrip == nil ? LocalizedStringKey("trip_create_title") : LocalizedStringKey("trip_edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common_cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editingTrip == nil ? LocalizedStringKey("common_add") : LocalizedStringKey("common_done")) {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showNotificationPermissionSheet) {
                NotificationPermissionSheet(
                    notificationManager: notificationManager,
                    tripName: name,
                    leadMinutes: notificationLeadMinutes,
                    onGranted: { showNotificationPermissionSheet = false },
                    onDismissed: {
                        notificationsEnabled = false
                        showNotificationPermissionSheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $pickingRole) { role in
                TripWaypointPickerView(
                    items: allFavoriteItems,
                    selectedWaypoint: role == .origin ? originWaypoint : destinationWaypoint,
                    excludedWaypoint: role == .origin ? destinationWaypoint : originWaypoint
                ) { waypoint in
                    if role == .origin { originWaypoint = waypoint }
                    else { destinationWaypoint = waypoint }
                    pickingRole = nil
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            populateFromEditingTrip()
            if editingTrip == nil {
                Task {
                    await notificationManager.refreshStatus()
                    await MainActor.run {
                        if notificationManager.authorizationStatus == .denied {
                            notificationsEnabled = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func waypointRow(_ role: WaypointRole, item: (any FavoriteItem)?, placeholder: LocalizedStringKey) -> some View {
        Button { pickingRole = role } label: {
            HStack(spacing: 10) {
                Image(systemName: role == .origin ? "mappin.circle.fill" : "flag.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(role == .origin ? Color.indigo : Color.green)
                    .frame(width: 24)

                if let item {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.displayName).font(.headline).foregroundStyle(.primary)
                        Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text(placeholder).foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard let origin = originWaypoint, let destination = destinationWaypoint else { return }
        let cal = Calendar.current
        let trip = Trip(
            id: editingTrip?.id ?? UUID(),
            name: name,
            profile: editingTrip?.profile ?? profileStore.profile,
            schedule: TripSchedule(
                days: selectedDays,
                departureHour: cal.component(.hour, from: departureDate),
                departureMinute: cal.component(.minute, from: departureDate)
            ),
            origin: origin,
            destination: destination,
            notificationLeadMinutes: notificationsEnabled ? notificationLeadMinutes : nil
        )
        if editingTrip != nil {
            notificationManager.cancel(tripId: trip.id)
            tripStore.update(trip)
        } else {
            tripStore.add(trip)
        }
        Task { await scheduleAfterPermissionCheck(trip) }
    }

    private func scheduleAfterPermissionCheck(_ trip: Trip) async {
        guard trip.notificationLeadMinutes != nil else { return }
        await notificationManager.refreshStatus()
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationManager.schedule(trip)
        case .notDetermined:
            let granted = await notificationManager.requestAuthorization()
            if granted { notificationManager.schedule(trip) }
        default:
            break
        }
    }

    private func handleNotificationToggle() {
        Task {
            await notificationManager.refreshStatus()
            switch notificationManager.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                break
            case .denied:
                await MainActor.run {
                    notificationsEnabled = false
                    showNotificationPermissionSheet = true
                }
            case .notDetermined:
                await MainActor.run { showNotificationPermissionSheet = true }
            @unknown default:
                break
            }
        }
    }

    private func leadLabel(_ minutes: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = minutes >= 60 ? [.hour] : [.minute]
        return formatter.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
    }

    private func populateFromEditingTrip() {
        guard let t = editingTrip else { return }
        name = t.name
        selectedDays = t.schedule.days
        departureDate = Calendar.current.date(
            from: DateComponents(hour: t.schedule.departureHour, minute: t.schedule.departureMinute)
        ) ?? Date()
        originWaypoint = t.origin
        destinationWaypoint = t.destination
        notificationsEnabled = t.notificationLeadMinutes != nil
        notificationLeadMinutes = t.notificationLeadMinutes ?? 15
    }

    private func resolveWaypoint(_ waypoint: TripWaypoint?) -> (any FavoriteItem)? {
        waypoint?.resolve(in: FavoriteStores(favorites: favoritesStore, addresses: addressStore))
    }
}

// MARK: - DayPickerRow

private struct DayPickerRow: View {
    @Binding var selectedDays: Set<Weekday>
    private let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(displayOrder) { day in
                let active = selectedDays.contains(day)
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        if active { selectedDays.remove(day) }
                        else { selectedDays.insert(day) }
                    }
                } label: {
                    Text(String(day.shortName.prefix(2)).uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            active ? Color.indigo : Color.secondary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(active ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}
