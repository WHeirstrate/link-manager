# Link Manager

A tiny macOS menu bar app for quick links. Click the 🔗 icon, pick a link, and it opens.
Links can be websites, apps, files, folders, or any URL scheme (`mailto:`, `slack://`, …).

- Lives in the menu bar only, with no Dock icon
- Websites show their **favicon**, apps and files show their normal macOS icon
- Edit links in a small window: add, remove, drag to reorder, paste with ⌘V
- Launches at login (toggle it from the menu)
- No accounts, no analytics, no dependencies. Links are stored in a local JSON file

<!-- Add a screenshot here: ![Link Manager menu](docs/screenshot.png) -->

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools (`xcode-select --install`) or a full Xcode install, for the Swift 5.9+ toolchain

## Install

```bash
git clone https://github.com/<your-username>/link-manager.git
cd link-manager
./build.sh
```

The script builds a release binary, wraps it in `LinkManager.app`, signs it ad hoc, copies it to
`~/Applications`, and launches it. Because you build it yourself, Gatekeeper won't complain.

To build without installing, run `./build.sh --no-install`. The app ends up in `build/`.

## Usage

| Action | How |
| --- | --- |
| Open a link | Click the menu bar icon, then the link |
| Add or edit links | Menu, then **Edit Links…** (⌘,) |
| Pick an app or file | **Choose…** next to a link in the editor |
| Toggle launch at login | Menu, then **Launch at Login** |

### What a target can be

| Target | Example |
| --- | --- |
| Web URL | `https://github.com`, or just `github.com` |
| App name | `Notes`, `Visual Studio Code` |
| Bundle identifier | `com.apple.Safari` |
| File or folder | `/Applications/Slack.app`, `~/Documents` |
| Any URL scheme | `mailto:hi@example.com`, `slack://open` |

App names are looked up in `/Applications`, `/System/Applications`, their `Utilities` subfolders
and `~/Applications`.

### Favicons

When you add a web link, the app downloads the page, reads its `<link rel="icon">` tags
(preferring `apple-touch-icon`, then PNG), and falls back to `/favicon.ico`. Icons are cached per host.
SVG-only favicons are skipped and show a globe instead.

## Where data lives

```
~/Library/Application Support/LinkManager/
├── links.json   # your links
└── icons/       # cached favicons
```

To reset the app, quit it and delete that folder.

## Uninstall

1. Turn off **Launch at Login** in the menu, then choose **Quit**.
2. Delete `~/Applications/LinkManager.app`.
3. Optionally delete `~/Library/Application Support/LinkManager`.

## Project layout

```
Sources/LinkManager/
├── main.swift            # app delegate, status item, menu, login item
├── Link.swift            # model and target resolution (URL / app / file)
├── LinkStore.swift       # persistence and favicon fetching
├── FaviconService.swift  # favicon scraping, caching and icon lookup
└── EditorView.swift      # SwiftUI editor window
build.sh                  # builds, bundles, signs and installs the .app
```

## Troubleshooting

- **Launch at Login does nothing**: macOS may need approval under System Settings → General →
  Login Items. The app also works best when run from `~/Applications` or `/Applications`.
- **No favicon**: some sites block scripted requests or only offer SVG icons. The globe
  fallback is used.
- **Nothing opens when clicking a link**: the target couldn't be resolved. Check the
  spelling of the app name, or use **Choose…** to pick it.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
