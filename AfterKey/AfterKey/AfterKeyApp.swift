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

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("displayDuration") var displayDuration: Double = 3.0
    @AppStorage("maxKeys") var maxKeys: Int = 5
    @AppStorage("overlayPosition") var position: OverlayPosition = .bottomRight
    @AppStorage("showModifiers") var showModifiers: Bool = true
    @AppStorage("fontSize") var fontSize: Double = 32.0
    @AppStorage("cornerRadius") var cornerRadius: Double = 12.0

    @AppStorage("backgroundColorRed") var backgroundColorRed: Double = 0.0
    @AppStorage("backgroundColorGreen") var backgroundColorGreen: Double = 0.0
    @AppStorage("backgroundColorBlue") var backgroundColorBlue: Double = 0.0
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.3
    @AppStorage("textColorRed") var textColorRed: Double = 1.0
    @AppStorage("textColorGreen") var textColorGreen: Double = 1.0
    @AppStorage("textColorBlue") var textColorBlue: Double = 1.0
    @AppStorage("textColorOpacity") var textColorOpacity: Double = 1.0
    @AppStorage("borderWidth") var borderWidth: Double = 1.0
    @AppStorage("borderColorRed") var borderColorRed: Double = 1.0
    @AppStorage("borderColorGreen") var borderColorGreen: Double = 1.0
    @AppStorage("borderColorBlue") var borderColorBlue: Double = 1.0
    @AppStorage("borderColorOpacity") var borderColorOpacity: Double = 0.2

    var backgroundColor: Color {
        Color(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue, opacity: backgroundOpacity)
    }

    var textColor: Color {
        Color(red: textColorRed, green: textColorGreen, blue: textColorBlue, opacity: textColorOpacity)
    }

    var borderColor: Color {
        Color(red: borderColorRed, green: borderColorGreen, blue: borderColorBlue, opacity: borderColorOpacity)
    }
}

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
        .defaultSize(width: 420, height: 700)
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Appearance").tag(1)
                Text("Position").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            TabView(selection: $selectedTab) {
                ScrollView {
                    VStack(spacing: 20) {
                        generalSettingsSection
                        actionsSection
                    }
                    .padding(20)
                }
                .tag(0)

                ScrollView {
                    VStack(spacing: 20) {
                        appearanceSettingsSection
                        actionsSection
                    }
                    .padding(20)
                }
                .tag(1)

                ScrollView {
                    VStack(spacing: 20) {
                        positionSettingsSection
                        actionsSection
                    }
                    .padding(20)
                }
                .tag(2)
            }
            .frame(height: 600)
        }
        .frame(width: 420, height: 700)
    }

    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General Settings")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                SettingRow(
                    title: "Display Duration",
                    value: "\(settings.displayDuration, default: "%.1f")s",
                    minValue: 0.5,
                    maxValue: 10,
                    step: 0.5,
                    binding: $settings.displayDuration
                )

                SettingRow(
                    title: "Max Items",
                    value: "\(settings.maxKeys)",
                    minValue: 1,
                    maxValue: 20,
                    step: 1,
                    binding: Binding(
                        get: { Double(settings.maxKeys) },
                        set: { settings.maxKeys = Int($0) }
                    )
                )

                VStack(spacing: 8) {
                    Toggle("Show Modifier Keys", isOn: $settings.showModifiers)
                        .toggleStyle(.switch)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.windowBackgroundColor))
            )
        }
    }

    private var appearanceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance Settings")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    SettingRow(
                        title: "Font Size",
                        value: "\(Int(settings.fontSize))",
                        minValue: 16,
                        maxValue: 64,
                        step: 2,
                        binding: $settings.fontSize
                    )

                    SettingRow(
                        title: "Corner Radius",
                        value: "\(Int(settings.cornerRadius))",
                        minValue: 0,
                        maxValue: 30,
                        step: 2,
                        binding: $settings.cornerRadius
                    )

                    SettingRow(
                        title: "Border Width",
                        value: "\(settings.borderWidth, default: "%.1f")",
                        minValue: 0,
                        maxValue: 5,
                        step: 0.5,
                        binding: $settings.borderWidth
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ColorPickerRow(
                        title: "Color",
                        color: Binding(
                            get: { Color(red: settings.backgroundColorRed, green: settings.backgroundColorGreen, blue: settings.backgroundColorBlue) },
                            set: { color in
                                if let components = color.cgColor?.components, components.count >= 3 {
                                    settings.backgroundColorRed = Double(components[0])
                                    settings.backgroundColorGreen = Double(components[1])
                                    settings.backgroundColorBlue = Double(components[2])
                                }
                            }
                        )
                    )

                    SettingRow(
                        title: "Opacity",
                        value: "\(settings.backgroundOpacity, default: "%.2f")",
                        minValue: 0,
                        maxValue: 1,
                        step: 0.05,
                        binding: $settings.backgroundOpacity
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ColorPickerRow(
                        title: "Color",
                        color: Binding(
                            get: { Color(red: settings.textColorRed, green: settings.textColorGreen, blue: settings.textColorBlue) },
                            set: { color in
                                if let components = color.cgColor?.components, components.count >= 3 {
                                    settings.textColorRed = Double(components[0])
                                    settings.textColorGreen = Double(components[1])
                                    settings.textColorBlue = Double(components[2])
                                }
                            }
                        )
                    )

                    SettingRow(
                        title: "Opacity",
                        value: "\(settings.textColorOpacity, default: "%.2f")",
                        minValue: 0,
                        maxValue: 1,
                        step: 0.05,
                        binding: $settings.textColorOpacity
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Border Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ColorPickerRow(
                        title: "Color",
                        color: Binding(
                            get: { Color(red: settings.borderColorRed, green: settings.borderColorGreen, blue: settings.borderColorBlue) },
                            set: { color in
                                if let components = color.cgColor?.components, components.count >= 3 {
                                    settings.borderColorRed = Double(components[0])
                                    settings.borderColorGreen = Double(components[1])
                                    settings.borderColorBlue = Double(components[2])
                                }
                            }
                        )
                    )

                    SettingRow(
                        title: "Opacity",
                        value: "\(settings.borderColorOpacity, default: "%.2f")",
                        minValue: 0,
                        maxValue: 1,
                        step: 0.05,
                        binding: $settings.borderColorOpacity
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.windowBackgroundColor))
            )
        }
    }

    private var positionSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overlay Position")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(OverlayPosition.allCases) { position in
                    PositionButton(
                        position: position,
                        isSelected: settings.position == position
                    ) {
                        settings.position = position
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.windowBackgroundColor))
            )
        }
    }


    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }) {
                HStack {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 14))
                    Text("Open Privacy Settings")
                        .font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button(action: {
                settings.displayDuration = 3.0
                settings.maxKeys = 5
                settings.position = .bottomRight
                settings.showModifiers = true
                settings.fontSize = 32.0
                settings.cornerRadius = 12.0

                settings.backgroundColorRed = 0.0
                settings.backgroundColorGreen = 0.0
                settings.backgroundColorBlue = 0.0
                settings.backgroundOpacity = 0.3

                settings.textColorRed = 1.0
                settings.textColorGreen = 1.0
                settings.textColorBlue = 1.0
                settings.textColorOpacity = 1.0

                settings.borderWidth = 1.0
                settings.borderColorRed = 1.0
                settings.borderColorGreen = 1.0
                settings.borderColorBlue = 1.0
                settings.borderColorOpacity = 0.2
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                    Text("Reset to Defaults")
                        .font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    let minValue: Double
    let maxValue: Double
    let step: Double
    @Binding var binding: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Text(value)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Slider(value: $binding, in: minValue...maxValue, step: step)
                .controlSize(.small)
        }
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            ColorPicker("", selection: $color)
                .labelsHidden()
        }
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
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .primary)
                Text(shortName(for: position))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func iconName(for position: OverlayPosition) -> String {
        switch position {
        case .topLeft: return "arrow.up.left.circle.fill"
        case .topCenter: return "arrow.up.circle.fill"
        case .topRight: return "arrow.up.right.circle.fill"
        case .centerLeft: return "arrow.left.circle.fill"
        case .center: return "circle.fill"
        case .centerRight: return "arrow.right.circle.fill"
        case .bottomLeft: return "arrow.down.left.circle.fill"
        case .bottomCenter: return "arrow.down.circle.fill"
        case .bottomRight: return "arrow.down.right.circle.fill"
        }
    }

    private func shortName(for position: OverlayPosition) -> String {
        switch position {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .centerLeft: return "Center Left"
        case .center: return "Center"
        case .centerRight: return "Center Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }
}

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
        settingsWindow?.close()

        let settingsView = SettingsView()
            .environmentObject(SettingsManager.shared)

        let hostingController = NSHostingController(rootView: settingsView)

        settingsWindow = NSWindow(contentViewController: hostingController)
        settingsWindow?.title = "AfterKey Settings"
        settingsWindow?.setContentSize(NSSize(width: 420, height: 700))
        settingsWindow?.styleMask = [.titled, .closable, .resizable]
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)

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

struct OverlayView: View {
    @EnvironmentObject var monitor: KeyMonitor
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ZStack {
            Color.clear

            VStack {
                if settings.position.alignment.vertical != .top { Spacer() }

                VStack(spacing: 8) {
                    ForEach(monitor.recentKeys) { row in
                        Text(row.text)
                            .font(.system(size: CGFloat(settings.fontSize), weight: .bold, design: .rounded))
                            .foregroundColor(settings.textColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                settings.backgroundColor
                                    .opacity(settings.backgroundOpacity)
                            )
                            .cornerRadius(CGFloat(settings.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(settings.cornerRadius))
                                    .stroke(settings.borderColor, lineWidth: CGFloat(settings.borderWidth))
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

class KeyMonitor: ObservableObject {
    @Published var recentKeys: [KeyDisplay] = []
    private let settings = SettingsManager.shared

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

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
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

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

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
