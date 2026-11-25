import UIKit

final class KeyboardViewController: UIInputViewController {
    private var pal = Themes.get()
    private var fontName = Fonts.none
    private var shift = false
    private var numbers = false
    private var statusText = ""
    private let status = UILabel()
    private var deleteTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let h = view.heightAnchor.constraint(equalToConstant: 300)
        h.priority = .defaultHigh
        h.isActive = true
        build()
        let name = Store.get(K.font, Fonts.none)
        if name != Fonts.none {
            Task {
                try? await Fonts.ensure(name)
                await MainActor.run { self.build() }
            }
        }
    }

    // MARK: Construction

    private func build() {
        pal = Themes.get()
        fontName = Store.get(K.font, Fonts.none)
        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = pal.bg

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 5
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])

        add(modeBar(), to: root, h: 40)

        status.text = statusText
        status.font = Fonts.uiFont(fontName, size: 12)
        status.textColor = pal.sub
        status.textAlignment = .center
        add(status, to: root, h: 18)

        add(row(["é", "è", "ê", "à", "ù", "ç", "ô", "î"].map { letterKey($0) }), to: root, h: 34)

        if numbers {
            add(row("1234567890".map { plainKey(String($0)) }), to: root, h: 42)
            add(row("-/:;()€&@\"".map { plainKey(String($0)) }), to: root, h: 42)
            var r3: [UIView] = [plainKey("#")]
            r3 += [".", ",", "?", "!", "'"].map { plainKey($0) }
            r3.append(deleteKey())
            add(row(r3), to: root, h: 42)
        } else {
            add(row("azertyuiop".map { letterKey(String($0)) }), to: root, h: 42)
            add(row("qsdfghjklm".map { letterKey(String($0)) }), to: root, h: 42)
            var r3: [UIView] = [specialKey(shift ? "⬆︎" : "⇧") { [weak self] in
                self?.shift.toggle()
                self?.build()
            }]
            r3 += "wxcvbn".map { letterKey(String($0)) }
            r3.append(deleteKey())
            add(row(r3), to: root, h: 42)
        }
        add(bottomRow(), to: root, h: 42)
    }

    private func add(_ v: UIView, to root: UIStackView, h: CGFloat) {
        v.heightAnchor.constraint(equalToConstant: h).isActive = true
        root.addArrangedSubview(v)
    }

    private func row(_ keys: [UIView]) -> UIStackView {
        let s = UIStackView(arrangedSubviews: keys)
        s.axis = .horizontal
        s.spacing = 4
        s.distribution = .fillEqually
        return s
    }

    private func modeBar() -> UIView {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        let st = UIStackView()
        st.axis = .horizontal
        st.spacing = 6
        st.translatesAutoresizingMaskIntoConstraints = false
        sv.addSubview(st)
        NSLayoutConstraint.activate([
            st.leadingAnchor.constraint(equalTo: sv.contentLayoutGuide.leadingAnchor),
            st.trailingAnchor.constraint(equalTo: sv.contentLayoutGuide.trailingAnchor),
            st.topAnchor.constraint(equalTo: sv.contentLayoutGuide.topAnchor),
            st.bottomAnchor.constraint(equalTo: sv.contentLayoutGuide.bottomAnchor),
            st.heightAnchor.constraint(equalTo: sv.frameLayoutGuide.heightAnchor)
        ])
        for m in Mode.allCases {
            var c = UIButton.Configuration.filled()
            c.title = m.shortLabel
            c.baseBackgroundColor = pal.accent
            c.baseForegroundColor = pal.onAccent
            c.cornerStyle = .capsule
            c.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            let name = fontName
            c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
                var a = a
                a.font = Fonts.uiFont(name, size: 15)
                return a
            }
            let b = UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in self?.apply(m) })
            st.addArrangedSubview(b)
        }
        return sv
    }

    // MARK: Touches

    private func baseKey(_ title: String, bg: UIColor, fg: UIColor, action: @escaping () -> Void) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        b.setTitleColor(fg, for: .normal)
        b.titleLabel?.font = Fonts.uiFont(fontName, size: 20)
        b.backgroundColor = bg
        b.layer.cornerRadius = 9
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.15
        b.layer.shadowRadius = 0.5
        b.layer.shadowOffset = CGSize(width: 0, height: 1)
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return b
    }

    private func letterKey(_ s: String) -> UIButton {
        let t = shift ? s.uppercased() : s
        return baseKey(t, bg: pal.card, fg: pal.text) { [weak self] in
            guard let self = self else { return }
            self.textDocumentProxy.insertText(t)
            if self.shift { self.shift = false; self.build() }
        }
    }

    private func plainKey(_ s: String) -> UIButton {
        baseKey(s, bg: pal.card, fg: pal.text) { [weak self] in self?.textDocumentProxy.insertText(s) }
    }

    private func specialKey(_ title: String, accent: Bool = false, action: @escaping () -> Void) -> UIButton {
        baseKey(title, bg: accent ? pal.accent : pal.stroke, fg: accent ? pal.onAccent : pal.text, action: action)
    }

    private func deleteKey() -> UIButton {
        let b = specialKey("⌫") { }
        b.addAction(UIAction { [weak self] _ in
            self?.textDocumentProxy.deleteBackward()
            self?.deleteTimer?.invalidate()
            self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
                    self?.textDocumentProxy.deleteBackward()
                }
            }
        }, for: .touchDown)
        let stop = UIAction { [weak self] _ in
            self?.deleteTimer?.invalidate()
            self?.deleteTimer = nil
        }
        b.addAction(stop, for: .touchUpInside)
        b.addAction(stop, for: .touchUpOutside)
        b.addAction(stop, for: .touchCancel)
        return b
    }

    private func bottomRow() -> UIStackView {
        let sw = specialKey(numbers ? "ABC" : "123") { [weak self] in
            self?.numbers.toggle()
            self?.build()
        }
        let globe = specialKey("🌐") { [weak self] in self?.advanceToNextInputMode() }
        let keyBtn = specialKey("🔑") { [weak self] in self?.importKey() }
        let space = baseKey("espace", bg: pal.card, fg: pal.sub) { [weak self] in
            self?.textDocumentProxy.insertText(" ")
        }
        let ret = specialKey("↵", accent: true) { [weak self] in self?.textDocumentProxy.insertText("\n") }
        let s = UIStackView(arrangedSubviews: [sw, globe, keyBtn, space, ret])
        s.axis = .horizontal
        s.spacing = 4
        s.distribution = .fill
        [sw, globe, keyBtn, ret].forEach { $0.widthAnchor.constraint(equalToConstant: 52).isActive = true }
        space.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        return s
    }

    // MARK: Actions

    private func flash(_ s: String) {
        DispatchQueue.main.async {
            self.statusText = s
            self.status.text = s
        }
    }

    /// Colle une clé « gsk_… » copiée dans le presse-papier (utile si l'App Group n'est pas disponible).
    private func importKey() {
        guard hasFullAccess else { flash("Active « Autoriser l'accès complet » dans Réglages › Claviers"); return }
        if let s = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), s.hasPrefix("gsk_") {
            Store.set(K.key, s)
            flash("Clé enregistrée ✓")
        } else {
            flash("Copie d'abord ta clé gsk_… puis touche 🔑")
        }
    }

    private func apply(_ mode: Mode) {
        guard hasFullAccess else { flash("Active « Autoriser l'accès complet » dans Réglages › Claviers"); return }
        let proxy = textDocumentProxy
        let selected = proxy.selectedText ?? ""
        let hasSelection = !selected.isEmpty
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        let original = hasSelection ? selected : before + after
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            flash("Rien à traiter : écris d'abord un texte")
            return
        }
        flash("Réécriture…")
        Task {
            do {
                let out = try await Rewriter.run(mode: mode, text: original)
                await MainActor.run {
                    self.replace(original, with: out, hasSelection: hasSelection, afterCount: after.count)
                }
            } catch {
                self.flash(error.localizedDescription)
            }
        }
    }

    private func replace(_ original: String, with out: String, hasSelection: Bool, afterCount: Int) {
        let p = textDocumentProxy
        let now = hasSelection ? (p.selectedText ?? "") : ((p.documentContextBeforeInput ?? "") + (p.documentContextAfterInput ?? ""))
        guard now == original else {
            UIPasteboard.general.string = out
            flash("Le texte a changé : résultat copié")
            return
        }
        if hasSelection {
            p.insertText(out)   // remplace la sélection
            flash("✓ Terminé")
            return
        }
        let finish = {
            for _ in 0..<original.count { p.deleteBackward() }
            p.insertText(out)
            self.flash("✓ Terminé")
        }
        if afterCount > 0 {
            p.adjustTextPosition(byCharacterOffset: afterCount)   // curseur en fin de texte
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: finish)
        } else {
            finish()
        }
    }
}
