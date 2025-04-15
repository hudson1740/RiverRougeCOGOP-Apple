// AnnouncementsViewModel.swift
import Foundation
import SwiftUI

class AnnouncementsViewModel: ObservableObject {
    @Published var announcements: [Announcement] = []
    @Published var isFetching = false // New property to track fetch state

    func fetchAnnouncements() {
        isFetching = true
        let cacheBuster = Int(Date().timeIntervalSince1970)
        guard let url = URL(string: "https://hudson1740.github.io/RiverRougeCOGOP-Apple/announcements.json?cb=\(cacheBuster)") else {
            print("Invalid URL")
            self.loadFallbackData()
            self.isFetching = false
            return
        }

        print("Starting fetch from \(url)")
        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadFallbackData()
                    self.isFetching = false
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response received")
                DispatchQueue.main.async {
                    self.loadFallbackData()
                    self.isFetching = false
                }
                return
            }

            print("HTTP Status Code: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200 else {
                print("Unexpected status code: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    self.loadFallbackData()
                    self.isFetching = false
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.loadFallbackData()
                    self.isFetching = false
                }
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON data: \(jsonString)")
            } else {
                print("Could not convert data to string")
            }

            do {
                let decoder = JSONDecoder()
                let fetchedAnnouncements = try decoder.decode([Announcement].self, from: data)
                DispatchQueue.main.async {
                    print("Successfully fetched \(fetchedAnnouncements.count) announcements: \(fetchedAnnouncements)")
                    self.announcements = fetchedAnnouncements.sorted { $0.priority < $1.priority }
                    self.isFetching = false
                }
            } catch {
                print("Detailed decoding error: \(error)")
                DispatchQueue.main.async {
                    self.loadFallbackData()
                    self.isFetching = false
                }
            }
        }.resume()
    }

    private func loadFallbackData() {
        let fallbackAnnouncements = [
            Announcement(id: "1", title: "Sunday School", body: "Join us at 11 AM every Sunday", timeInfo: "Sunday 11 AM", priority: 1),
            Announcement(id: "2", title: "Sunday Service", body: "Join us at 12PM every Sunday", timeInfo: "Sunday 12PM", priority: 2),
            Announcement(id: "3", title: "Bible Study", body: "Join us for Bible Study!", timeInfo: "Wednesday 6PM", priority: 3),
            Announcement(id: "4", title: "Good Friday Service", body: "Join our annual Good Friday Service", timeInfo: "April 18th", priority: 4)
        ]
        print("Using fallback data: \(fallbackAnnouncements)")
        self.announcements = fallbackAnnouncements.sorted { $0.priority < $1.priority }
    }
}
