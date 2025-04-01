// ContentView.swift

import SwiftUI
import MapKit
import SafariServices

struct ContentView: View {
    @State private var dailyScripture = ScriptureProvider.getRandomScripture()
    @State private var showingAnnouncements = false
    @State private var showingBibleLink = false
    @State private var showingNotes = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Spacer()
                    Button(action: {
                        // Navigate to settings
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                .background(Color.black)

                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Church of God of Prophecy")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        Text("41 Orchard St. River Rouge, MI 48218")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image("cogop-trans")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.black]), startPoint: .leading, endPoint: .trailing))
                .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 5)

                // Grid Buttons
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    GridButton(title: "Join Service", icon: "person.3.fill")
                    GridButton(title: "Announcements", icon: "info.circle.fill")
                        .onTapGesture { showingAnnouncements = true }
                        .contentShape(Rectangle())
                    GridButton(title: "Bible", icon: "book.fill")
                        .onTapGesture {
                            if UIApplication.shared.canOpenURL(URL(string: "bible://")!) {
                                if let url = URL(string: "bible://") {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                showingBibleLink = true
                            }
                        }
                        .contentShape(Rectangle())
                    GridButton(title: "Location", icon: "map.fill")
                        .onTapGesture { openMaps(address: "41 Orchard St, River Rouge, MI 48218") }
                        .contentShape(Rectangle())
                    GridButton(title: "Giving", icon: "dollarsign.circle.fill")
                    GridButton(title: "Notes", icon: "note.text")
                        .onTapGesture { showingNotes = true }
                        .contentShape(Rectangle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .sheet(isPresented: $showingAnnouncements) {
                    AnnouncementsView()
                }
                .sheet(isPresented: $showingBibleLink) {
                    BibleLinkView()
                }
                .sheet(isPresented: $showingNotes) {
                    NotesView()
                }

                // Daily Verse Section
                VStack {
                    Text("Daily Scripture")
                        .underline()
                        .padding(20)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text(dailyScripture)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(.horizontal)
                .padding(.bottom, 10)

                // Footer
                HStack(spacing: 30) {
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
            .edgesIgnoringSafeArea(.top)
            .background(Color.black)
        }
    }
}

//location button
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

struct AnnouncementsView: View {
    var body: some View {
        Text("Hello, World!")
            .font(.largeTitle)
            .padding()
    }
}

struct BibleLinkView: View {
    var body: some View {
        VStack {
            Text("Open Bible App")
                .font(.title)
                .padding()
            Text("The Bible app is not installed. Would you like to install it from the App Store?")
                .padding()
            Button("Install from App Store") {
                if let url = URL(string: "https://apps.apple.com/us/app/bible-daily-bible-verse-kjv/id1357464684") {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
        }
    }
}

struct GridButton: View {
    var title: String
    var icon: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .shadow(radius: 5)
            Text(title)
                .foregroundColor(.white)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .frame(width: 110, height: 110)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .shadow(color: Color.white.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct SocialButton: View {
    var icon: String

    var body: some View {
        Image(icon)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(.blue)
            .shadow(radius: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
