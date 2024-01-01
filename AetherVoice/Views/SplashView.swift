import SwiftUI

struct SplashView: View {
    @State var viewModel: DocumentListViewModel?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let viewModel = viewModel {
            ContentView(viewModel: viewModel)
        } else {
            VStack {
                // Use different images based on the color scheme
                if colorScheme == .dark {
                    Image("SplashDark") // Your white icon for dark mode
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                } else {
                    Image("Splash") // Your black icon for light mode
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .task {
                viewModel = await DocumentListViewModel()
            }
        }
    }
}
