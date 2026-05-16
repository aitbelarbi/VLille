import SwiftUI

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(12)
    }
}

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(message: "Impossible de se connecter. Vérifiez votre connexion.", onDismiss: {})
            .padding()
    }
}
#endif

