import SwiftUI

// Main BibleView
struct BibleView: View {
    @Binding var showingBible: Bool
    private let books = [
        BibleBook(name: "Genesis", chapterCount: 50, apiName: "Genesis"),
        BibleBook(name: "Exodus", chapterCount: 40, apiName: "Exodus"),
        BibleBook(name: "Leviticus", chapterCount: 27, apiName: "Leviticus"),
        BibleBook(name: "Numbers", chapterCount: 36, apiName: "Numbers"),
        BibleBook(name: "Deuteronomy", chapterCount: 34, apiName: "Deuteronomy"),
        BibleBook(name: "Joshua", chapterCount: 24, apiName: "Joshua"),
        BibleBook(name: "Judges", chapterCount: 21, apiName: "Judges"),
        BibleBook(name: "Ruth", chapterCount: 4, apiName: "Ruth"),
        BibleBook(name: "1 Samuel", chapterCount: 31, apiName: "1+Samuel"),
        BibleBook(name: "2 Samuel", chapterCount: 24, apiName: "2+Samuel"),
        BibleBook(name: "1 Kings", chapterCount: 22, apiName: "1+Kings"),
        BibleBook(name: "2 Kings", chapterCount: 25, apiName: "2+Kings"),
        BibleBook(name: "1 Chronicles", chapterCount: 29, apiName: "1+Chronicles"),
        BibleBook(name: "2 Chronicles", chapterCount: 36, apiName: "2+Chronicles"),
        BibleBook(name: "Ezra", chapterCount: 10, apiName: "Ezra"),
        BibleBook(name: "Nehemiah", chapterCount: 13, apiName: "Nehemiah"),
        BibleBook(name: "Esther", chapterCount: 10, apiName: "Esther"),
        BibleBook(name: "Job", chapterCount: 42, apiName: "Job"),
        BibleBook(name: "Psalms", chapterCount: 150, apiName: "Psalms"),
        BibleBook(name: "Proverbs", chapterCount: 31, apiName: "Proverbs"),
        BibleBook(name: "Ecclesiastes", chapterCount: 12, apiName: "Ecclesiastes"),
        BibleBook(name: "Song of Solomon", chapterCount: 8, apiName: "Song+of+Solomon"),
        BibleBook(name: "Isaiah", chapterCount: 66, apiName: "Isaiah"),
        BibleBook(name: "Jeremiah", chapterCount: 52, apiName: "Jeremiah"),
        BibleBook(name: "Lamentations", chapterCount: 5, apiName: "Lamentations"),
        BibleBook(name: "Ezekiel", chapterCount: 48, apiName: "Ezekiel"),
        BibleBook(name: "Daniel", chapterCount: 12, apiName: "Daniel"),
        BibleBook(name: "Hosea", chapterCount: 14, apiName: "Hosea"),
        BibleBook(name: "Joel", chapterCount: 3, apiName: "Joel"),
        BibleBook(name: "Amos", chapterCount: 9, apiName: "Amos"),
        BibleBook(name: "Obadiah", chapterCount: 1, apiName: "Obadiah"),
        BibleBook(name: "Jonah", chapterCount: 4, apiName: "Jonah"),
        BibleBook(name: "Micah", chapterCount: 7, apiName: "Micah"),
        BibleBook(name: "Nahum", chapterCount: 3, apiName: "Nahum"),
        BibleBook(name: "Habakkuk", chapterCount: 3, apiName: "Habakkuk"),
        BibleBook(name: "Zephaniah", chapterCount: 3, apiName: "Zephaniah"),
        BibleBook(name: "Haggai", chapterCount: 2, apiName: "Haggai"),
        BibleBook(name: "Zechariah", chapterCount: 14, apiName: "Zechariah"),
        BibleBook(name: "Malachi", chapterCount: 4, apiName: "Malachi"),
        BibleBook(name: "Matthew", chapterCount: 28, apiName: "Matthew"),
        BibleBook(name: "Mark", chapterCount: 16, apiName: "Mark"),
        BibleBook(name: "Luke", chapterCount: 24, apiName: "Luke"),
        BibleBook(name: "John", chapterCount: 21, apiName: "John"),
        BibleBook(name: "Acts", chapterCount: 28, apiName: "Acts"),
        BibleBook(name: "Romans", chapterCount: 16, apiName: "Romans"),
        BibleBook(name: "1 Corinthians", chapterCount: 16, apiName: "1+Corinthians"),
        BibleBook(name: "2 Corinthians", chapterCount: 13, apiName: "2+Corinthians"),
        BibleBook(name: "Galatians", chapterCount: 6, apiName: "Galatians"),
        BibleBook(name: "Ephesians", chapterCount: 6, apiName: "Ephesians"),
        BibleBook(name: "Philippians", chapterCount: 4, apiName: "Philippians"),
        BibleBook(name: "Colossians", chapterCount: 4, apiName: "Colossians"),
        BibleBook(name: "1 Thessalonians", chapterCount: 5, apiName: "1+Thessalonians"),
        BibleBook(name: "2 Thessalonians", chapterCount: 3, apiName: "2+Thessalonians"),
        BibleBook(name: "1 Timothy", chapterCount: 6, apiName: "1+Timothy"),
        BibleBook(name: "2 Timothy", chapterCount: 4, apiName: "2+Timothy"),
        BibleBook(name: "Titus", chapterCount: 3, apiName: "Titus"),
        BibleBook(name: "Philemon", chapterCount: 1, apiName: "Philemon"),
        BibleBook(name: "Hebrews", chapterCount: 13, apiName: "Hebrews"),
        BibleBook(name: "James", chapterCount: 5, apiName: "James"),
        BibleBook(name: "1 Peter", chapterCount: 5, apiName: "1+Peter"),
        BibleBook(name: "2 Peter", chapterCount: 3, apiName: "2+Peter"),
        BibleBook(name: "1 John", chapterCount: 5, apiName: "1+John"),
        BibleBook(name: "2 John", chapterCount: 1, apiName: "2+John"),
        BibleBook(name: "3 John", chapterCount: 1, apiName: "3+John"),
        BibleBook(name: "Jude", chapterCount: 1, apiName: "Jude"),
        BibleBook(name: "Revelation", chapterCount: 22, apiName: "Revelation")
    ]
    
    @State private var navigationState: NavigationState = .books
    @State private var verses: [BibleVerse] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var highlightedVerses: Set<String> = []
    @State private var bookmarkedVerses: [String] = []
    @State private var showingBookmarks = false
    @State private var scrollToVerse: String?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let initialSearch: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .overlay(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.05), Color.black]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 500
                        )
                    )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        VStack {
                            Text("Holy Bible (KJV)")
                                .font(horizontalSizeClass == .regular ? .title : .title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            if case .verses(let book, let chapter) = navigationState {
                                Text("\(book.name) \(chapter)")
                                    .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .shadow(radius: 5)
                    
                    if showingBookmarks {
                        if bookmarkedVerses.isEmpty {
                            Text("No Bookmarks Yet")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(bookmarkedVerses, id: \.self) { bookmark in
                                        HStack {
                                            Text(bookmark)
                                                .font(.body)
                                                .foregroundColor(.white)
                                                .padding()
                                                .onTapGesture {
                                                    navigateToBookmark(bookmark)
                                                }
                                            Spacer()
                                            Button(action: {
                                                removeBookmark(bookmark)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.trailing)
                                        }
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        switch navigationState {
                        case .books:
                            BookListView(books: books, searchText: $searchText) { book in
                                navigationState = .chapters(book)
                            }
                        case .chapters(let book):
                            ChapterListView(book: book) { chapter in
                                navigationState = .verses(book, chapter)
                                fetchVerses(book: book.apiName, chapter: chapter)
                            }
                        case .verses(let book, let chapter):
                            VerseListView(
                                book: book,
                                chapter: chapter,
                                verses: verses,
                                highlightedVerses: $highlightedVerses,
                                bookmarkedVerses: $bookmarkedVerses,
                                scrollToVerse: $scrollToVerse
                            )
                        }
                    }
                }
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if case .chapters = navigationState {
                        Button(action: {
                            navigationState = .books
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                    } else if case .verses = navigationState {
                        Button(action: {
                            if case .verses(let book, _) = navigationState {
                                navigationState = .chapters(book)
                                verses = [] // Clear verses when going back
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                    } else if showingBookmarks {
                        Button(action: {
                            showingBookmarks = false
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                    } else {
                        Button(action: {
                            showingBible = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showingBookmarks {
                        Button(action: {
                            showingBookmarks.toggle()
                        }) {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadHighlightsAndBookmarks()
            if let initial = initialSearch, !initial.isEmpty {
                handleInitialSearch(initial)
            }
        }
    }
    
    private func getNavigationTitle() -> String {
        switch navigationState {
        case .books:
            return "Books"
        case .chapters(let book):
            return book.name
        case .verses(_, let chapter):
            return "Chapter \(chapter)"
        }
    }

    private func handleInitialSearch(_ search: String) {
        let normalizedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("Handling initial search: '\(normalizedSearch)'")

        let components = normalizedSearch.components(separatedBy: " ")
        guard components.count >= 2 else {
            print("Invalid search format: not enough components in '\(normalizedSearch)'")
            return
        }

        let chapterVerse = components.last!.components(separatedBy: ":")
        guard chapterVerse.count == 2,
              let chapter = Int(chapterVerse[0]),
              let verse = Int(chapterVerse[1]) else {
            print("Invalid chapter:verse format in '\(normalizedSearch)'")
            return
        }

        let bookNameComponents = components.dropLast()
        var bookName = bookNameComponents.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        
        // Handle special case for Psalms (singular/plural)
        if bookName.lowercased() == "psalm" {
            bookName = "Psalms"
        }

        print("Parsed - Book: '\(bookName)', Chapter: '\(chapter)', Verse: '\(verse)'")

        if let book = books.first(where: { $0.name.lowercased() == bookName.lowercased() }) {
            print("Found book: \(book.name)")
            if chapter > 0 && chapter <= book.chapterCount {
                print("Valid chapter: \(chapter), navigating and fetching verses...")
                navigationState = .verses(book, chapter)
                fetchVerses(book: book.apiName, chapter: chapter, highlightVerse: verse)
            } else {
                print("Invalid chapter: \(chapter) for book \(book.name) (max: \(book.chapterCount))")
                errorMessage = "Invalid chapter: \(chapter) for \(book.name)"
            }
        } else {
            print("Book not found: '\(bookName)'")
            print("Available books: \(books.map { $0.name.lowercased() })")
            errorMessage = "Book not found: \(bookName)"
        }
    }

    private func fetchVerses(book: String, chapter: Int, highlightVerse: Int? = nil) {
        isLoading = true
        errorMessage = nil

        let urlString = "https://bible-api.com/\(book)+\(chapter)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL: \(urlString)"
            isLoading = false
            print("Invalid URL: \(urlString)")
            return
        }

        print("Fetching URL: \(urlString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error fetching verses: \(error.localizedDescription)"
                    print("Fetch Error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received from API"
                    print("No data received")
                    return
                }
                do {
                    let jsonString = String(data: data, encoding: .utf8) ?? "Unable to decode JSON"
                    print("Received JSON: \(jsonString)")
                    let apiResponse = try JSONDecoder().decode(BibleAPIResponse.self, from: data)
                    self.verses = apiResponse.verses
                    if let verseNum = highlightVerse, let bookName = apiResponse.verses.first?.bookName {
                        let verseId = "\(bookName):\(chapter):\(verseNum)"
                        self.highlightedVerses.insert(verseId)
                        self.scrollToVerse = verseId
                        print("Highlighting and scrolling to verse ID: \(verseId)")
                    }
                } catch {
                    self.errorMessage = "Failed to parse data: \(error.localizedDescription)"
                    print("Parse Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func handleSearch() {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("Normalized search text: '\(normalizedSearch)'")

        let components = normalizedSearch.components(separatedBy: " ")
        guard components.count >= 2 else {
            print("Invalid search format: not enough components in '\(normalizedSearch)'")
            return
        }

        let chapterVerse = components.last!.components(separatedBy: ":")
        guard chapterVerse.count == 2,
              let chapter = Int(chapterVerse[0]),
              let verse = Int(chapterVerse[1]) else {
            print("Invalid chapter:verse format in '\(normalizedSearch)'")
            return
        }

        let bookNameComponents = components.dropLast()
        var bookName = bookNameComponents.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        
        // Handle special case for Psalms
        if bookName.lowercased() == "psalm" {
            bookName = "Psalms"
        }

        print("Parsed - Book: '\(bookName)', Chapter: '\(chapter)', Verse: '\(verse)'")

        if let book = books.first(where: { $0.name.lowercased() == bookName.lowercased() }) {
            print("Found book: \(book.name)")
            if chapter > 0 && chapter <= book.chapterCount {
                print("Valid chapter: \(chapter), fetching verses...")
                navigationState = .verses(book, chapter)
                fetchVerses(book: book.apiName, chapter: chapter, highlightVerse: verse)
                searchText = ""
            } else {
                print("Invalid chapter: \(chapter) for book \(book.name) (max: \(book.chapterCount))")
                errorMessage = "Invalid chapter: \(chapter) for \(book.name)"
            }
        } else {
            print("Book not found: '\(bookName)'")
            errorMessage = "Book not found: \(bookName)"
        }
    }

    private func loadHighlightsAndBookmarks() {
        if let savedHighlights = UserDefaults.standard.stringArray(forKey: "highlightedVerses") {
            highlightedVerses = Set(savedHighlights)
        }
        if let savedBookmarks = UserDefaults.standard.stringArray(forKey: "bookmarkedVerses") {
            bookmarkedVerses = savedBookmarks
        }
    }

    private func saveHighlights() {
        UserDefaults.standard.set(Array(highlightedVerses), forKey: "highlightedVerses")
    }

    private func saveBookmarks() {
        UserDefaults.standard.set(bookmarkedVerses, forKey: "bookmarkedVerses")
    }

    private func navigateToBookmark(_ bookmark: String) {
        let components = bookmark.components(separatedBy: " ")
        if components.count >= 2 {
            let bookName = components[0..<components.count-1].joined(separator: " ")
            let lastComponent = components.last ?? ""
            let verseComponents = lastComponent.components(separatedBy: ":")
            if verseComponents.count == 2,
               let chapter = Int(verseComponents[0]),
               let verse = Int(verseComponents[1]) {
                if let book = books.first(where: { $0.name.lowercased() == bookName.lowercased() }) {
                    if chapter > 0 && chapter <= book.chapterCount {
                        showingBookmarks = false
                        navigationState = .verses(book, chapter)
                        fetchVerses(book: book.apiName, chapter: chapter, highlightVerse: verse)
                    }
                }
            }
        }
    }

    private func removeBookmark(_ bookmark: String) {
        bookmarkedVerses.removeAll { $0 == bookmark }
        saveBookmarks()
    }
}

// Subviews
struct BookListView: View {
    let books: [BibleBook]
    @Binding var searchText: String
    let onBookSelected: (BibleBook) -> Void

    var filteredBooks: [BibleBook] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            HStack {
                TextField("Search Books (e.g., John 3:16)", text: $searchText, onCommit: {
                    // Handle search if needed in the future
                })
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 5)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredBooks) { book in
                        HStack {
                            Text(book.name)
                                .font(.title2)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .onTapGesture {
                            onBookSelected(book)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
}

struct ChapterListView: View {
    let book: BibleBook
    let onChapterSelected: (Int) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    HStack {
                        Text("Chapter \(chapter)")
                            .font(.title2)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .onTapGesture {
                        onChapterSelected(chapter)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct VerseListView: View {
    let book: BibleBook
    let chapter: Int
    let verses: [BibleVerse]
    @Binding var highlightedVerses: Set<String>
    @Binding var bookmarkedVerses: [String]
    @Binding var scrollToVerse: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(verses) { verse in
                        let verseId = verse.id
                        HStack(alignment: .top) {
                            Text("\(verse.verse).")
                                .font(.body)
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    toggleHighlight(verse: verse)
                                }
                            Text(verse.text)
                                .font(.body)
                                .foregroundColor(.white)
                                .onTapGesture {
                                    toggleHighlight(verse: verse)
                                }
                            Spacer()
                            Button(action: {
                                toggleBookmark(verse: verse)
                            }) {
                                Image(systemName: bookmarkedVerses.contains("\(verse.bookName) \(verse.chapter):\(verse.verse)") ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding()
                        .background(
                            highlightedVerses.contains(verseId) ?
                            Color.yellow.opacity(0.3) :
                            Color.gray.opacity(0.2)
                        )
                        .cornerRadius(10)
                        .id(verseId)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black)
            .onChange(of: scrollToVerse) { newValue in
                if let verseId = newValue {
                    withAnimation {
                        proxy.scrollTo(verseId, anchor: .top)
                    }
                    scrollToVerse = nil // Reset after scrolling
                }
            }
            .onAppear {
                if let verseId = scrollToVerse {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(verseId, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func toggleBookmark(verse: BibleVerse) {
        let bookmark = "\(verse.bookName) \(verse.chapter):\(verse.verse)"
        if bookmarkedVerses.contains(bookmark) {
            bookmarkedVerses.removeAll { $0 == bookmark }
        } else {
            bookmarkedVerses.append(bookmark)
        }
        UserDefaults.standard.set(bookmarkedVerses, forKey: "bookmarkedVerses")
    }

    private func toggleHighlight(verse: BibleVerse) {
        let verseId = verse.id
        if highlightedVerses.contains(verseId) {
            highlightedVerses.remove(verseId)
        } else {
            highlightedVerses.insert(verseId)
        }
        UserDefaults.standard.set(Array(highlightedVerses), forKey: "highlightedVerses")
    }
}

struct BibleView_Previews: PreviewProvider {
    static var previews: some View {
        BibleView(showingBible: .constant(true), initialSearch: "John 3:16")
            .preferredColorScheme(.dark)
    }
}
