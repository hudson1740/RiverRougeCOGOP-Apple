import SwiftUI

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []

    init() {
        loadNotes()
        loadFolders()
    }

    func saveNotes() {
        let url = getDocumentsDirectory().appendingPathComponent("notes.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(notes)
            try data.write(to: url, options: [.atomicWrite])
            print("Saved \(notes.count) notes: \(notes.map { "\($0.title) in \($0.folder ?? "None")" })")
        } catch {
            print("Error saving notes: \(error.localizedDescription)")
        }
    }

    func loadNotes() {
        let url = getDocumentsDirectory().appendingPathComponent("notes.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("No notes file at \(url.path)")
            notes = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            notes = try decoder.decode([Note].self, from: data)
            print("Loaded \(notes.count) notes")
        } catch {
            print("Error loading notes: \(error.localizedDescription)")
            notes = []
        }
    }

    func saveFolders() {
        let url = getDocumentsDirectory().appendingPathComponent("folders.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(folders)
            try data.write(to: url, options: [.atomicWrite])
            print("Saved \(folders.count) folders: \(folders.map { $0.name })")
        } catch {
            print("Error saving folders: \(error.localizedDescription)")
        }
    }

    func loadFolders() {
        let url = getDocumentsDirectory().appendingPathComponent("folders.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("No folders file at \(url.path)")
            folders = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            folders = try decoder.decode([Folder].self, from: data)
            print("Loaded \(folders.count) folders: \(folders.map { $0.name })")
        } catch {
            print("Error loading folders: \(error.localizedDescription)")
            folders = []
        }
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: UUID? = nil  // nil represents "All Notes"
    @State private var newNoteText = ""
    @State private var showingNewNoteSheet = false
    @State private var editingNote: Note?
    @State private var noteToDelete: Note?
    @State private var showingDeleteConfirmation = false
    @State private var showingFolderManager = false
    @State private var noteToMove: Note?
    @State private var showingMoveToFolderSheet = false

    var filteredNotes: [Note] {
        let categoryFiltered: [Note]
        if let selectedFolderId = selectedCategory {
            if let selectedFolder = viewModel.folders.first(where: { $0.id == selectedFolderId }) {
                categoryFiltered = viewModel.notes.filter { $0.folder == selectedFolder.name }
            } else {
                categoryFiltered = []
            }
        } else {
            categoryFiltered = viewModel.notes.filter { $0.folder == nil || $0.folder?.isEmpty == true }
        }

        if searchText.isEmpty {
            print("Filtered notes for \(selectedCategory?.uuidString ?? "All Notes"): \(categoryFiltered.map { $0.title })")
            return categoryFiltered
        } else {
            let searchFiltered = categoryFiltered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
            print("Filtered notes for \(selectedCategory?.uuidString ?? "All Notes") & search '\(searchText)': \(searchFiltered.map { $0.title })")
            return searchFiltered
        }
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search Notes...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)

            HStack {
                Picker("Category", selection: $selectedCategory) {
                    Text("All Notes").tag(nil as UUID?)
                    ForEach(viewModel.folders) { folder in
                        Text(folder.name).tag(folder.id as UUID?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.leading)

                Button(action: { showingFolderManager = true }) {
                    Image(systemName: "folder.badge.plus")
                        .imageScale(.large)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 5)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)], spacing: 15) {
                    ForEach(filteredNotes) { note in
                        NoteCardView(note: note)
                            .onTapGesture { editingNote = note }
                            .contextMenu {
                                Button {
                                    print("Move requested for '\(note.title)' in '\(note.folder ?? "None")'")
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
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
                .padding()
            }

            HStack {
                Spacer()
                Button(action: { showingNewNoteSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                        .shadow(radius: 3)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteView(newNoteText: $newNoteText) { title, text in
                let folderName: String?
                if let selectedFolderId = selectedCategory,
                   let selectedFolder = viewModel.folders.first(where: { $0.id == selectedFolderId }) {
                    folderName = selectedFolder.name
                } else {
                    folderName = nil
                }
                let newNote = Note(title: title.isEmpty ? "Untitled Note" : title, text: text, folder: folderName)
                viewModel.notes.append(newNote)
                viewModel.saveNotes()
                newNoteText = ""
                showingNewNoteSheet = false
            }
        }
        .sheet(item: $editingNote) { note in
            NoteEditorView(note: note) { updatedNote in
                if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                    viewModel.notes[index] = updatedNote
                    viewModel.saveNotes()
                }
                editingNote = nil
            }
        }
        .sheet(isPresented: $showingFolderManager) {
            FolderManagerView(folders: $viewModel.folders, selectedCategory: $selectedCategory, notes: $viewModel.notes)
        }
        .sheet(isPresented: $showingMoveToFolderSheet, onDismiss: {
            print("Move sheet dismissed. Notes: \(viewModel.notes.map { "\($0.title) in \($0.folder ?? "None")" })")
            noteToMove = nil
        }) {
            if let note = noteToMove {
                MoveToFolderView(folders: $viewModel.folders, note: note) { selectedFolder in
                    if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                        var updatedNote = viewModel.notes[index]
                        let oldFolder = updatedNote.folder
                        updatedNote.folder = selectedFolder?.name
                        updatedNote.lastModified = Date()
                        viewModel.notes[index] = updatedNote
                        viewModel.saveNotes()
                        selectedCategory = selectedFolder?.id ?? nil
                        print("Moved '\(updatedNote.title)' from '\(oldFolder ?? "None")' to '\(updatedNote.folder ?? "None")'")
                    }
                    showingMoveToFolderSheet = false
                }
            }
        }
        .alert("Delete Note?", isPresented: $showingDeleteConfirmation, presenting: noteToDelete) { note in
            Button("Delete", role: .destructive) {
                viewModel.notes.removeAll { $0.id == note.id }
                viewModel.saveNotes()
                noteToDelete = nil
            }
            Button("Cancel", role: .cancel) { noteToDelete = nil }
        } message: { note in
            Text("Are you sure you want to delete \"\(note.title)\"? This cannot be undone.")
        }
    }
}

struct NoteCardView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            Text(previewText(note.text))
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(maxHeight: .infinity, alignment: .top)
            Spacer()
            Text(note.lastModified, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.randomNoteColor().opacity(0.7))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 1, y: 2)
    }

    func previewText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "No additional text" }
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines)
        let preview = words.prefix(15).joined(separator: " ")
        return words.count > 15 ? preview + "..." : preview
    }
}

struct Note: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String
    var folder: String?
    var lastModified: Date = Date()

    static func ==(lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

struct NewNoteView: View {
    @Binding var newNoteText: String
    @State private var newNoteTitle = ""
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Title", text: $newNoteTitle)
                    .padding()
                    .background(Color(.systemGray6))
                    .padding([.horizontal, .top])
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $newNoteText)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    if newNoteText.isEmpty {
                        Text("Note...")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.horizontal, 22)
                            .padding(.top, 13)
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(newNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines), newNoteText)
                        dismiss()
                    }
                    .disabled(newNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                              newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct NoteEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var note: Note
    let onNoteUpdated: (Note) -> Void
    @State private var editedTitle: String = ""
    @State private var editedText: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Title", text: $editedTitle)
                    .padding()
                    .background(Color(.systemGray6))
                    .padding([.horizontal, .top])
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $editedText)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    if editedText.isEmpty {
                        Text("Note...")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.horizontal, 22)
                            .padding(.top, 13)
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        var updatedNote = note
                        updatedNote.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Note" : editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        updatedNote.text = editedText
                        updatedNote.lastModified = Date()
                        onNoteUpdated(updatedNote)
                        dismiss()
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                              editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editedTitle = note.title
                editedText = note.text
            }
        }
    }
}

struct Folder: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String

    static func ==(lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FolderManagerView: View {
    @Binding var folders: [Folder]
    @Binding var selectedCategory: UUID?
    @Binding var notes: [Note]
    @State private var newFolderName = ""
    @State private var folderToEdit: Folder?
    @State private var editedFolderName = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Existing Folders")) {
                    if folders.isEmpty {
                        Text("No folders created yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(folders) { folder in
                            HStack {
                                Image(systemName: "folder")
                                Text(folder.name)
                                Spacer()
                                Button {
                                    folderToEdit = folder
                                    editedFolderName = folder.name
                                } label: {
                                    Image(systemName: "pencil").foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Button {
                                    deleteFolder(folder)
                                } label: {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .onDelete(perform: deleteFolder(at:))
                    }
                }
                Section(header: Text("Add New Folder")) {
                    HStack {
                        TextField("New Folder Name", text: $newFolderName) {
                            addFolder()
                        }
                        Button("Add") { addFolder() }
                            .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Manage Folders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $folderToEdit) { folder in
                NavigationView {
                    VStack {
                        TextField("Folder Name", text: $editedFolderName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Edit Folder Name")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { folderToEdit = nil }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                updateFolder(folder)
                            }
                            .disabled(editedFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                      editedFolderName == folder.name)
                        }
                    }
                }
            }
            .onDisappear {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("folders.json")
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(folders)
                    try data.write(to: url, options: [.atomicWrite])
                    print("Saved \(folders.count) folders on dismiss: \(folders.map { $0.name })")
                } catch {
                    print("Error saving folders on dismiss: \(error.localizedDescription)")
                }
            }
        }
    }

    func addFolder() {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              !folders.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame })
        else { return }
        let newFolder = Folder(name: trimmedName)
        folders.append(newFolder)
        folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        newFolderName = ""
        print("Added folder: \(trimmedName)")
    }

    func deleteFolder(at offsets: IndexSet) {
        offsets.forEach { index in deleteFolder(folders[index]) }
    }

    func deleteFolder(_ folder: Folder) {
        let deletedFolderName = folder.name
        let notesToUpdateIndices = notes.indices.filter { notes[$0].folder == deletedFolderName }
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders.remove(at: index)
            print("Deleted folder: \(deletedFolderName)")
            if !notesToUpdateIndices.isEmpty {
                for i in notesToUpdateIndices {
                    notes[i].folder = nil
                    notes[i].lastModified = Date()
                    print("Moved note '\(notes[i].title)' from '\(deletedFolderName)' to 'All Notes'")
                }
                // Save notes immediately after moving them
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("notes.json")
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(notes)
                    try data.write(to: url, options: [.atomicWrite])
                    print("Saved \(notes.count) notes after folder deletion: \(notes.map { "\($0.title) in \($0.folder ?? "None")" })")
                } catch {
                    print("Error saving notes after folder deletion: \(error.localizedDescription)")
                }
            }
            if selectedCategory == folder.id {
                selectedCategory = nil // Switch to "All Notes" if deleted folder was selected
                print("Switched to 'All Notes' after deleting selected folder")
            }
            if folderToEdit?.id == folder.id { folderToEdit = nil }
        }
    }

    func updateFolder(_ folder: Folder) {
        let newTrimmedName = editedFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldName = folder.name
        guard !newTrimmedName.isEmpty,
              !folders.contains(where: { $0.id != folder.id && $0.name.localizedCaseInsensitiveCompare(newTrimmedName) == .orderedSame })
        else { return }
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].name = newTrimmedName
            folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if oldName != newTrimmedName {
                let notesToUpdateIndices = notes.indices.filter { notes[$0].folder == oldName }
                for i in notesToUpdateIndices {
                    notes[i].folder = newTrimmedName
                    notes[i].lastModified = Date()
                }
            }
            folderToEdit = nil
        }
    }
}

struct MoveToFolderView: View {
    @Binding var folders: [Folder]
    let note: Note
    let onMove: (Folder?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    print("Moving '\(note.title)' to 'All Notes'")
                    onMove(nil)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "tray.full")
                        Text("All Notes")
                        Spacer()
                        if note.folder == nil || note.folder?.isEmpty == true {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
                Section(header: Text("Folders")) {
                    if folders.isEmpty {
                        Text("No folders available.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(folders) { folder in
                            Button(action: {
                                print("Moving '\(note.title)' to '\(folder.name)'")
                                onMove(folder)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text(folder.name)
                                    Spacer()
                                    if note.folder == folder.name {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move \"\(note.title)\" to...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                print("MoveToFolderView opened for '\(note.title)'. Folders: \(folders.map { $0.name })")
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    static func randomNoteColor() -> Color {
        let noteColors: [Color] = [
            Color(hex: "d52600"), // Red
            Color(hex: "0acb45"), // Green
            Color(hex: "2900c0")  // Blueple
        ]
        return noteColors.randomElement() ?? Color.gray.opacity(0.3)
    }
}
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
    }
}
