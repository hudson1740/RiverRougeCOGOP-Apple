struct ScriptureProvider {
    static let scriptures = [
        "Your word is a lamp to my feet and a light to my path. - Psalm 119:105",
        "Trust in the Lord with all your heart and lean not on your own understanding. - Proverbs 3:5",
        "I can do all things through Christ who strengthens me. - Philippians 4:13",
        "Be strong and courageous. Do not be afraid or terrified because of them, for the Lord your God goes with you. - Deuteronomy 31:6",
        "The Lord is my shepherd; I shall not want. - Psalm 23:1",
        "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life. - John 3:16"
    ]
    
    static func getRandomScripture() -> String {
        return scriptures.randomElement() ?? "Be still, and know that I am God. - Psalm 46:10"
    }
}
