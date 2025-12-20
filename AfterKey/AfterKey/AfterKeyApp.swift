import SwiftUI
import AppKit
import Combine

@main
struct afterkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var monitor = KeyMonitor()
    var statusBarItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Key Overlay")
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit AfterKey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quitItem)
        statusBarItem.menu = menu

        let screenFrame = NSScreen.main?.frame ?? .zero

        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        overlayWindow.level = .statusBar + 1
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.styleMask.insert(.nonactivatingPanel)

        let hostingView = NSHostingView(rootView: OverlayView().environmentObject(monitor))
        overlayWindow.contentView = hostingView
        overlayWindow.orderFront(nil)

        monitor.start()
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusItem) {
    }
}

struct OverlayView: View {
    @EnvironmentObject var monitor: KeyMonitor

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 12) {
                Spacer()

                VStack(spacing: 10) {
                    ForEach(monitor.recentKeys.reversed()) { row in
                        Text(row.text)
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(radius: 6)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

class KeyMonitor: ObservableObject {
    @Published var recentKeys: [KeyDisplay] = []

    struct KeyDisplay: Identifiable {
        let id = UUID()
        var text: String
        var expireDate: Date
    }

    private var timer: Timer?
    private var currentModifiers = ""

    func start() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) |
                   CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleEvent(type: type, cgEvent: event)
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        ) else {
            print("Нет прав на мониторинг ввода")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                let now = Date()
                withAnimation(.easeOut(duration: 0.4)) {
                    self.recentKeys.removeAll { $0.expireDate < now }
                }
                if self.recentKeys.count > 8 {
                    self.recentKeys.removeFirst(self.recentKeys.count - 8)
                }
            }
        }
    }

    private func handleEvent(type: CGEventType, cgEvent: CGEvent) {
        guard let nsEvent = NSEvent(cgEvent: cgEvent) else { return }

        DispatchQueue.main.async {
            let now = Date()

            let flags = nsEvent.modifierFlags
            var mods = ""
            if flags.contains(.command) { mods += "⌘" }
            if flags.contains(.shift) { mods += "⇧" }
            if flags.contains(.option) { mods += "⌥" }
            if flags.contains(.control) { mods += "⌃" }

            self.currentModifiers = mods

            if type == .keyDown {
                let keycode = Int(cgEvent.getIntegerValueField(.keyboardEventKeycode))

                var char = nsEvent.characters ?? ""

                switch keycode {
                case 49: char = "␣"
                case 36: char = "↵"
                case 51: char = "⌫"
                case 48: char = "Tab"
                case 53: char = "Esc"
                case 123: char = "←"
                case 124: char = "→"
                case 125: char = "↓"
                case 126: char = "↑"
                default:
                    break
                }

                let finalText = self.currentModifiers + char

                guard !finalText.isEmpty else { return }

                let display = KeyDisplay(text: finalText, expireDate: now.addingTimeInterval(3.0))
                withAnimation(.easeIn(duration: 0.2)) {
                    self.recentKeys.append(display)
                }
            }
        }
    }
}
