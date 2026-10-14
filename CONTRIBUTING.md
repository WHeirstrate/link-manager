# Contributing

Thanks for your interest! This is a small project, so the process is light.

## Getting started

```bash
git clone https://github.com/<your-username>/link-manager.git
cd link-manager
swift build          # debug build
./build.sh           # release build, install to ~/Applications and launch
```

You need macOS 13+ and a Swift 5.9+ toolchain. There are no third-party dependencies.

## Guidelines

- Keep it small and native: AppKit and SwiftUI only, no external packages.
- Match the surrounding code style.
- Open an issue before starting on a big change.
- Test by hand: add a web link, an app, a file and a custom URL scheme, and check the menu, icons and editor.
- Make sure `./build.sh --no-install` succeeds before opening a pull request.

## Pull requests

1. Fork and create a branch from `main`.
2. Make your change, with a clear commit message.
3. Fill in the pull request template.

By contributing you agree your work is released under the [MIT license](LICENSE).
