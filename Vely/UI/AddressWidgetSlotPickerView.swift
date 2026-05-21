import SwiftUI

struct AddressWidgetSlotPickerView: View {
    let slotIndex: Int
    let currentCityId: String
    @Environment(AddressStore.self) var addressStore
    @Environment(\.dismiss) var dismiss

    private var currentCityAddresses: [SavedAddress] {
        addressStore.savedAddresses
            .filter { $0.cityId == currentCityId || $0.cityId.isEmpty }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                if addressStore.widgetSlots(for: currentCityId)[slotIndex] != nil {
                    Section {
                        Button(role: .destructive) {
                            addressStore.setWidgetSlot(slotIndex, addressId: nil, cityId: currentCityId)
                            dismiss()
                        } label: {
                            Label("widget_slot_remove", systemImage: "minus.circle")
                        }
                    }
                }

                Section("widget_slot_pick_section") {
                    ForEach(currentCityAddresses, id: \.id) { address in
                        let addressId = address.id.uuidString
                        let isCurrentSlot = addressStore.widgetSlots(for: currentCityId)[slotIndex] == addressId
                        let otherSlot: Int? = {
                            guard let slot = addressStore.widgetSlot(for: addressId, cityId: currentCityId) else { return nil }
                            return slot != slotIndex + 1 ? slot : nil
                        }()

                        Button {
                            addressStore.setWidgetSlot(slotIndex, addressId: addressId, cityId: currentCityId)
                            dismiss()
                        } label: {
                            AddressSlotEntryRow(
                                address: address,
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

private struct AddressSlotEntryRow: View {
    let address: SavedAddress
    let isCurrentSlot: Bool
    let otherSlot: Int?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(address.tintColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: address.systemIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(address.tintColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(address.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !address.address.isEmpty {
                    Text(address.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

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
}
