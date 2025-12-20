import SwiftUI
import AppKit
import Combine

// MARK: - Enums
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

// MARK: - App Main
@main
struct afterkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // Стандартное окно настроек SwiftUI
        Settings {
            SettingsView(monitor: delegate.monitor)
        }
    }
}

// MARK: - Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var monitor = KeyMonitor()
    var statusBarItem: NSStatusItem!

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
        // В macOS 13+ для настроек рекомендуется использовать SettingsLink в View,
        // но из меню мы вызываем стандартный селектор.
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AfterKey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem.menu = menu
    }
    
    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        // Правильный способ вызова окна настроек для новых macOS
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    func setupOverlayWindow() {
        let screenFrame = NSScreen.main?.frame ?? .zero

        // Исправлено: Убрали .nonactivatingPanel из styleMask, так как он вызывает ошибку 0x80
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
        
        // Устанавливаем панель как неактивируемую через свойство класса, если нужно
        // Но для overlay обычно достаточно уровня окна
        
        let hostingView = NSHostingView(rootView: OverlayView().environmentObject(monitor))
        overlayWindow.contentView = hostingView
        overlayWindow.orderFront(nil)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var monitor: KeyMonitor

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("Display Duration: \(monitor.displayDuration, specifier: "%.1f")s")
                    Slider(value: $monitor.displayDuration, in: 1...10, step: 0.5)
                }
                
                Stepper("Max Items: \(monitor.maxKeys)", value: $monitor.maxKeys, in: 1...15)
            } header: {
                Text("General Settings")
            }
            
            Divider()
            
            Section {
                Picker("Position", selection: $monitor.position) {
                    ForEach(OverlayPosition.allCases) { pos in
                        Text(pos.rawValue.capitalized).tag(pos)
                    }
                }
            } header: {
                Text("Layout")
            }
            
            // Кнопка для быстрого доступа к системным настройкам (Accessibility)
            Section {
                Button("Open Privacy Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

// MARK: - Overlay View
struct OverlayView: View {
    @EnvironmentObject var monitor: KeyMonitor

    var body: some View {
        ZStack {
            Color.clear

            VStack {
                if monitor.position.alignment.vertical != .top { Spacer() }
                
                VStack(spacing: 8) {
                    ForEach(monitor.recentKeys) { row in
                        Text(row.text)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial) // Красивое размытие фона
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: monitor.position.alignment.vertical == .top ? .top : .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(50)
                .frame(maxWidth: .infinity, alignment: monitor.position.alignment)

                if monitor.position.alignment.vertical != .bottom { Spacer() }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: monitor.recentKeys.count)
    }
}

// MARK: - Key Monitor
class KeyMonitor: ObservableObject {
    @Published var recentKeys: [KeyDisplay] = []
    
    @AppStorage("displayDuration") var displayDuration: Double = 3.0
    @AppStorage("maxKeys") var maxKeys: Int = 5
    @AppStorage("overlayPosition") var position: OverlayPosition = .bottomRight

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
            let flags = nsEvent.modifierFlags
            if flags.contains(.command) { mods += "⌘" }
            if flags.contains(.shift) { mods += "⇧" }
            if flags.contains(.option) { mods += "⌥" }
            if flags.contains(.control) { mods += "⌃" }

            if type == .keyDown {
                let keycode = Int(cgEvent.getIntegerValueField(.keyboardEventKeycode))
                var char = nsEvent.charactersIgnoringModifiers?.uppercased() ?? ""

                switch keycode {
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
                    let display = KeyDisplay(text: finalText, expireDate: Date().addingTimeInterval(self.displayDuration))
                    withAnimation(.spring()) {
                        self.recentKeys.append(display)
                        if self.recentKeys.count > self.maxKeys {
                            self.recentKeys.removeFirst()
                        }
                    }
                }
            }
        }
    }
}
