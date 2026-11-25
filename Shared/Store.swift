import Foundation

enum K {
    static let key = "api_key"
    static let model = "model"
    static let examples = "examples"
    static let rules = "rules"
    static let theme = "theme"
    static let font = "font"
}

/// Réglages partagés entre l'appli et le clavier via un App Group.
/// Si l'App Group n'est pas disponible (signature gratuite), chaque cible garde sa propre copie.
enum Store {
    static let group = "group.com.example.correcteur"
    private static var shared: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    static func get(_ k: String, _ d: String = "") -> String {
        shared.string(forKey: k) ?? UserDefaults.standard.string(forKey: k) ?? d
    }

    static func set(_ k: String, _ v: String) {
        shared.set(v, forKey: k)
        UserDefaults.standard.set(v, forKey: k)
    }
}
