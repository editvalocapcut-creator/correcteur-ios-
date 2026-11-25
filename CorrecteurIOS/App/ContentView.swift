import SwiftUI

@MainActor
struct ContentView: View {
    @State private var key = Store.get(K.key)
    @State private var model = Store.get(K.model, Rewriter.defaultModel)
    @State private var examples = Store.get(K.examples)
    @State private var rules = Store.get(K.rules)
    @State private var themeId = Store.get(K.theme, "clair")
    @State private var fontName = Store.get(K.font, Fonts.none)
    @State private var testText = "salut sa va ? je voudrai savoir si tu es dispo demain pour la reunion"
    @State private var testMode = Mode.correct
    @State private var testOut = ""
    @State private var busy = false
    @State private var info = ""

    private var p: Palette { Themes.all.first { $0.id == themeId } ?? Themes.all[0] }
    private func col(_ c: UIColor) -> Color { Color(uiColor: c) }
    private func f(_ size: CGFloat, bold: Bool = false) -> Font {
        Font(Fonts.uiFont(fontName, size: size, bold: bold) as CTFont)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("✎ Assistant d'écriture").font(f(26, bold: true))
                Text("Corrige et reformule tes textes dans toutes tes applis, grâce au clavier Correcteur IA.")
                    .font(f(15)).foregroundColor(col(p.sub))
                keyboardCard
                lookCard
                groqCard
                styleCard
                testCard
                if !info.isEmpty { Text(info).font(f(14)).foregroundColor(col(p.sub)) }
            }
            .padding(16)
        }
        .foregroundColor(col(p.text))
        .lineSpacing(4)
        .background(col(p.bg).ignoresSafeArea())
        .preferredColorScheme(p.light ? .light : .dark)
    }

    // MARK: Composants

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22).fill(col(p.card)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(col(p.stroke), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private func pill(_ t: String, primary: Bool = false) -> some View {
        Text(t).font(f(primary ? 16 : 15, bold: primary))
            .frame(maxWidth: .infinity, minHeight: primary ? 50 : 44)
            .foregroundColor(col(primary ? p.onAccent : p.text))
            .background(RoundedRectangle(cornerRadius: 14).fill(col(primary ? p.accent : p.bg)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(col(p.stroke), lineWidth: primary ? 0 : 1))
    }

    private func btn(_ t: String, primary: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { pill(t, primary: primary) }
    }

    private func boxed<V: View>(_ v: V) -> some View {
        v.font(f(15)).padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(col(p.bg)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(col(p.stroke), lineWidth: 1))
    }

    private func section(_ t: String) -> some View { Text(t).font(f(18, bold: true)) }
    private func hint(_ t: String) -> some View { Text(t).font(f(14)).foregroundColor(col(p.sub)) }

    // MARK: Cartes

    private var keyboardCard: some View {
        card {
            section("Clavier")
            hint("1. Réglages › Général › Clavier › Claviers › Ajouter un clavier › Correcteur IA\n2. Touche « Correcteur IA », puis active « Autoriser l'accès complet » (nécessaire pour joindre Groq)\n3. Dans une appli, touche 🌐 pour passer sur le clavier Correcteur IA, écris, puis touche un mode.")
            btn("Ouvrir les réglages") {
                if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
            }
        }
    }

    private var lookCard: some View {
        card {
            section("Apparence")
            hint("Thème")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Themes.all, id: \.id) { t in
                    let sel = t.id == themeId
                    Button {
                        themeId = t.id
                        Store.set(K.theme, t.id)
                    } label: {
                        Text(t.label).font(f(14, bold: sel))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundColor(col(sel ? p.onAccent : p.text))
                            .background(RoundedRectangle(cornerRadius: 14).fill(col(sel ? p.accent : p.bg)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(col(p.stroke), lineWidth: sel ? 0 : 1))
                    }
                }
            }
            hint("Police")
            Menu {
                ForEach(Fonts.groups, id: \.self) { g in
                    Section(g) {
                        ForEach(Fonts.all.filter { $0.group == g }, id: \.name) { fd in
                            Button(fd.name) { chooseFont(fd.name) }
                        }
                    }
                }
            } label: { pill("Aa   \(fontName)   ▾") }
            Text("« Les élèves écrivent des phrases courtes et claires. » 0123456789").font(f(16)).padding(.top, 4)
        }
    }

    private var groqCard: some View {
        card {
            section("Connexion Groq")
            boxed(SecureField("Clé API (gsk_...)", text: $key).textInputAutocapitalization(.never).autocorrectionDisabled())
            boxed(TextField("Modèle", text: $model).textInputAutocapitalization(.never).autocorrectionDisabled())
        }
    }

    private var styleCard: some View {
        card {
            section("Mon style d'écriture")
            hint("Utilisé par le mode « Mon style ». Colle des messages que tu as vraiment écrits.")
            boxed(TextEditor(text: $examples).scrollContentBackground(.hidden).frame(minHeight: 130))
            hint("Mes règles : tutoiement, pas de point final, emojis rares, phrases courtes…")
            boxed(TextEditor(text: $rules).scrollContentBackground(.hidden).frame(minHeight: 70))
            btn("💾 Enregistrer", primary: true) { saveAll(); info = "Enregistré ✓" }
        }
    }

    private var testCard: some View {
        card {
            section("Tester")
            boxed(TextEditor(text: $testText).scrollContentBackground(.hidden).frame(minHeight: 80))
            Menu {
                ForEach(Mode.allCases, id: \.self) { m in
                    Button(m.label) { testMode = m }
                }
            } label: { pill("Mode : \(testMode.label)   ▾") }
            btn(busy ? "…" : "▶ Lancer le test", primary: true) { runTest() }
            if !testOut.isEmpty { Text(testOut).font(f(16)).textSelection(.enabled) }
        }
    }

    // MARK: Actions

    private func saveAll() {
        Store.set(K.key, key.trimmingCharacters(in: .whitespacesAndNewlines))
        Store.set(K.model, model.trimmingCharacters(in: .whitespacesAndNewlines))
        Store.set(K.examples, examples)
        Store.set(K.rules, rules)
    }

    private func chooseFont(_ name: String) {
        info = name == Fonts.none ? "" : "Téléchargement de la police…"
        Task {
            do {
                try await Fonts.ensure(name)
                fontName = name
                Store.set(K.font, name)
                info = ""
            } catch {
                info = "Police indisponible : \(error.localizedDescription)"
            }
        }
    }

    private func runTest() {
        saveAll()
        busy = true
        testOut = "…"
        Task {
            do { testOut = try await Rewriter.run(mode: testMode, text: testText) }
            catch { testOut = "❌ " + error.localizedDescription }
            busy = false
        }
    }
}
