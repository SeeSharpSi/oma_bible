# Bible — BSB verse lookup for the Omarchy bar

A bar-widget plugin for [Omarchy](https://omarchy.org/). Click the book icon in
your top bar, type a verse reference, see the text. Powered by the
[Berean Standard Bible](https://berean.bible/).

![kind: bar-widget](https://img.shields.io/badge/kind-bar--widget-1c9c77)

## Features

- Click the bar icon to open the lookup panel (or use IPC — see below)
- Accepts book names and abbreviations: `John 3:16`, `Jn 3:16`, `1Jn 3:16`,
  `1st Sam 1:1`, `Gen 1:1-3`, `Ps 23`, `Luke 3:1-2 John 5:1`
- Smart verse numbers: single verse keeps `chapter:verse`, multiple verses in
  one chapter show verse only, and the first verse of each new chapter gets
  `chapter:verse` back
- Multiple references group under their own reference headers, separated by
  blank lines
- Open results in a dedicated reading overlay
- Copy button puts the reference header(s) + verses on the clipboard
- Whole chapters, chapter ranges, cross-chapter ranges, comma/semicolon lists

## Install

```bash
omarchy plugin add <this repo's git URL> --enable
```

Requires `sqlite3` on PATH (`omarchy pkg add sqlite` if missing).

The plugin ships with `BSB.sqlite` (~9 MB) and never modifies it — all queries
open the database read-only.

## Uninstall

```bash
omarchy plugin remove cassian.bible
```

## IPC

```bash
omarchy-shell cassian.bible open
omarchy-shell cassian.bible lookup "John 3:16"
omarchy-shell cassian.bible openResult
omarchy-shell cassian.bible close
```

## The `bsb` CLI

The plugin is driven by a standalone script, `bsb`, which also works on its
own:

```
bsb [-n|--no-reference] [-j|--join] [--grouped] <book> <chapter[:verse][-chapter[:verse]]> [ <book> <chapter> ... ]
```

Examples:

```bash
bsb John 1:1                     # single verse
bsb -n Proverbs 3:3-5            # verse range, no chapter:verse prefix
bsb Luke 2:3-5:12                # cross-chapter range
bsb Gen 3                        # whole chapter
bsb Gen 1-2                      # chapter range
bsb John 3:16,18                 # comma list (same chapter inheritance)
bsb Luke 3:1-2 John 5            # multiple books
bsb lk 1:9-10                    # abbreviations, case-insensitive
bsb 1st Samuel 1:1               # I/II/III, First/Second/Third, 1st/2nd/3rd
bsb --grouped "jn 3:1 ps 2:2"    # reference headers + smart verse numbers
```

### Options

- `-n`, `--no-reference` — omit the `chapter:verse` prefix, print verse text only
- `-j`, `--join` — join multiple verses on one line (combinable with `-n`)
- `--grouped` — emit a reference header per book group and use smart verse
  numbers (verse-only within a chapter, `chapter:verse` on the first verse of
  each later chapter)
- `-h`, `--help` — show help

Book names are case-insensitive, periods are ignored (`Gen.`, `Jn.`), numbered
books work with or without spaces (`1 John`, `1John`, `1Jn`, `I Jn`,
`First John`), and missing spaces are repaired (`John1:1`, `Gen1:1`).

## Plugin layout

```
manifest.json   Omarchy plugin manifest
Widget.qml      Bar widget + popup panel
bsb             Verse lookup script (bash + sqlite3)
BSB.sqlite      Berean Standard Bible text
```

## License

Code is MIT — see [LICENSE](LICENSE). The `BSB.sqlite` database contains the
Berean Standard Bible text, which is free to share with attribution; see the
license file for details.
