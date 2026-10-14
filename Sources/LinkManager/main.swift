import AppKit
import SwiftUI
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = LinkStore()
    private var statusItem: NSStatusItem!
    private var editorWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "link", accessibilityDescription: "Quick Links")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        installEditMenu()

        // Enable launch at login on first run; the menu toggle controls it afterwards.
        let key = "didSetDefaultLoginItem"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            try? SMAppService.mainApp.register()
        }
    }

    // Rebuilt every time the menu opens, so it always reflects the latest links and icons.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let links = store.links.filter { !$0.title.isEmpty || !$0.target.isEmpty }
        if links.isEmpty {
            let empty = NSMenuItem(title: "No links yet", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }
        for link in links {
            let item = NSMenuItem(title: link.title.isEmpty ? link.target : link.title,
                                  action: #selector(openLink(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = link.target
            item.image = IconProvider.icon(for: link.target)
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let edit = NSMenuItem(title: "Edit Links…", action: #selector(showEditor), keyEquivalent: ",")
        edit.target = self
        edit.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        menu.addItem(edit)

        menu.addItem(.separator())
        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        login.target = self
        // An icon instead of a checkmark keeps every row's icon in the same column.
        let enabled = SMAppService.mainApp.status == .enabled
        login.image = NSImage(systemSymbolName: enabled ? "checkmark.circle.fill" : "circle", accessibilityDescription: nil)
        menu.addItem(login)
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quit)
    }

    // Menu-bar-only apps have no main menu, so ⌘C/⌘V/⌘X/⌘A/⌘Z need an Edit menu to be routed.
    private func installEditMenu() {
        let mainMenu = NSMenu()
        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        NSApp.mainMenu = mainMenu
    }

    @objc private func openLink(_ sender: NSMenuItem) {
        if let target = sender.representedObject as? String { TargetResolver.open(target) }
    }

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            NSSound.beep()
        }
    }

    @objc private func showEditor() {
        if editorWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: EditorView(store: store)))
            window.title = "Edit Quick Links"
            window.styleMask = [.titled, .closable, .resizable]
            window.isReleasedWhenClosed = false
            window.center()
            editorWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        editorWindow?.makeKeyAndOrderFront(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
