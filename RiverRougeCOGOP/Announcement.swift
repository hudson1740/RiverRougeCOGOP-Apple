// Announcement.swift
import Foundation

struct Announcement: Identifiable, Codable, Equatable {
    var id: String
    let title: String
    let body: String
    let timeInfo: String
    let priority: Int
}
