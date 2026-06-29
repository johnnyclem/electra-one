import ElectraKit
import Foundation

@main
struct Probe {
    static func main() async {
        let device = E1Device()
        do {
            let ports = try await device.connect()
            print("Connected → in: \(ports.input) | out: \(ports.output)")

            let info = try await device.getInfo()
            print("Device   → \(info.modelUpper)  fw \(info.versionText ?? "?")  serial \(info.serial ?? "?")")

            print("Scanning bank 0 …")
            for slot in 0..<6 {
                let s = await device.scanSlot(bank: 0, slot: slot)
                let detail = s.name ?? s.error ?? "—"
                print(String(format: "  [%02d] %-7@ %@", slot, s.status.rawValue as NSString, detail))
            }

            // Round-trip a read of slot 1 to prove large fragmented reads work.
            if let summary = try? await device.summarize(bank: 0, slot: 1) {
                print("Slot 1   → \"\(summary.name)\"  controls: \(summary.controls)  pages: \(summary.pages)")
            }

            await device.disconnect()
            print("✓ probe completed")
        } catch {
            print("ERROR: \(error)")
            await device.disconnect()
            exit(1)
        }
    }
}
