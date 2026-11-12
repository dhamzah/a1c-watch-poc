import Foundation

/// POC parser for dictated food/activity logs, Indonesian + English + mixed.
/// Production: send the text to Sally (backend LLM) and get a structured log back.
enum LogParser {
    // rough carbs per typical portion (g)
    static let foods: [(keys: [String], name: String, carbs: Int)] = [
        (["nasi padang"], "Nasi padang", 75),
        (["nasi goreng", "fried rice"], "Nasi goreng", 70),
        (["nasi uduk"], "Nasi uduk", 65),
        (["nasi", "rice"], "Rice", 55),
        (["mie", "mi goreng", "noodle", "bakmi", "kwetiau"], "Noodles", 60),
        (["roti", "bread", "toast"], "Bread", 25),
        (["rendang"], "Rendang", 5),
        (["ayam", "chicken"], "Chicken", 0),
        (["ikan", "fish"], "Fish", 0),
        (["telur", "egg"], "Egg", 1),
        (["tempe"], "Tempe", 8),
        (["tahu", "tofu"], "Tofu", 3),
        (["sayur", "vegetable", "salad", "gado"], "Vegetables", 10),
        (["pisang", "banana"], "Banana", 27),
        (["martabak"], "Martabak", 60),
        (["kopi susu", "es kopi"], "Iced coffee with milk", 30),
        (["teh manis", "sweet tea"], "Sweet tea", 25),
        (["boba", "bubble tea"], "Bubble tea", 50),
        (["durian"], "Durian", 35),
        (["oat", "oatmeal"], "Oatmeal", 30),
    ]
    static let activities: [(keys: [String], name: String)] = [
        (["jalan", "walk"], "Walk"), (["lari", "run", "jogging"], "Run"),
        (["sepeda", "bike", "cycling"], "Cycling"), (["gym", "angkat beban", "weights", "strength"], "Strength"),
        (["renang", "swim"], "Swim"), (["badminton", "bulutangkis"], "Badminton"),
        (["yoga"], "Yoga"), (["padel", "tennis", "tenis"], "Tennis/Padel"),
    ]

    static func parse(_ raw: String, at date: Date = Date()) -> LogEntry {
        let text = raw.lowercased()
        let half = text.contains("half") || text.contains("setengah") || text.contains("separuh")
        let minutes = firstMinutes(in: text)

        if let a = activities.first(where: { $0.keys.contains { text.contains($0) } }),
           minutes != nil || foods.allSatisfy({ !$0.keys.contains { text.contains($0) } }) {
            return LogEntry(date: date, kind: .activity, text: raw,
                            summary: "\(a.name)\(minutes.map { " · \($0) min" } ?? "")", carbsG: nil, minutes: minutes)
        }
        if text.contains("0spike") || text.contains("zerospike") || text.contains("allulose") {
            return LogEntry(date: date, kind: .supplement, text: raw, summary: "0Spike allulose", carbsG: 0, minutes: nil)
        }
        if text.contains("air putih") || text.contains("water") {
            return LogEntry(date: date, kind: .water, text: raw, summary: "Water", carbsG: 0, minutes: nil)
        }
        if ["pusing", "lemas", "dizzy", "tired", "ngantuk", "mual"].contains(where: text.contains) {
            return LogEntry(date: date, kind: .symptom, text: raw, summary: raw, carbsG: nil, minutes: nil)
        }

        var matched: [String] = []
        var carbs = 0
        var used = text
        for f in foods {
            if let k = f.keys.first(where: { used.contains($0) }) {
                var c = f.carbs
                var n = f.name
                if half && (f.name == "Rice" || f.name.hasPrefix("Nasi")) { c /= 2; n += " (half rice)" }
                matched.append(n); carbs += c
                used = used.replacingOccurrences(of: k, with: " ")
                // a "nasi X" dish already includes rice
                if f.name.hasPrefix("Nasi ") { used = used.replacingOccurrences(of: "nasi", with: " ").replacingOccurrences(of: "rice", with: " ") }
            }
        }
        let summary = matched.isEmpty ? raw.capitalized : matched.joined(separator: ", ")
        return LogEntry(date: date, kind: .food, text: raw, summary: summary,
                        carbsG: matched.isEmpty ? nil : carbs, minutes: nil)
    }

    private static func firstMinutes(in text: String) -> Int? {
        let pattern = #"(\d{1,3})\s*(min|mins|minute|minutes|menit|m\b)"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text) else {
            if text.contains("jam") || text.contains("hour") { return 60 }
            return nil
        }
        return Int(text[r])
    }
}
