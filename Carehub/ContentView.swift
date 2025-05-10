import SwiftUI

struct SplashView: View {
    @State private var showOnboarding = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color(red: 0.43, green: 0.34, blue: 0.99)
                .edgesIgnoringSafeArea(.all)
            
            if let image = UIImage(named: "appicon_background") {
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(UIScreen.main.bounds.width * 0.5, 300))
                        .accessibilityLabel("CareHub Logo")
                    
                    Text("CareHub")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("CareHub Logo with Title")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.8))
                    
                    Text("CareHub")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
            }
        }
                .navigationDestination(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashView()
                .preferredColorScheme(.light)
            SplashView()
                .preferredColorScheme(.dark)
        }
    }
}
