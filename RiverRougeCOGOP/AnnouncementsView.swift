import SwiftUI

struct AnnouncementsView: View {
    @StateObject private var viewModel = AnnouncementsViewModel()
    @State private var errorMessage: String? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                titleView
                contentView
                Spacer()
            }
            .background(backgroundGradient)
            .cornerRadius(15)
            .shadow(radius: 10)
            .padding(.horizontal)
        }
        .onAppear {
            print("AnnouncementsView appeared, fetching data...")
            errorMessage = nil
            viewModel.fetchAnnouncements()
        }
        .onChange(of: viewModel.announcements) { newAnnouncements in
            print("Announcements updated: \(newAnnouncements.count) items loaded")
            for announcement in newAnnouncements {
                print("Announcement: \(announcement.title), Priority: \(announcement.priority)")
            }
        }
    }

    // Extracted title view
    private var titleView: some View {
        Group {
            if #available(iOS 16.0, *) {
                Text("Announcements")
                    .underline()
                    .padding(.top, 40)
                    .font(horizontalSizeClass == .regular ? .largeTitle : .title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("Announcements")
                    .padding(.top, 40)
                    .font(horizontalSizeClass == .regular ? .largeTitle : .title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }

    // Extracted content view
    private var contentView: some View {
        Group {
            if viewModel.isFetching {
                ProgressView("Loading announcements...")
                    .foregroundColor(.white)
                    .padding()
            } else if let message = errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.announcements.isEmpty {
                Text("No announcements available.")
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            } else {
                announcementsList
            }
        }
    }

    // Extracted announcements list
    private var announcementsList: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(viewModel.announcements) { announcement in
                    announcementCard(announcement: announcement)
                }
            }
            .padding(.bottom)
        }
        .refreshable {
            await refreshAnnouncements()
        }
    }

    // Extracted refresh logic
    private func refreshAnnouncements() async {
        // Debounce: Ignore refresh if one is already in progress or within 1 second of the last refresh
        let now = Date()
        if isRefreshing {
            print("Refresh skipped: Already refreshing")
            return
        }
        if let lastRefresh = lastRefreshTime, now.timeIntervalSince(lastRefresh) < 1 {
            print("Refresh skipped: Too soon after last refresh")
            return
        }

        isRefreshing = true
        lastRefreshTime = now
        defer { isRefreshing = false }

        print("Pull-to-refresh triggered")
        errorMessage = nil
        viewModel.fetchAnnouncements()

        // Wait for the fetch to complete
        await Task { @MainActor in
            while viewModel.isFetching {
                try? await Task.sleep(nanoseconds: 100_000_000) // Sleep for 100ms, ignore errors
            }
        }.value

        // Set error message if no announcements were loaded
        if viewModel.announcements.isEmpty {
            errorMessage = "Failed to load announcements. Please try again."
        }
    }

    // Extracted announcement card
    private func announcementCard(announcement: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(announcement.title)
                .font(.headline)
                .foregroundColor(.white)
            Text(announcement.body)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            Text(announcement.timeInfo)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .italic()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    // Extracted background gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct AnnouncementsView_Previews: PreviewProvider {
    static var previews: some View {
        AnnouncementsView()
            .preferredColorScheme(.dark)
    }
}
