// ContentView.swift
import SwiftUI
import MapKit
import SafariServices

struct ContentView: View {
    @State private var dailyScripture: String = UserDefaults.standard.string(forKey: "dailyScripture") ?? ScriptureProvider.getRandomScripture()
    @State private var showingAnnouncements = false
    @State private var showingGiving = false
    @State private var showingBibleLink = false
    @State private var showingNotes = false
    @State private var showingFullScripture = false
    @State private var showingMusicPlayer = false
    @State private var showingSettings = false
    @State private var selectedGradient: GradientOption = .defaultOption
    @State private var selectedScriptureTheme: ScriptureTheme = .defaultTheme
    @State private var selectedFontSize: FontSizeOption = .medium
    @State private var selectedRefreshFrequency: ScriptureRefreshFrequency = .onLaunch
    @State private var refreshTimer: Timer? = nil

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
                        Button(action: {
                            showingSettings = true
                        }) {
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
                        GridButton(title: "Join Service", icon: "person.3.fill", gradient: selectedGradient, action: {
                            if let url = URL(string: "https://bit.ly/RRCOGOP") {
                                UIApplication.shared.open(url)
                            }
                        })
                        
                        GridButton(title: "Announcements", icon: "info.circle.fill", gradient: selectedGradient, action: {
                            showingAnnouncements = true
                        })
                        
                        GridButton(title: "Bible", icon: "book.fill", gradient: selectedGradient, action: {
                            if let appURL = URL(string: "youversion://") {
                                if UIApplication.shared.canOpenURL(appURL) {
                                    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
                                } else {
                                    if let appStoreURL = URL(string: "https://apps.apple.com/us/app/bible/id282935706") {
                                        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
                                    }
                                }
                            }
                        })
                        
                        GridButton(title: "Location", icon: "map.fill", gradient: selectedGradient, action: {
                            openMaps(address: "41 Orchard St, River Rouge, MI 48218")
                        })
                        
                        GridButton(title: "Giving", icon: "dollarsign.circle.fill", gradient: selectedGradient, action: {
                            showingGiving = true
                        })
                        
                        GridButton(title: "Notes", icon: "note.text", gradient: selectedGradient, action: {
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
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(
                            selectedGradient: $selectedGradient,
                            selectedScriptureTheme: $selectedScriptureTheme,
                            selectedFontSize: $selectedFontSize,
                            selectedRefreshFrequency: $selectedRefreshFrequency
                        )
                        .presentationDetents([.medium, .large, .height(450)])
                        .presentationDragIndicator(.visible)
                    }
                    Spacer()

                    // Daily Verse Section
                    VStack {
                        HStack {
                            Spacer()
                            if #available(iOS 16.0, *) {
                                Text("Daily Scripture")
                                    .underline()
                                    .padding(.top, 20)
                                    .font(horizontalSizeClass == .regular ? .title : .title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else { /* Fallback */ }
                            if selectedRefreshFrequency == .manual {
                                Spacer()
                                Button(action: {
                                    dailyScripture = ScriptureProvider.getRandomScripture()
                                    saveScriptureState()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.white)
                                        .padding(.top, 20)
                                        .padding(.trailing, 10)
                                }
                            } else {
                                Spacer()
                            }
                        }
                        Text(dailyScripture)
                            .font(selectedFontSize.fontForMain(horizontalSizeClass: horizontalSizeClass))
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
                    .background(selectedScriptureTheme.gradient)
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
                                        .font(selectedFontSize.fontForModal(horizontalSizeClass: horizontalSizeClass))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(selectedScriptureTheme.gradient)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .padding(.horizontal)
                        }
                        .presentationDetents([.medium, .large, .height(250)])
                        .presentationDragIndicator(.visible)
                    }

                    Spacer()

                    // Footer with Music Icon
                    HStack(spacing: horizontalSizeClass == .regular ? 60 : 30) {
                        SocialButton(icon: "facebook")
                        SocialButton(icon: "x-white")
                        SocialButton(icon: "instagram")
                        SocialButton(icon: "youtube")
                        SocialButton(icon: "cashapp")
                        SocialButton(icon: "music.note.list", isMusicButton: true, musicAction: {
                            showingMusicPlayer = true
                        })
                    }
                    .padding()
                    .sheet(isPresented: $showingMusicPlayer) {
                        YouTubePlayerView()
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                    }

                    Text("Developed by Brett: Brett Tech Networking")
                        .font(.footnote)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.bottom)
                }
            }
            .onAppear {
                loadGradientSelection()
                loadScriptureThemeSelection()
                loadFontSizeSelection()
                loadRefreshFrequencySelection()
                checkAndRefreshScripture()
                setupRefreshTimer()
            }
            .onChange(of: selectedRefreshFrequency) { _ in
                setupRefreshTimer()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // Helper Functions
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

    func loadGradientSelection() {
        if let savedGradientName = UserDefaults.standard.string(forKey: "selectedGradient"),
           let savedGradient = GradientOption(rawValue: savedGradientName) {
            selectedGradient = savedGradient
        } else {
            selectedGradient = .defaultOption
        }
    }

    func loadScriptureThemeSelection() {
        if let savedThemeName = UserDefaults.standard.string(forKey: "selectedScriptureTheme"),
           let savedTheme = ScriptureTheme(rawValue: savedThemeName) {
            selectedScriptureTheme = savedTheme
        } else {
            selectedScriptureTheme = .defaultTheme
        }
    }

    func loadFontSizeSelection() {
        if let savedFontSizeName = UserDefaults.standard.string(forKey: "selectedFontSize"),
           let savedFontSize = FontSizeOption(rawValue: savedFontSizeName) {
            selectedFontSize = savedFontSize
        } else {
            selectedFontSize = .medium
        }
    }

    func loadRefreshFrequencySelection() {
        if let savedFrequencyName = UserDefaults.standard.string(forKey: "selectedRefreshFrequency"),
           let savedFrequency = ScriptureRefreshFrequency(rawValue: savedFrequencyName) {
            selectedRefreshFrequency = savedFrequency
        } else {
            selectedRefreshFrequency = .onLaunch
        }
    }

    func checkAndRefreshScripture() {
        let now = Date()
        let lastRefresh = UserDefaults.standard.double(forKey: "lastScriptureRefresh")
        let lastRefreshDate = lastRefresh > 0 ? Date(timeIntervalSince1970: lastRefresh) : nil
        var shouldRefresh = false

        switch selectedRefreshFrequency {
        case .onLaunch:
            shouldRefresh = true // Always refresh on launch
        case .hourly:
            if let lastDate = lastRefreshDate {
                let hoursSinceLastRefresh = now.timeIntervalSince(lastDate) / 3600
                shouldRefresh = hoursSinceLastRefresh >= 1
            } else {
                shouldRefresh = true // First time, refresh
            }
        case .daily:
            if let lastDate = lastRefreshDate {
                let hoursSinceLastRefresh = now.timeIntervalSince(lastDate) / 3600
                shouldRefresh = hoursSinceLastRefresh >= 24
            } else {
                shouldRefresh = true // First time, refresh
            }
        case .manual:
            shouldRefresh = false // Only refresh manually
        }

        if shouldRefresh {
            dailyScripture = ScriptureProvider.getRandomScripture()
            saveScriptureState()
        }
    }

    func saveScriptureState() {
        UserDefaults.standard.set(dailyScripture, forKey: "dailyScripture")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastScriptureRefresh")
        print("Saved scripture state: \(dailyScripture), last refresh: \(Date())")
    }

    func setupRefreshTimer() {
        refreshTimer?.invalidate()
        switch selectedRefreshFrequency {
        case .hourly:
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                self.dailyScripture = ScriptureProvider.getRandomScripture()
                self.saveScriptureState()
                print("Hourly scripture refresh triggered")
            }
        case .daily:
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { _ in
                self.dailyScripture = ScriptureProvider.getRandomScripture()
                self.saveScriptureState()
                print("Daily scripture refresh triggered")
            }
        default:
            break // No timer for onLaunch or manual
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

enum GradientOption: String, CaseIterable {
    case defaultOption = "Default"
    case greenToLime = "Green to Lime"
    case redToOrange = "Red to Orange"
    case cyanToTeal = "Cyan to Teal"
    case purpleToPink = "Purple to Pink"
    case orangeToYellow = "Orange to Yellow"
    case blueToIndigo = "Blue to Indigo"

    var gradient: LinearGradient {
        switch self {
        case .defaultOption:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .greenToLime:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.6), Color.yellow.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .redToOrange:
            return LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.6), Color.orange.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cyanToTeal:
            return LinearGradient(
                gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.teal.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purpleToPink:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orangeToYellow:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.yellow.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blueToIndigo:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.indigo.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

enum ScriptureTheme: String, CaseIterable {
    case defaultTheme = "Default"
    case sunsetGlow = "Sunset Glow"
    case forestMist = "Forest Mist"
    case oceanBreeze = "Ocean Breeze"
    case lavenderDream = "Lavender Dream"
    case goldenDawn = "Golden Dawn"
    case midnightSky = "Midnight Sky"

    var gradient: LinearGradient {
        switch self {
        case .defaultTheme:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .sunsetGlow:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .forestMist:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.teal.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .oceanBreeze:
            return LinearGradient(
                gradient: Gradient(colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .lavenderDream:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .goldenDawn:
            return LinearGradient(
                gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .midnightSky:
            return LinearGradient(
                gradient: Gradient(colors: [Color.indigo.opacity(0.8), Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

enum FontSizeOption: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    func fontForMain(horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        switch self {
        case .small:
            return horizontalSizeClass == .regular ? .subheadline : .caption
        case .medium:
            return horizontalSizeClass == .regular ? .title2 : .body
        case .large:
            return horizontalSizeClass == .regular ? .title : .title2
        case .extraLarge:
            return horizontalSizeClass == .regular ? .largeTitle : .title
        }
    }

    func fontForModal(horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        switch self {
        case .small:
            return horizontalSizeClass == .regular ? .body : .caption
        case .medium:
            return horizontalSizeClass == .regular ? .title2 : .body
        case .large:
            return horizontalSizeClass == .regular ? .title : .title2
        case .extraLarge:
            return horizontalSizeClass == .regular ? .largeTitle : .title
        }
    }
}

enum ScriptureRefreshFrequency: String, CaseIterable {
    case onLaunch = "On Launch"
    case hourly = "Hourly"
    case daily = "Daily"
    case manual = "Manual"
}

struct GridButton: View {
    var title: String
    var icon: String
    var gradient: GradientOption
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
                    .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 0)
                Text(title)
                    .foregroundColor(.white)
                    .font(textFont)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .frame(width: textFrameWidth)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(gradient.gradient)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isTapped ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped)
    }
}

struct SocialButton: View {
    var icon: String
    var isMusicButton: Bool = false
    var musicAction: (() -> Void)? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var iconSize: CGFloat {
        horizontalSizeClass == .regular ? 45 : 30
    }

    var body: some View {
        Button(action: {
            if isMusicButton {
                musicAction?()
            } else {
                openSocialURL(for: icon)
            }
        }) {
            if isMusicButton {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.white)
            } else {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
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
