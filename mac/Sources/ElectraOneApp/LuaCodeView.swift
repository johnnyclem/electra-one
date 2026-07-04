import SwiftUI
import AppKit

// MARK: - Syntax-highlighted Lua editor (NSTextView)

struct LuaCodeView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSView {
        // Build the text stack on TextKit 1 explicitly. On macOS 26,
        // `NSTextView.scrollableTextView()` hands back a TextKit 2 view; once we
        // attach a custom NSRulerView (line numbers) and touch its layout
        // manager, that view stops drawing glyphs entirely — the gutter shows
        // line numbers but the code is invisible, at any text color. Creating an
        // NSLayoutManager and wiring the storage/container/text view by hand pins
        // the whole thing to TextKit 1, which renders reliably.
        //
        // Line numbers are NOT drawn with an NSRulerView: under SwiftUI hosting
        // an NSRulerView attached to this scroll view suppresses the text view's
        // glyph drawing (the gutter renders but the code disappears — the exact
        // "invisible text" bug). Instead we place a plain sibling gutter view to
        // the left and redraw it as the text scrolls.
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let container = NSTextContainer(
            containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)

        let textView = NSTextView(frame: .zero, textContainer: container)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = LuaTheme.font
        textView.drawsBackground = true
        textView.backgroundColor = LuaTheme.background
        textView.insertionPointColor = LuaTheme.plain
        textView.textColor = LuaTheme.plain
        // Defeat dark-appearance "adaptive color mapping", which darkens our light
        // text toward the dark background until the code disappears. The opt-out
        // flag is unreliable on recent macOS, so we also pin the editor to the
        // LIGHT appearance — that mapping only runs in dark appearance, so under
        // aqua our explicit colors render exactly as set.
        let lightAppearance = NSAppearance(named: .aqua)
        textView.appearance = lightAppearance
        textView.usesAdaptiveColorMappingForDarkAppearance = false // available since 10.14
        textView.typingAttributes = [.font: LuaTheme.font, .foregroundColor: LuaTheme.plain]
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.string = text

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.appearance = lightAppearance
        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = LuaTheme.background
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false

        let gutter = LineNumberGutter(textView: textView)
        gutter.appearance = lightAppearance
        context.coordinator.gutter = gutter
        context.coordinator.textView = textView

        // Container: fixed-width gutter on the left, scroll view fills the rest.
        let host = NSView()
        gutter.translatesAutoresizingMaskIntoConstraints = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(gutter)
        host.addSubview(scroll)
        NSLayoutConstraint.activate([
            gutter.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            gutter.topAnchor.constraint(equalTo: host.topAnchor),
            gutter.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            gutter.widthAnchor.constraint(equalToConstant: LineNumberGutter.width),
            scroll.leadingAnchor.constraint(equalTo: gutter.trailingAnchor),
            scroll.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: host.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])

        // Redraw the gutter whenever the text scrolls.
        let clip = scroll.contentView
        clip.postsBoundsChangedNotifications = true
        context.coordinator.scrollObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification, object: clip, queue: .main
        ) { [weak gutter] _ in gutter?.needsDisplay = true }

        LuaHighlighter.apply(to: textView)
        return host
    }

    func updateNSView(_ host: NSView, context: Context) {
        // Re-point the coordinator at the latest struct value so its delegate
        // callbacks write through the current Binding, not the first render's.
        context.coordinator.parent = self
        guard let textView = context.coordinator.textView else { return }
        if textView.string != text {
            let sel = textView.selectedRange()
            textView.string = text
            LuaHighlighter.apply(to: textView)
            // Preserve the selection (clamped) rather than collapsing it.
            let len = (text as NSString).length
            let loc = min(sel.location, len)
            textView.setSelectedRange(NSRange(location: loc, length: min(sel.length, len - loc)))
        }
        context.coordinator.gutter?.needsDisplay = true
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LuaCodeView
        weak var gutter: LineNumberGutter?
        weak var textView: NSTextView?
        var scrollObserver: NSObjectProtocol?
        init(_ parent: LuaCodeView) { self.parent = parent }
        deinit { if let o = scrollObserver { NotificationCenter.default.removeObserver(o) } }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            LuaHighlighter.apply(to: tv)
            gutter?.needsDisplay = true
        }
    }
}

// MARK: - Theme

enum LuaTheme {
    static let font = NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)
    static let background = NSColor(calibratedRed: 0.99, green: 0.99, blue: 0.99, alpha: 1)
    static let plain = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1)
    static let comment = NSColor(calibratedRed: 0.40, green: 0.52, blue: 0.40, alpha: 1)
    static let string = NSColor(calibratedRed: 0.72, green: 0.30, blue: 0.16, alpha: 1)
    static let number = NSColor(calibratedRed: 0.10, green: 0.42, blue: 0.72, alpha: 1)
    static let keyword = NSColor(calibratedRed: 0.68, green: 0.18, blue: 0.42, alpha: 1)
    static let api = NSColor(calibratedRed: 0.08, green: 0.52, blue: 0.48, alpha: 1)
    static let funcName = NSColor(calibratedRed: 0.55, green: 0.40, blue: 0.05, alpha: 1)
    static let gutter = NSColor(calibratedWhite: 0.60, alpha: 1)
}

// MARK: - Highlighter

enum LuaHighlighter {
    private static let keywords: Set<String> = [
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
        "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return",
        "then", "true", "until", "while",
    ]
    private static let apiGlobals: Set<String> = [
        "controls", "control", "parameterMap", "midi", "timer", "info", "window",
        "helpers", "overlays", "controller", "transport", "patch", "groups",
        "pages", "device", "print", "json", "preset",
    ]

    static func apply(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let ns = textView.string as NSString
        let full = NSRange(location: 0, length: ns.length)

        storage.beginEditing()
        storage.setAttributes([.font: LuaTheme.font, .foregroundColor: LuaTheme.plain], range: full)
        for tok in tokens(ns) {
            storage.addAttribute(.foregroundColor, value: tok.color, range: tok.range)
        }
        storage.endEditing()
    }

    private struct Tok { let range: NSRange; let color: NSColor }

    private static func tokens(_ s: NSString) -> [Tok] {
        var out: [Tok] = []
        let n = s.length
        var i = 0

        func isIdentStart(_ c: unichar) -> Bool {
            (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95
        }
        func isIdent(_ c: unichar) -> Bool { isIdentStart(c) || (c >= 48 && c <= 57) }
        func isDigit(_ c: unichar) -> Bool { (c >= 48 && c <= 57) }

        while i < n {
            let c = s.character(at: i)

            if c == 0x5B {
                if let close = longBracketEnd(s, open: i) {
                    out.append(Tok(range: NSRange(location: i, length: close - i), color: LuaTheme.string))
                    i = close
                    continue
                }
            }

            if c == 0x2D, i + 1 < n, s.character(at: i + 1) == 0x2D {
                if i + 2 < n, s.character(at: i + 2) == 0x5B, let close = longBracketEnd(s, open: i + 2) {
                    out.append(Tok(range: NSRange(location: i, length: close - i), color: LuaTheme.comment))
                    i = close
                    continue
                }
                var j = i + 2
                while j < n, s.character(at: j) != 0x0A { j += 1 }
                out.append(Tok(range: NSRange(location: i, length: j - i), color: LuaTheme.comment))
                i = j
                continue
            }

            if c == 0x22 || c == 0x27 {
                let quote = c
                var j = i + 1
                while j < n {
                    let cj = s.character(at: j)
                    if cj == 0x5C { j += 2; continue }
                    if cj == quote || cj == 0x0A { j += 1; break }
                    j += 1
                }
                out.append(Tok(range: NSRange(location: i, length: min(j, n) - i), color: LuaTheme.string))
                i = min(j, n)
                continue
            }

            if isDigit(c) || (c == 0x2E && i + 1 < n && isDigit(s.character(at: i + 1))) {
                var j = i + 1
                var isHex = false
                // 0x / 0X prefix — only then are hex digits part of the number.
                if c == 0x30, j < n, s.character(at: j) == 0x78 || s.character(at: j) == 0x58 {
                    isHex = true
                    j += 1
                }
                while j < n {
                    let cj = s.character(at: j)
                    if isDigit(cj) || cj == 0x2E
                        || (isHex && ((cj >= 65 && cj <= 70) || (cj >= 97 && cj <= 102))) {
                        j += 1
                    } else if !isHex, cj == 0x65 || cj == 0x45 {
                        // Exponent marker; a sign is only valid immediately after
                        // it (so `1-2` no longer highlights as one number).
                        j += 1
                        if j < n, s.character(at: j) == 0x2B || s.character(at: j) == 0x2D { j += 1 }
                    } else {
                        break
                    }
                }
                out.append(Tok(range: NSRange(location: i, length: j - i), color: LuaTheme.number))
                i = j
                continue
            }

            if isIdentStart(c) {
                var j = i + 1
                while j < n, isIdent(s.character(at: j)) { j += 1 }
                let word = s.substring(with: NSRange(location: i, length: j - i))
                if keywords.contains(word) {
                    out.append(Tok(range: NSRange(location: i, length: j - i), color: LuaTheme.keyword))
                } else if apiGlobals.contains(word) {
                    out.append(Tok(range: NSRange(location: i, length: j - i), color: LuaTheme.api))
                } else {
                    let prev = precedingWord(s, before: i)
                    if prev == "function" {
                        out.append(Tok(range: NSRange(location: i, length: j - i), color: LuaTheme.funcName))
                    }
                }
                i = j
                continue
            }

            i += 1
        }
        return out
    }

    private static func longBracketEnd(_ s: NSString, open: Int) -> Int? {
        let n = s.length
        var k = open + 1
        var level = 0
        while k < n, s.character(at: k) == 0x3D { level += 1; k += 1 }
        guard k < n, s.character(at: k) == 0x5B else { return nil }
        k += 1
        while k < n {
            if s.character(at: k) == 0x5D {
                var m = k + 1, lv = 0
                while m < n, s.character(at: m) == 0x3D { lv += 1; m += 1 }
                if lv == level, m < n, s.character(at: m) == 0x5D { return m + 1 }
            }
            k += 1
        }
        return n
    }

    private static func precedingWord(_ s: NSString, before idx: Int) -> String {
        var k = idx - 1
        while k >= 0, s.character(at: k) == 0x20 || s.character(at: k) == 0x09 { k -= 1 }
        let end = k + 1
        while k >= 0 {
            let c = s.character(at: k)
            if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || (c >= 48 && c <= 57) { k -= 1 } else { break }
        }
        let start = k + 1
        guard start < end else { return "" }
        return s.substring(with: NSRange(location: start, length: end - start))
    }
}

// MARK: - Line-number gutter (plain NSView, not NSRulerView)

final class LineNumberGutter: NSView {
    static let width: CGFloat = 38
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(frame: NSRect(x: 0, y: 0, width: LineNumberGutter.width, height: 100))
    }
    required init?(coder: NSCoder) { fatalError() }

    // Flipped so y grows downward, matching the text view's visible geometry.
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        LuaTheme.background.setFill()
        bounds.fill()

        guard let textView,
              let layout = textView.layoutManager,
              let container = textView.textContainer else { return }

        let ns = textView.string as NSString
        let visible = textView.visibleRect
        let inset = textView.textContainerInset.height
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular),
            .foregroundColor: LuaTheme.gutter,
        ]

        var lineNo = 1
        var charIndex = 0
        let glyphRange = layout.glyphRange(forBoundingRect: visible, in: container)
        let firstChar = layout.characterIndexForGlyph(at: glyphRange.location)
        if firstChar > 0 {
            // Count newlines in place — substring(to:) would copy everything
            // above the viewport on every gutter redraw.
            for k in 0..<firstChar where ns.character(at: k) == 0x0A { lineNo += 1 }
        }
        charIndex = firstChar

        while charIndex <= ns.length {
            let lineRange = ns.lineRange(for: NSRange(location: min(charIndex, ns.length), length: 0))
            var glyphLine = layout.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            if glyphLine.length == 0 { glyphLine = NSRange(location: layout.numberOfGlyphs, length: 0) }
            let lineRect = layout.boundingRect(forGlyphRange: glyphLine, in: container)
            let y = lineRect.minY + inset - visible.minY
            if y > bounds.maxY { break }
            if y + lineRect.height >= bounds.minY {
                let label = "\(lineNo)" as NSString
                let size = label.size(withAttributes: attrs)
                label.draw(at: NSPoint(x: LineNumberGutter.width - size.width - 5, y: y + 1), withAttributes: attrs)
            }
            lineNo += 1
            if lineRange.location + lineRange.length <= charIndex { break }
            charIndex = lineRange.location + lineRange.length
            if charIndex >= ns.length, ns.length == 0 || ns.character(at: ns.length - 1) != 0x0A { break }
        }
    }
}
