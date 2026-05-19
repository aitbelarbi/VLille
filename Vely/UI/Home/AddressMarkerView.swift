import SwiftUI

struct AddressMarkerView: View {
    let item: AddressFavorite

    var body: some View {
        ZStack {
            Circle()
                .fill(item.markerTint)
                .frame(width: 36, height: 36)
                .shadow(color: item.markerTint.opacity(0.4), radius: 4, x: 0, y: 2)
            Image(systemName: item.markerIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .overlay(alignment: .bottom) {
            Triangle()
                .fill(item.markerTint)
                .frame(width: 10, height: 6)
                .offset(y: 6)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
