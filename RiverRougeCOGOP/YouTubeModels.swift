// YouTubeModels.swift
import Foundation

struct YouTubePlaylistResponse: Codable {
    let items: [YouTubePlaylistItem]?
}

struct YouTubePlaylistItem: Codable, Identifiable {
    let id = UUID()
    let snippet: YouTubeSnippet
}

struct YouTubeSnippet: Codable {
    let title: String
    let resourceId: YouTubeResourceId
    let thumbnails: YouTubeThumbnails?
}

struct YouTubeResourceId: Codable {
    let videoId: String
}

struct YouTubeThumbnails: Codable {
    let defaultThumbnail: YouTubeThumbnail?

    enum CodingKeys: String, CodingKey {
        case defaultThumbnail = "default"
    }
}

struct YouTubeThumbnail: Codable {
    let url: String
}
