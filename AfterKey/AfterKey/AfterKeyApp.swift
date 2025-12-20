import SwiftUI
import AppKit
import Combine

enum OverlayPosition: String, CaseIterable, Identifiable {
    case topLeft, topCenter, topRight
    case centerLeft, center, centerRight
    case bottomLeft, bottomCenter, bottomRight

    var id: String { self.rawValue }

    var alignment: Alignment {
        switch self {
        case .topLeft: return .topLeading
        case .topCenter: return .top
        case .topRight: return .topTrailing
        case .centerLeft: return .leading
        case .center: return .center
        case .centerRight: return .trailing
        case .bottomLeft: return .bottomLeading
        case .bottomCenter: return .bottom
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("displayDuration") var displayDuration: Double = 3.0
    @AppStorage("maxKeys") var maxKeys: Int = 5
    @AppStorage("overlayPosition") var position: OverlayPosition = .bottomRight
    @AppStorage("showModifiers") var showModifiers: Bool = true
    @AppStorage("fontSize") var fontSize: Double = 32.0
    @AppStorage("cornerRadius") var cornerRadius: Double = 12.0
}

// MARK: - App Main
@main
struct afterkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var settings = SettingsManager.shared

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 500)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Display Duration: \(settings.displayDuration, specifier: "%.1f")s")
                    Slider(value: $settings.displayDuration, in: 0.5...10, step: 0.5)
                }
                .padding(.vertical, 4)

                Stepper("Max Items: \(settings.maxKeys)", value: $settings.maxKeys, in: 1...20)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Font Size: \(Int(settings.fontSize))")
                    Slider(value: $settings.fontSize, in: 16...64, step: 2)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Corner Radius: \(Int(settings.cornerRadius))")
                    Slider(value: $settings.cornerRadius, in: 0...30, step: 2)
                }
                .padding(.vertical, 4)

                Toggle("Show Modifier Keys", isOn: $settings.showModifiers)
                    .padding(.vertical, 4)
            } header: {
                Text("General Settings")
                    .font(.headline)
            }

            Divider()
                .padding(.vertical, 8)

            Section {
                Text("Overlay Position")
                    .font(.headline)
                    .padding(.bottom, 8)

                // Grid of positions
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(OverlayPosition.allCases) { position in
                        PositionButton(
                            position: position,
                            isSelected: settings.position == position
                        ) {
                            settings.position = position
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()
                .padding(.vertical, 8)

            Section {
                Button("Open Privacy Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }

                Button("Reset to Defaults") {
                    settings.displayDuration = 3.0
                    settings.maxKeys = 5
                    settings.position = .bottomRight
                    settings.showModifiers = true
                    settings.fontSize = 32.0
                    settings.cornerRadius = 12.0
                }
                .foregroundColor(.red)
            }
        }
        .padding(20)
        .frame(width: 400, height: 500)
    }
}

struct PositionButton: View {
    let position: OverlayPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName(for: position))
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
                Text(position.rawValue
                    .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                    .capitalized)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func iconName(for position: OverlayPosition) -> String {
        switch position {
        case .topLeft: return "arrow.up.left.circle"
        case .topCenter: return "arrow.up.circle"
        case .topRight: return "arrow.up.right.circle"
        case .centerLeft: return "arrow.left.circle"
        case .center: return "circle"
        case .centerRight: return "arrow.right.circle"
        case .bottomLeft: return "arrow.down.left.circle"
        case .bottomCenter: return "arrow.down.circle"
        case .bottomRight: return "arrow.down.right.circle"
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var monitor = KeyMonitor()
    var statusBarItem: NSStatusItem!
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupOverlayWindow()
        monitor.start()
    }

    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Key Overlay")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AfterKey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem.menu = menu
    }

    @objc func openSettings() {
        // Close existing settings window if open
        settingsWindow?.close()

        // Create new settings window
        let settingsView = SettingsView()
            .environmentObject(SettingsManager.shared)
            .frame(width: 400, height: 500)

        let hostingController = NSHostingController(rootView: settingsView)

        settingsWindow = NSWindow(contentViewController: hostingController)
        settingsWindow?.title = "AfterKey Settings"
        settingsWindow?.setContentSize(NSSize(width: 400, height: 500))
        settingsWindow?.styleMask = [.titled, .closable, .resizable]
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)

        // Bring to front
        NSApp.activate(ignoringOtherApps: true)
    }

    func setupOverlayWindow() {
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

        let hostingView = NSHostingView(rootView: OverlayView().environmentObject(monitor))
        overlayWindow.contentView = hostingView
        overlayWindow.orderFront(nil)
    }
}

// MARK: - Overlay View
struct OverlayView: View {
    @EnvironmentObject var monitor: KeyMonitor
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ZStack {
            Color.clear

            VStack {ываыв
                if settings.position.alignment.vertical != .top { Spacer() }

                VStack(spacing: 8) {
                    ForEach(monitor.recentKeys) { row in
                        Text(row.text)
                            .font(.system(size: CGFloat(settings.fontSize), weight: .bold, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(CGFloat(settings.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(settings.cornerRadius))
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: settings.position.alignment.vertical == .top ? .top : .bottom)
                                    .combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(50)
                .frame(maxWidth: .infinity, alignment: settings.position.alignment)

                if settings.position.alignment.vertical != .bottom { Spacer() }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: monitor.recentKeys.count)
    }
}

// MARK: - Key Monitor
class KeyMonitor: ObservableObject {
    @Published var recentKeys: [KeyDisplay] = []
    @StateObject private var settings = SettingsManager.shared

    struct KeyDisplay: Identifiable {
        let id = UUID()
        var text: String
        var expireDate: Date
    }

    private var timer: Timer?

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
            print("ERROR: Accessibility permissions missing")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                let now = Date()
                withAnimation {
                    self.recentKeys.removeAll { $0.expireDate < now }
                }
            }
        }
    }

    private func handleEvent(type: CGEventType, cgEvent: CGEvent) {
        guard let nsEvent = NSEvent(cgEvent: cgEvent) else { return }

        DispatchQueue.main.async {
            var mods = ""
            if self.settings.showModifiers {
                let flags = nsEvent.modifierFlags
                if flags.contains(.command) { mods += "⌘" }
                if flags.contains(.shift) { mods += "⇧" }
                if flags.contains(.option) { mods += "⌥" }
                if flags.contains(.control) { mods += "⌃" }
            }

            if type == .keyDown {
                let keycode = Int(cgEvent.getIntegerValueField(.keyboardEventKeycode))
                var char = nsEvent.charactersIgnoringModifiers?.uppercased() ?? ""

                switch keycode {
                case 48:  char = "⇥"
                case 49: char = "␣"
                case 36: char = "↵"
                case 51: char = "⌫"
                case 53: char = "ESC"
                case 123: char = "←"
                case 124: char = "→"
                case 125: char = "↓"
                case 126: char = "↑"
                default: break
                }

                let finalText = mods + char
                if !finalText.isEmpty {
                    let display = KeyDisplay(
                        text: finalText,
                        expireDate: Date().addingTimeInterval(self.settings.displayDuration)
                    )
                    withAnimation(.spring()) {
                        self.recentKeys.append(display)
                        if self.recentKeys.count > self.settings.maxKeys {
                            self.recentKeys.removeFirst()
                        }
                    }
                }
            }
        }
    }
}
