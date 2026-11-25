import UIKit
import CoreText
import CoreGraphics

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

// MARK: - Thèmes

struct Palette {
    let id: String
    let label: String
    let bg: UIColor
    let card: UIColor
    let text: UIColor
    let sub: UIColor
    let accent: UIColor
    let onAccent: UIColor
    let stroke: UIColor
    let light: Bool
}

enum Themes {
    static let all: [Palette] = [
        Palette(id: "clair", label: "☀ Clair",
                bg: UIColor(hex: 0xF5F6FA), card: UIColor(hex: 0xFFFFFF), text: UIColor(hex: 0x1F2430), sub: UIColor(hex: 0x5B6472),
                accent: UIColor(hex: 0x4F5BD5), onAccent: UIColor(hex: 0xFFFFFF), stroke: UIColor(hex: 0xE3E6EF), light: true),
        Palette(id: "sombre", label: "🌙 Sombre reposant",
                bg: UIColor(hex: 0x1C2025), card: UIColor(hex: 0x272C33), text: UIColor(hex: 0xE4E0D6), sub: UIColor(hex: 0x9AA3AD),
                accent: UIColor(hex: 0x8FA8E8), onAccent: UIColor(hex: 0x14181C), stroke: UIColor(hex: 0x3A414A), light: false),
        Palette(id: "sepia", label: "📜 Sépia / papier",
                bg: UIColor(hex: 0xF3EAD3), card: UIColor(hex: 0xFBF5E6), text: UIColor(hex: 0x3F3125), sub: UIColor(hex: 0x6F604C),
                accent: UIColor(hex: 0x9A6A3A), onAccent: UIColor(hex: 0xFFFFFF), stroke: UIColor(hex: 0xE0D3B5), light: true),
        Palette(id: "doux", label: "🌿 Contraste doux",
                bg: UIColor(hex: 0xE6EEF0), card: UIColor(hex: 0xF3F8F8), text: UIColor(hex: 0x2C3A40), sub: UIColor(hex: 0x55676E),
                accent: UIColor(hex: 0x3C7A89), onAccent: UIColor(hex: 0xFFFFFF), stroke: UIColor(hex: 0xC9D8DB), light: true)
    ]

    static func get() -> Palette {
        let id = Store.get(K.theme, "clair")
        return all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - Polices

struct FontDef {
    let name: String
    let group: String
    let css: String?   // nom Google Fonts
    let url: String?   // URL directe
}

enum Fonts {
    static let none = "Système"
    static let groups = ["Par défaut", "Spécial confort", "Sans-serif moderne", "Géométrique", "Avec empattement"]

    static let all: [FontDef] = [
        FontDef(name: none, group: "Par défaut", css: nil, url: nil),
        FontDef(name: "Lexend", group: "Spécial confort", css: "Lexend", url: nil),
        FontDef(name: "OpenDyslexic", group: "Spécial confort", css: nil,
                url: "https://raw.githubusercontent.com/antijingoist/opendyslexic/master/compiled/OpenDyslexic-Regular.otf"),
        FontDef(name: "Inter", group: "Sans-serif moderne", css: "Inter", url: nil),
        FontDef(name: "Roboto", group: "Sans-serif moderne", css: "Roboto", url: nil),
        FontDef(name: "Open Sans", group: "Sans-serif moderne", css: "Open Sans", url: nil),
        FontDef(name: "DM Sans", group: "Sans-serif moderne", css: "DM Sans", url: nil),
        FontDef(name: "Manrope", group: "Sans-serif moderne", css: "Manrope", url: nil),
        FontDef(name: "Work Sans", group: "Sans-serif moderne", css: "Work Sans", url: nil),
        FontDef(name: "Poppins", group: "Géométrique", css: "Poppins", url: nil),
        FontDef(name: "Montserrat", group: "Géométrique", css: "Montserrat", url: nil),
        FontDef(name: "Nunito", group: "Géométrique", css: "Nunito", url: nil),
        FontDef(name: "Lato", group: "Géométrique", css: "Lato", url: nil),
        FontDef(name: "Playfair Display", group: "Avec empattement", css: "Playfair Display", url: nil),
        FontDef(name: "Lora", group: "Avec empattement", css: "Lora", url: nil),
        FontDef(name: "Libre Baskerville", group: "Avec empattement", css: "Libre Baskerville", url: nil)
    ]

    private static var psNames: [String: String] = [:]

    private static var dir: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Store.group)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("fonts", isDirectory: true)
    }

    private static func fileURL(_ f: FontDef) -> URL {
        dir.appendingPathComponent(f.name.replacingOccurrences(of: " ", with: "_") + ".font")
    }

    /// Enregistre la police depuis le disque (sans réseau). Renvoie son nom PostScript, ou nil.
    @discardableResult
    static func register(_ name: String) -> String? {
        if let ps = psNames[name] { return ps }
        guard let f = all.first(where: { $0.name == name }), f.css != nil || f.url != nil else { return nil }
        guard let data = try? Data(contentsOf: fileURL(f)), data.count > 1000,
              let provider = CGDataProvider(data: data as CFData),
              let cg = CGFont(provider),
              let psCF = cg.postScriptName else { return nil }
        var err: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(cg, &err)   // renvoie false si déjà enregistrée : sans importance
        let ps = psCF as String
        psNames[name] = ps
        return ps
    }

    static func uiFont(_ name: String, size: CGFloat, bold: Bool = false) -> UIFont {
        if let ps = register(name), let f = UIFont(name: ps, size: size) {
            if bold, let d = f.fontDescriptor.withSymbolicTraits(.traitBold) { return UIFont(descriptor: d, size: size) }
            return f
        }
        return bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
    }

    /// Télécharge la police si besoin (une seule fois), puis l'enregistre.
    static func ensure(_ name: String) async throws {
        guard let f = all.first(where: { $0.name == name }), f.css != nil || f.url != nil else { return }
        if register(name) != nil { return }

        var fileUrl = f.url ?? ""
        if f.url == nil {
            // Un User-Agent ancien pousse Google Fonts à renvoyer du TTF (et non du woff2).
            let family = f.css!.replacingOccurrences(of: " ", with: "+")
            let cssData = try await fetch("https://fonts.googleapis.com/css?family=\(family):400",
                                          ua: "Mozilla/5.0 (Linux; U; Android 4.0.3; en-us)")
            guard let css = String(data: cssData, encoding: .utf8),
                  let r = css.range(of: "url\\(([^)]+)\\)", options: .regularExpression) else {
                throw RewriteError.msg("police introuvable")
            }
            fileUrl = String(css[r]).dropFirst(4).dropLast(1)
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
        }
        let data = try await fetch(fileUrl, ua: nil)
        guard isFont(data) else { throw RewriteError.msg("format de police non supporté") }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: fileURL(f))
        guard register(name) != nil else { throw RewriteError.msg("police illisible") }
    }

    private static func fetch(_ url: String, ua: String?) async throws -> Data {
        guard let u = URL(string: url) else { throw RewriteError.msg("URL invalide") }
        var req = URLRequest(url: u)
        req.timeoutInterval = 30
        if let ua = ua { req.setValue(ua, forHTTPHeaderField: "User-Agent") }
        let (d, r) = try await URLSession.shared.data(for: req)
        let code = (r as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw RewriteError.msg("HTTP \(code)") }
        return d
    }

    private static func isFont(_ d: Data) -> Bool {
        guard d.count > 1000 else { return false }
        let h = [UInt8](d.prefix(4))
        return h == [0x4F, 0x54, 0x54, 0x4F] || h == [0x74, 0x72, 0x75, 0x65] || h == [0x00, 0x01, 0x00, 0x00]
    }
}
