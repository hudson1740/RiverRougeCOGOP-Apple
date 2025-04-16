import Foundation

// Define Navigation State
enum NavigationState {
    case books
    case chapters(BibleBook)
    case verses(BibleBook, Int)
}

// BibleBook struct
struct BibleBook: Identifiable {
    let id = UUID()
    let name: String
    let chapterCount: Int
    let apiName: String
}

// BibleVerse struct
struct BibleVerse: Codable, Identifiable {
    var id: String {
        "\(bookName):\(chapter):\(verse)"
    }
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case bookName = "book_name"
        case chapter
        case verse
        case text
    }
}

// BibleAPIResponse struct
struct BibleAPIResponse: Codable {
    let verses: [BibleVerse]
}
