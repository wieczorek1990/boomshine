import SwiftUI

struct SplashView: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Image("soiree_logo")
      .resizable()
      .renderingMode(.template)
      .scaledToFit()
      .frame(width: 200, height: 200)
      .foregroundColor(colorScheme == .dark ? .white : .black)
  }
}

#Preview {
  SplashView()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
