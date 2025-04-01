// notes.swift

import SwiftUI

struct NotesView: View {
    @State private var searchText = ""
    @State private var selectedCategory = 0
    @State private var notes: [Note] = []
    @State private var newNoteText = ""
    @State private var showingNewNoteSheet = false
    @State private var editingNote: Note?
    @State private var noteToDelete: Note?
    @State private var showingDeleteConfirmation = false
    @State private var folders: [Folder] = []
    @State private var showingFolderManager = false
    @State private var noteToMove: Note?
    @State private var showingMoveToFolderSheet = false

    var filteredNotes: [Note] {
        if selectedCategory == 0 {
            return notes
        } else {
            guard let selectedFolder = folders.first(where: { $0.id == UUID(uuidString: "\(selectedCategory)") }) else {
                return []
            }
            return notes.filter { $0.folder == selectedFolder.name }
        }
    }

    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search Notes...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)

            // Category Tabs
            HStack {
                Picker("Category", selection: $selectedCategory) {
                    Text("All Notes").tag(0)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(folder.id.hashValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                Button(action: {
                    showingFolderManager = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 30))
                }
                .padding(.trailing)
            }

            // Note Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(filteredNotes) { note in
                        NoteCardView(note: note)
                            .onTapGesture {
                                editingNote = note
                            }
                            .contextMenu {
                                Button(role: .none) {
                                    noteToMove = note
                                    showingMoveToFolderSheet = true
                                } label: {
                                    Label("Move to Folder", systemImage: "folder")
                                }
                                Button(role: .destructive) {
                                    noteToDelete = note
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }

            // Add Note Button
            HStack {
                Spacer()
                Button(action: {
                    showingNewNoteSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                }
            }
            .padding()

//            // Delete Button (Placeholder)
//            Button(action: {
//                // Add Delete Functionality
//            }) {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 40))
//                    .foregroundColor(.red)
//            }
//            .padding(.bottom)
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteView(newNoteText: $newNoteText, onSave: { title, text in
                let newNote = Note(title: title, text: text, folder: nil, category: selectedCategory)
                notes.append(newNote)
                newNoteText = ""
                showingNewNoteSheet = false
            })
        }
        .sheet(item: $editingNote) { note in
            NoteEditorView(note: note, onNoteUpdated: { updatedNote in
                if let index = notes.firstIndex(of: note) {
                    notes[index] = updatedNote
                }
            })
        }
        .sheet(isPresented: $showingFolderManager) {
            FolderManagerView(folders: $folders)
        }
        .sheet(isPresented: $showingMoveToFolderSheet) {
            if let note = noteToMove {
                MoveToFolderView(folders: $folders, note: note, onMove: { folder in
                    if let index = notes.firstIndex(of: note) {
                        notes[index].folder = folder.name
                        selectedCategory = folder.id.hashValue
                        saveNotes() // Save notes immediately
                    }
                    noteToMove = nil
                    showingMoveToFolderSheet = false
                })
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Note?"),
                message: Text("Are you sure you want to delete this note?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                    noteToDelete = nil
                },
                secondaryButton: .cancel() {
                    noteToDelete = nil
                }
            )
        }
        .onAppear {
            loadNotes()
            loadFolders()
        }
        .onChange(of: notes) { _ in
            saveNotes()
        }
        .onChange(of: folders) { _ in
            saveFolders()
        }
    }

    func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "savedNotes")
        } else {
            print("Error encoding notes")
        }
    }

    func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: "savedNotes") {
            if let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotes) {
                notes = decodedNotes
            } else {
                print("Error decoding notes")
            }
        }
    }

    func deleteNote(_ note: Note) {
        if let index = notes.firstIndex(of: note) {
            notes.remove(at: index)
            saveNotes() // Save notes immediately
        }
    }

    func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: "savedFolders")
        } else {
            print("Error encoding folders")
        }
    }

    func loadFolders() {
        if let savedFolders = UserDefaults.standard.data(forKey: "savedFolders") {
            if let decodedFolders = try? JSONDecoder().decode([Folder].self, from: savedFolders) {
                folders = decodedFolders
            } else {
                print("Error decoding folders")
            }
        }
    }
}

struct NoteCardView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.headline)
            Text(previewText(note.text))
                .font(.body)
            Spacer()
            Text(Date(), style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.random().opacity(0.8))
        .cornerRadius(10)
    }

    func previewText(_ text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let preview = words.prefix(10).joined(separator: " ")
        if words.count > 10 {
            return preview + "..."
        } else {
            return preview
        }
    }
}

struct Note: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var text: String
    var folder: String?
    var category: Int
}

struct NewNoteView: View {
    @Binding var newNoteText: String
    @State private var newNoteTitle = ""
    var onSave: (String, String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $newNoteTitle)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $newNoteText)
                            .padding()

                        if newNoteText.isEmpty {
                            Text("Note...")
                                .foregroundColor(.gray)
                                .position(x: 50, y: 35)
                        }
                    }
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(newNoteTitle, newNoteText)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NoteEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var note: Note
    @State private var editedTitle = ""
    @State private var editedText = ""
    var onNoteUpdated: (Note) -> Void

    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $editedTitle)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $editedText)
                            .padding()

                        if editedText.isEmpty {
                            Text("Note...")
                                .foregroundColor(.gray)
                                .position(x: 50, y: 35)
                        }
                    }
                }
            }
            .navigationTitle("Edit Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let updatedNote = Note(title: editedTitle, text: editedText, folder: note.folder, category: note.category)
                        onNoteUpdated(updatedNote)
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedTitle = note.title
                editedText = note.text
            }
        }
    }
}

struct Folder: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
}

struct FolderManagerView: View {
    @Binding var folders: [Folder]
    @State private var newFolderName = ""
    @State private var folderToEdit: Folder?
    @State private var editedFolderName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach($folders) { $folder in
                    HStack {
                        Text(folder.name)
                        Spacer()
                        Button("Edit") {
                            folderToEdit = folder
                            editedFolderName = folder.name
                        }
                    }
                }
                .onDelete(perform: deleteFolder)

                HStack {
                    TextField("New Folder Name", text: $newFolderName)
                    Button("Add") {
                        addFolder()
                    }
                }
            }
            .navigationTitle("Manage Folders")
            .sheet(item: $folderToEdit) { folder in
                NavigationView {
                    TextField("Folder Name", text: $editedFolderName)
                        .padding()
                        .navigationTitle("Edit Folder")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    updateFolder(folder)
                                    folderToEdit = nil
                                }
                            }
                        }
                }
            }
        }
    }

    func addFolder() {
        let newFolder = Folder(name: newFolderName)
        folders.append(newFolder)
        newFolderName = ""
    }

    func deleteFolder(at offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
    }

    func updateFolder(_ folder: Folder) {
        if let index = folders.firstIndex(of: folder) {
            folders[index].name = editedFolderName
        }
    }
}

struct MoveToFolderView: View {
    @Binding var folders: [Folder]
    let note: Note
    var onMove: (Folder) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(folders) { folder in
                    Button(folder.name) {
                        onMove(folder)
                    }
                }
            }
            .navigationTitle("Move to Folder")
        }
    }
}

extension Color {
    static func random() -> Color {
        return Color(
            red: .random(in: 0.2...0.9),
            green: .random(in: 0.2...0.9),
            blue: .random(in: 0.2...0.9)
        )
    }
}
