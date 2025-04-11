// ContentView.swift

import SwiftUI
import MapKit
import SafariServices

struct ContentView: View {
    @State private var dailyScripture: String = ScriptureProvider.getRandomScripture()
    @State private var showingAnnouncements = false
    @State private var showingGiving = false
    @State private var showingBibleLink = false
    @State private var showingNotes = false
    @State private var showingFullScripture = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var gridColumns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        Spacer()
                        Button(action: { /* settings */ }) {
                            Image("bluegear").resizable().frame(width: 35, height: 35)
                        }.padding()
                    }
                    .background(Color.black)

                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Church of God of Prophecy")
                                .font(horizontalSizeClass == .regular ? .title : .title2)
                                .bold()
                                .foregroundColor(.white)
                            Text("41 Orchard St. River Rouge, MI 48218")
                                .font(horizontalSizeClass == .regular ? .body : .subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .bold()
                            Text("Bishop Leonard Clarke")
                                .font(horizontalSizeClass == .regular ? .body : .subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .bold()
                        }
                        Spacer()
                        Image("cogop-trans").resizable().scaledToFit().frame(width: 80, height: 80)
                    }
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.black]), startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 5)

                    Spacer()

                    // Grid Buttons
                    LazyVGrid(columns: gridColumns, spacing: 15) {
                        GridButton(title: "Join Service", icon: "person.3.fill", action: {
                            if let url = URL(string: "https://bit.ly/RRCOGOP") {
                                UIApplication.shared.open(url)
                            }
                        })
                        
                        GridButton(title: "Announcements", icon: "info.circle.fill", action: {
                            showingAnnouncements = true
                        })
                        
                        GridButton(title: "Bible", icon: "book.fill", action: {
                            // Attempt to open the YouVersion Bible app using its URL scheme
                            if let appURL = URL(string: "youversion://") {
                                if UIApplication.shared.canOpenURL(appURL) {
                                    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
                                } else {
                                    // If the app isn't installed, redirect to the App Store using the app's ID
                                    if let appStoreURL = URL(string: "https://apps.apple.com/us/app/bible/id282935706") {
                                        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
                                    }
                                }
                            }
                        })
                        
                        GridButton(title: "Location", icon: "map.fill", action: {
                            openMaps(address: "41 Orchard St, River Rouge, MI 48218")
                        })
                        
                        GridButton(title: "Giving", icon: "dollarsign.circle.fill", action: {
                            showingGiving = true
                        })
                        
                        GridButton(title: "Notes", icon: "note.text", action: {
                            showingNotes = true
                        })
                    }
                    .padding()
                    .sheet(isPresented: $showingAnnouncements) {
                        AnnouncementsView()
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .sheet(isPresented: $showingBibleLink) {
                        BibleLinkView()
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .sheet(isPresented: $showingGiving) {
                        GivingView()
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .sheet(isPresented: $showingNotes) {
                        NotesView()
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Spacer()

                    // Daily Verse Section
                    VStack {
                        if #available(iOS 16.0, *) {
                            Text("Daily Scripture").underline().padding(.top, 20)
                                .font(horizontalSizeClass == .regular ? .title : .title2)
                                .fontWeight(.bold).foregroundColor(.white)
                        } else { /* Fallback */ }
                        Text(dailyScripture)
                            .font(horizontalSizeClass == .regular ? .title2 : .body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 90)
                            .onTapGesture {
                                showingFullScripture = true
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.horizontal)
                    .sheet(isPresented: $showingFullScripture) {
                        ZStack {
                            Color.black.ignoresSafeArea()
                            VStack {
                                if #available(iOS 16.0, *) {
                                    Text("Daily Scripture")
                                        .underline()
                                        .padding(.top, 40)
                                        .font(horizontalSizeClass == .regular ? .title : .title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                } else { /* Fallback */ }
                                ScrollView {
                                    Text(dailyScripture)
                                        .font(horizontalSizeClass == .regular ? .title2 : .body)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .padding(.horizontal)
                        }
                        .presentationDetents([.medium, .large, .height(250)])
                        .presentationDragIndicator(.visible)
                    }

                    Spacer()

                    // Footer
                    HStack(spacing: horizontalSizeClass == .regular ? 60 : 30) {
                        SocialButton(icon: "facebook")
                        SocialButton(icon: "x-white")
                        SocialButton(icon: "instagram")
                        SocialButton(icon: "youtube")
                        SocialButton(icon: "cashapp")
                    }
                    .padding()

                    Text("Developed by Brett: Brett Tech Networking")
                        .font(.footnote)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.bottom)
                }
            }
            .onAppear {
                dailyScripture = ScriptureProvider.getRandomScripture()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Helper Functions / Structs
func openMaps(address: String) {
    let geocoder = CLGeocoder()
    geocoder.geocodeAddressString(address) { placemarks, error in
        if let placemark = placemarks?.first, let _ = placemark.location {
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            mapItem.name = "Church of God of Prophecy"
            mapItem.openInMaps()
        } else {
            print("Could not geocode address: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
}

struct BibleLinkView: View {
    var body: some View {
        VStack {
            Text("Open Bible App").font(.title).padding()
            Text("App not installed...").padding()
            Button("Install from App Store") { /* Action */ }.padding()
        }
    }
}

struct GivingLinkView: View {
    var body: some View {
        VStack {
            Text("Giving Options").font(.title).padding()
        }
    }
}

struct GridButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isTapped = false

    private var buttonSize: CGFloat {
        return horizontalSizeClass == .regular ? 180 : 110
    }
    private var iconSize: CGFloat {
        return horizontalSizeClass == .regular ? 70 : 40
    }
    private var textFont: Font {
        return horizontalSizeClass == .regular ? .body : .footnote
    }
    private var textFrameWidth: CGFloat {
        return horizontalSizeClass == .regular ? 140 : 80
    }

    var body: some View {
        Button(action: {
            isTapped = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTapped = false
            }
        }) {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.white)
                    .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 0) // Subtle blue glow
                Text(title)
                    .foregroundColor(.white)
                    .font(textFont)
                    .fontWeight(.semibold) // Bolder text for better readability
                    .multilineTextAlignment(.center)
                    .frame(width: textFrameWidth)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]), // Match the Daily Scripture gradient
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1) // Subtle white border
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4) // Blue shadow for depth
        }
        .scaleEffect(isTapped ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped)
    }
}

struct SocialButton: View {
    var icon: String
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var iconSize: CGFloat {
        horizontalSizeClass == .regular ? 45 : 30
    }

    var body: some View {
        Button(action: { openSocialURL(for: icon) }) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        }
    }

    func openSocialURL(for iconName: String) {
        var urlString: String?
        switch iconName {
        case "facebook":
            urlString = "https://www.facebook.com/RiverRougeCOGOP"
        case "x-white":
            urlString = "https://x.com/RiverRougeCOGOP"
        case "instagram":
            urlString = "https://www.instagram.com/riverrougecogop/"
        case "youtube":
            urlString = "https://www.youtube.com/@RiverRougeCOGOP"
        case "cashapp":
            urlString = "https://cash.app/$RiverRougeCOGOP"
        default:
            urlString = nil
        }
        if let urlString = urlString, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone 14 Pro")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone")

            ContentView()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPad Pro 12.9")
        }
    }
}
