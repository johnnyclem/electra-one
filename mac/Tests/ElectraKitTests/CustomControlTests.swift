import Testing
import Foundation
import AppKit
@testable import ElectraKit
@testable import LuaKit

/// End-to-end: adding a Custom control and rendering its seeded paint callback
/// yields draw ops — and we rasterize a couple to PNGs so the pipeline can be
/// eyeballed (written to $TMPDIR).
@Suite struct CustomControlTests {
    let lua = LuaEngine()

    @Test func addingCustomControlProducesDrawableScript() {
        var doc = PresetDocument.newPreset()
        let id = doc.addControl(kind: .custom, pageId: 1)
        #expect(doc.control(id: id)?.isCustom == true)

        let src = PresetDocument.customPaintStarter(controlId: id, colorHex: "F20530")
        let r = lua.paint(src, controlId: id, width: 200, height: 90, fraction: 0.7)
        #expect(r.ok, "paint errored: \(r.error ?? "?")")
        // background fill + value bar + label
        #expect(r.ops.contains { $0.op == "fillRect" })
        #expect(r.ops.contains { $0.op == "text" })
    }

    @Test func rasterizeStarterAndVUMeterToPNG() {
        // 1) the seeded starter bar
        let starter = PresetDocument.customPaintStarter(controlId: 1, colorHex: "F57000")
        write(lua.paint(starter, controlId: 1, width: 220, height: 90, fraction: 0.66),
              to: "custom_starter.png", w: 220, h: 90)

        // 2) a richer hand-written paint script (ADSR-style envelope)
        let adsr = """
        controls.get(1):setPaintCallback(function(o)
          local b = o:getBounds()
          local w, h = b[WIDTH], b[HEIGHT]
          graphics.setColor(0x101018)
          graphics.fillRect(0, 0, w, h)
          local ax, dx, sy, sx = w*0.18, w*0.34, h*0.45, w*0.62
          graphics.setColor(GREEN)
          graphics.drawLine(0, h, ax, 4)
          graphics.drawLine(ax, 4, dx, sy)
          graphics.drawLine(dx, sy, sx, sy)
          graphics.drawLine(sx, sy, w, h)
          graphics.setColor(WHITE)
          graphics.print(0, 2, "ADSR", w, LEFT)
        end)
        """
        write(lua.paint(adsr, controlId: 1, width: 220, height: 90, fraction: 0.5),
              to: "custom_adsr.png", w: 220, h: 90)
    }

    /// Rasterize draw ops with the same op semantics the app's Canvas uses.
    private func write(_ r: LuaEngine.PaintResult, to name: String, w: Int, h: Int) {
        let img = NSImage(size: NSSize(width: w, height: h))
        img.lockFocus()
        let ctx = NSGraphicsContext.current!.cgContext
        // flip to top-left origin (Electra coords)
        ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
        NSColor.black.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        for op in r.ops {
            let color = NSColor(srgbRed: CGFloat((op.color >> 16) & 0xff)/255,
                                green: CGFloat((op.color >> 8) & 0xff)/255,
                                blue: CGFloat(op.color & 0xff)/255, alpha: 1)
            color.setFill(); color.setStroke(); ctx.setLineWidth(1.5)
            switch op.op {
            case "fillRect": ctx.fill(CGRect(x: op.x, y: op.y, width: op.a, height: op.b))
            case "rect":     ctx.stroke(CGRect(x: op.x, y: op.y, width: op.a, height: op.b))
            case "line":
                ctx.move(to: CGPoint(x: op.x, y: op.y)); ctx.addLine(to: CGPoint(x: op.a, y: op.b)); ctx.strokePath()
            case "fillCircle": ctx.fillEllipse(in: CGRect(x: op.x-op.a, y: op.y-op.a, width: op.a*2, height: op.a*2))
            case "text":
                let s = op.text as NSString
                ctx.saveGState(); ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
                let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: NSFont.systemFont(ofSize: 11)]
                s.draw(at: NSPoint(x: op.x, y: CGFloat(h) - op.y - 12), withAttributes: attrs)
                ctx.restoreGState()
            default: break
            }
        }
        img.unlockFocus()
        if let tiff = img.tiffRepresentation, let bm = NSBitmapImageRep(data: tiff),
           let png = bm.representation(using: .png, properties: [:]) {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
            try? png.write(to: url)
            print("wrote \(url.path)")
        }
    }
}
