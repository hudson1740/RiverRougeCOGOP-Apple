// Announcements.swift

import SwiftUI

struct Announcement: Identifiable {
    let id: String
    let title: String
    let description: String
}

struct AnnouncementsView: View {
    // Static data for now (you can replace this with another data source later)
    @State private var announcements: [Announcement] = [
        Announcement(id: "1", title: "Sunday Service Update", description: "Join us this Sunday at 10 AM for a special service."),
        Announcement(id: "2", title: "Prayer Meeting", description: "Weekly prayer meeting on Wednesday at 7 PM.")
    ]
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            // Title
            Text("Announcements")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 20)

            if isLoading {
                ProgressView("Loading announcements...")
                    .foregroundColor(.white)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if announcements.isEmpty {
                Text("No announcements available.")
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            } else {
                // List of announcements
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(announcements) { announcement in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(announcement.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(announcement.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct AnnouncementsView_Previews: PreviewProvider {
    static var previews: some View {
        AnnouncementsView()
            .preferredColorScheme(.dark)
    }
}
