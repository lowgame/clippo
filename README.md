<div align="center">

# CLIPPO

### as minimal as possible clipboard history for macos bar

[![Download DMG](https://img.shields.io/badge/Download-clippo.dmg-black?style=for-the-badge&logo=apple)](https://github.com/lowgame/clippo/releases/latest)
[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-black?style=flat-square&logo=apple)](https://github.com/lowgame/clippo)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](LICENSE)
[![X (Twitter)](https://img.shields.io/badge/X-@hiimthelowgame-black?style=flat-square&logo=x)](https://x.com/hiimthelowgame)

<br/><br/>

<img src="assets/app_icon_1024.png" width="120" alt="CLIPPO Icon" />

<br/><br/>

*Strictly 3 colors. Zero icons. Zero clutter. Pure typographic geometry.*

</div>

---

## Design Principles

- **Less, but better** ([Dieter Rams](https://www.vitsoe.com/us/about/good-design)): Zero preview bloat, image databases, or 100 MB web runtimes. Only essential text memory.
- **Data-Ink Ratio** ([Edward Tufte](https://www.edwardtufte.com/books/)): Every pixel is state. Zero decorative cards, bloated thumbnails, or artificial borders.
- **Grid Discipline** ([Massimo Vignelli](https://archive.org/details/thevignellicanon)): Strict mathematical column layout. Strictly `#000000`, `#8E8E93`, `#FFFFFF`.
- **Zero Friction** ([Hick's Law](https://doi.org/10.1080/17470215208416600)): Instant 1..9 keyboard selection, two-click in-place `×` / `◎` purge, sub-millisecond launch.

---

## Features

- **Menu Bar Resident**: Summon instantly from the macOS status bar with a bespoke Bauhaus template glyph.
- **Instant 1..9 Selection**: Press any number `1..9` to immediately copy that item to your clipboard and dismiss the window.
- **Instant Search (`/`)**: Type directly into the minimal filter bar or hit `/` to filter through your history. Top matches dynamically re-index to `1..9`.
- **Two-Click Armored Purge (`◎`)**: Click `×` once to arm, twice to permanently purge a clip. Zero interrupting confirmation dialogs.
- **Privacy & Sensitive Data Filtering**: Automatically detects and ignores passwords, credentials, and transient tokens copied from password managers (1Password, Bitwarden, Apple Passwords, Keychain, etc.).
- **Theme Switching (`⌘D`)**: Effortlessly cycle between Dark, Light, and System appearances.
- **Local-First with iCloud Sync**: Instant local speed via `~/Library/Application Support/clippo/history.json` with seamless background iCloud Drive mirroring.
- **Featherweight**: Native Swift, SwiftUI, AppKit & CoreGraphics. Under 300 KB binary.

---

## Installation

### Direct Download
Download **[clippo.dmg](https://github.com/lowgame/clippo/releases/latest)**, drag **Clippo.app** to `/Applications`, and open.

*(If macOS displays an unnotarized app prompt on first launch, right-click `Clippo.app` and select **Open**).*

### Homebrew Tap
```bash
brew install lowgame/tap/clippo
```

### Build from Source
```bash
git clone https://github.com/lowgame/clippo.git && cd clippo && ./Scripts/create_dmg.sh
```

---

## Author & License

Created by **Ahmet Kamer** — [@hiimthelowgame](https://x.com/hiimthelowgame) on X · [@lowgame](https://github.com/lowgame) on GitHub.  
Released under the [MIT License](LICENSE).
