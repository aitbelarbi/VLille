import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(viewModel.stations) { station in
                        VStack(alignment: .leading) {
                            Text(station.nom)
                                .font(.headline)
                            Text(station.adresse)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                Text("🚲 Vélos dispo: \(station.nbVelosDispo)")
                                Text("📍 Places dispo: \(station.nbPlacesDispo)")
                            }
                            .font(.footnote)
                        }
                        .padding(5)
                    }
                }
            }
            .navigationTitle("Stations VLille")
            .onAppear {
                viewModel.fetchStations()
            }
        }
    }
}

#Preview {
    ContentView()
}
