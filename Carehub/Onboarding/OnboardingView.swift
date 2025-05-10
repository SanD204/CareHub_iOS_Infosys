import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var cardOffset: CGSize = .zero
    @State private var rotationAngle: Double = 0.0
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let pages = [
        OnboardingPage(
            icon: "heart.text.clipboard.fill",
            title: "Welcome to CareHub",
            description: "Manage appointments, records, and doctor communication easily",
            buttonTitle: "Next"
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Stay Connected with Your Care Team",
            description: "Access doctors, view results, and get follow-up reminders.",
            buttonTitle: "Next"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Secure and User-Friendly",
            description: "A secure, intuitive platform for hospital operations.",
            buttonTitle: "Get Started"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            LinearGradient(
                colors: [
                    Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.4),
                    Color.white.opacity(0.9),
                    Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            ForEach(Array(pages.enumerated().reversed()), id: \.offset) { index, page in
                if index >= currentPage {
                    OnboardingCard(
                        page: page,
                        isLastPage: index == pages.count - 1,
                        currentPage: .constant(index)
                    )
                    .offset(index == currentPage ? cardOffset : .zero)
                    .rotationEffect(.degrees(index == currentPage ? Double(cardOffset.width / 20) : 0))
                    .gesture(index == currentPage ? dragGesture : nil)
                    .animation(.spring(), value: cardOffset)
                }
            }

            VStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        if currentPage == pages.count - 1 {
                            appState.hasCompletedOnboarding = true
                            dismiss()
                        } else {
                            currentPage += 1
                        }
                        resetDrag()
                    }
                }) {
                    Text(pages[currentPage].buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                .accessibilityLabel("\(pages[currentPage].buttonTitle) Button")
            }
        }
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                cardOffset = gesture.translation
                rotationAngle = Double(cardOffset.width / 20)
            }
            .onEnded { gesture in
                let threshold: CGFloat = 100
                if abs(gesture.translation.width) > threshold {
                    withAnimation {
                        cardOffset = CGSize(width: gesture.translation.width * 5, height: gesture.translation.height * 2)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                appState.hasCompletedOnboarding = true
                                dismiss()
                            }
                            resetDrag()
                        }
                    }
                } else {
                    withAnimation {
                        resetDrag()
                    }
                }
            }
    }

    func resetDrag() {
        cardOffset = .zero
        rotationAngle = 0.0
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
}

// MARK: - Reusable Card View
struct OnboardingCard: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let currentPage: Binding<Int>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: page.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.8))
                .accessibilityLabel("\(page.title) Icon")

            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .accessibilityLabel("\(page.title) Title")

            Text(page.description)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .accessibilityLabel("\(page.title) Description")

            Spacer()
            
            if !isLastPage {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .frame(width: index == currentPage.wrappedValue ? 10 : 6,
                                   height: index == currentPage.wrappedValue ? 10 : 6)
                            .foregroundColor(index == currentPage.wrappedValue ? .black : .gray)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 30)
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
                .environmentObject(AppState())
                .preferredColorScheme(.light)

            OnboardingView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
        }
    }
}
