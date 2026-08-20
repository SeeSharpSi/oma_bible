# bible_lookup

Quick CLI to look up verses from the Berean Standard Bible (`BSB.sqlite`) without editing the database.

The `bsb` Bash script queries `BSB.sqlite` (located at the project root, alongside the script) using `sqlite3` and prints matching verses to stdout as `chapter:verse text` (one verse per line) by default; use `-n` / `--no-reference` to print only the verse text without the `chapter:verse` prefix and `-j` / `--join` to join multiple verses onto a single line (no newlines).

## Requirements

- `bash` 4+ (for associative arrays)
- `sqlite3` installed and on `PATH`
- `BSB.sqlite` at the project root (`./BSB.sqlite` or next to `bsb`)

No dependencies are installed and the database is never modified (read-only queries).

## Installation

Clone the project and ensure the script is executable:

```bash
chmod +x bsb
./bsb John 1:1
```

Optionally add the project root to `PATH` or symlink `bsb` into `~/bin`.

## Usage

```
bsb [-n|--no-reference] [-j|--join] <book> <chapter[:verse][-chapter[:verse]]> [ <book> <chapter> ... ]
bsb John 1:1
bsb Proverbs 3:3-5
bsb Luke 2:3-5:12
bsb lk 1:9-10
bsb Gen 3
bsb Luke 3:1-2 John 5
bsb --no-reference John 1:1   # same query, no chapter:verse prefix
bsb -n John 1:9-10            # short form
bsb -j John 1:9-10            # join on one line
bsb -n -j John 1:9-10         # combinable: no ref + join
bsb --join --no-reference John 1:9-10
```

### Options

- `-n`, `--no-reference` (aliases: `--no-references`, `--no-refs`, `--no-verse-numbers`, `--only-text`, `--plain`) — omit the leading `chapter:verse` prefix and print only the verse text. The flag may appear before, between, or after references and applies to all output in that invocation (e.g., `bsb John 1:1 --no-reference`, `bsb -n John 1:1 Romans 8:28`).
- `-j`, `--join` (aliases: `--joined`, `--no-newline`, `--no-newlines`, `--no-nl`, `--single-line`, `--one-line`, `--inline`) — join multiple verses on one line with a space separator instead of newlines. Combinable with `-n` (e.g., `bsb -n -j John 1:9-10`, `bsb --no-reference --join John 1:9-10`, `bsb -nj John 1:9-10`). Single-verse output unchanged.
- `-h`, `--help` — show help and exit.

- Single verse: `bsb John 1:1`
- Verse range (same chapter): `bsb Proverbs 3:3-5`, `bsb John 1:9-10`
- Cross-chapter range: `bsb Luke 2:3-5:12` (chapter 2 verse 3 through chapter 5 verse 12)
- Whole chapter: `bsb Gen 3`, `bsb Ps 23`
- Chapter range: `bsb Gen 1-2`
- Comma/semicolon list (same chapter inheritance): `bsb John 3:16,18`, `bsb John 3:16-18,20`
- Multiple references (different books): `bsb Luke 3:1-2 John 5`
- Same-book multiple specs without repeating the book: `bsb John 3:16 3:17`

Book names are case-insensitive and periods are ignored (`Gen.`, `Jn.`, `1 Jn.` all work). Numbered books may be written with or without a space (`1John`, `1 John`, `1Jn`, `1 Jn`).

Numbered-book prefixes are normalized before lookup, so all of these are equivalent:

- `1`, `I`, `First`, `1st` -> `1`
- `2`, `II`, `Second`, `2nd` -> `2`
- `3`, `III`, `Third`, `3rd` -> `3`

Examples: `1 Samuel`, `I Samuel`, `First Samuel`, `1st Samuel`, `1Sam`, `1 Samuel` (also `1Sam 1:1`, `IJohn 3:16`, `FirstJohn 3:16`, `IIKings 2:1`, `2nd Kings 2:1` with or without space).

Missing spaces are repaired: `John1:1`, `Jn3:16`, `Gen1:1`, `lk1:9-10`, `1Jn3:16` all work.

## How It Works

- `bsb` locates `BSB.sqlite` relative to its own directory or `./BSB.sqlite`.
- Parses all arguments as a sequence of book + spec tokens, case-insensitively.
- For each reference builds a SQLite query ordered by `chapter, verse`:

  - single: `chapter = C AND verse = V`
  - range: `verse BETWEEN`
  - cross-chapter: `(chapter = C1 AND verse >= V1) OR (chapter > C1 AND chapter < C2) OR (chapter = C2 AND verse <= V2)`

- Outputs `chapter:verse text` per line by default, or just `text` per line when `-n` / `--no-reference` is used. When `-j` / `--join` is used, multiple verses are joined with a single space on one line (combinable with `-n`).

## Database

`verses` table: `pk INTEGER PRIMARY KEY, translation TEXT, book INTEGER (1-66), chapter INTEGER, verse INTEGER, text TEXT`. The script only performs `SELECT` queries.

## License

Data from the Berean Standard Bible (BSB). Script is MIT.

## Examples

The list below shows the variety of supported invocations. The full abbreviation table follows immediately after.

```bash
# single verse
bsb John 1:1
bsb john 1:1          # case-insensitive
bsb Jn 3:16           # short form
bsb "John 1:1"        # quoted

# without space between book and reference
bsb John1:1
bsb Jn3:16
bsb Gen1:1
bsb 1Jn3:16

# whole chapter
bsb Gen 3
bsb Ps 23
bsb Psalm 23

# verse range (same chapter)
bsb John 1:9-10
bsb Proverbs 3:3-5
bsb lk 1:9-10

# cross-chapter range
bsb Luke 2:3-5:12
bsb Gen 1:1-2:3

# chapter range
bsb Gen 1-2
bsb John 3-5

# comma / semicolon (same chapter inheritance)
bsb John 3:16,18
bsb John 3:16,18,20
bsb John 3:16-18,20
bsb John 3:16;17

# multiple references
bsb Luke 3:1-2 John 5
bsb John 3:16 Romans 8:28
bsb John 3:16 3:17              # same book, no repeat
bsb "John 3:16" "Romans 8:28"  # quoted multi

# numbered-book prefix variants (all equivalent)
bsb 1 Samuel 1:1
bsb 1Sam 1:1
bsb I Samuel 1:1
bsb First Samuel 1:1
bsb 1st Samuel 1:1
bsb 1 Sm 1:1        # NABRE short
bsb II Kings 2:1
bsb 2nd Kings 2:1
bsb Second Kings 2:1
bsb I Kings 1:1
bsb III John 1:1
bsb 3rd John 1:1
bsb Third John 1:1

# long names and alternatives
bsb Song 2:4
bsb Song of Solomon 2:4
bsb Song of Songs 2:4
bsb SOS 2:4
bsb Canticles 2:4
bsb Acts of the Apostles 1:1
bsb Lamentations of Jeremiah 1:1
bsb The Revelation 1:1

# with periods
bsb Gen. 1:1
bsb Jn. 3:16
bsb 1 Jn. 3:16

# without verse reference
bsb --no-reference John 1:1
bsb -n John 1:9-10
bsb --no-reference John 3:16,18
bsb -n Luke 3:1-2 John 5
bsb John 1:1 --no-reference   # flag may appear before, between, or after refs

# join (no newlines between verses) — combinable with -n
bsb -j John 1:9-10
bsb --join John 1:9-10
bsb --no-newline John 1:9-10  # alias
bsb -n -j John 1:9-10         # joined without reference
bsb -nj John 1:9-10           # short combined form
bsb --no-reference --join John 1:9-10
bsb -j Luke 3:1-2 John 5      # multiple books joined
bsb John 1:9-10 --join        # flag after refs also works
```

Output is `chapter:verse text` per line by default, or just `text` per line with `-n` / `--no-reference`; with `-j` / `--join` verses are joined on one line:

```
bsb John 1:9-10
1:9 The true Light who gives light to every man was coming into the world.
1:10 He was in the world, and though the world was made through Him, the world did not recognize Him.

bsb --no-reference John 1:9-10
The true Light who gives light to every man was coming into the world.
He was in the world, and though the world was made through Him, the world did not recognize Him.

bsb -n John 1:1
In the beginning was the Word, and the Word was with God, and the Word was God.

bsb -j John 1:9-10
1:9 The true Light who gives light to every man was coming into the world. 1:10 He was in the world, and though the world was made through Him, the world did not recognize Him.

bsb -n -j John 1:9-10
The true Light who gives light to every man was coming into the world. He was in the world, and though the world was made through Him, the world did not recognize Him.

bsb -nj John 1:9-10
The true Light who gives light to every man was coming into the world. He was in the world, and though the world was made through Him, the world did not recognize Him.
```

## Abbreviation Table

All forms below are matched case-insensitively and with or without periods (`Gen`, `GEN`, `Gen.`, `gen` all match). For numbered books, both spaced (`1 Sam`) and unspaced (`1Sam`) forms work, as do `I/II/III`, `First/Second/Third`, and `1st/2nd/3rd` normalized to `1/2/3`.

| # | Book | Abbreviations |
|---|------|---------------|
| 1 | Genesis | `Genesis`, `Gen`, `Ge`, `Gn` |
| 2 | Exodus | `Exodus`, `Exo`, `Exod`, `Ex` |
| 3 | Leviticus | `Leviticus`, `Lev`, `Le`, `Lv` |
| 4 | Numbers | `Numbers`, `Num`, `Nu`, `Nm`, `Nb` |
| 5 | Deuteronomy | `Deuteronomy`, `Deut`, `De`, `Dt`, `Deu`, `Du`, `Deuteronomium` |
| 6 | Joshua | `Joshua`, `Josh`, `Jos`, `Jsh` |
| 7 | Judges | `Judges`, `Judg`, `Jdg`, `Jg`, `Jgs`, `Jdgs` |
| 8 | Ruth | `Ruth`, `Ru`, `Rut`, `Rth`, `Rt` |
| 9 | 1 Samuel | `1 Samuel`, `1Samuel`, `1 Sam`, `1Sam`, `1 Sa`, `1Sa`, `1 Sm`, `1Sm`, `1 S`, `1S`, `1st Samuel`, `First Samuel` |
| 10 | 2 Samuel | `2 Samuel`, `2Samuel`, `2 Sam`, `2Sam`, `2 Sa`, `2Sa`, `2 Sm`, `2Sm`, `2 S`, `2S`, `2nd Samuel`, `Second Samuel` |
| 11 | 1 Kings | `1 Kings`, `1Kings`, `1 King`, `1King`, `1 Kgs`, `1Kgs`, `1 Ki`, `1Ki`, `1 Kin`, `1Kin`, `1 K`, `1K` |
| 12 | 2 Kings | `2 Kings`, `2Kings`, `2 King`, `2King`, `2 Kgs`, `2Kgs`, `2 Ki`, `2Ki`, `2 Kin`, `2Kin`, `2 K`, `2K` |
| 13 | 1 Chronicles | `1 Chronicles`, `1Chronicles`, `1 Chron`, `1Chron`, `1 Chr`, `1Chr`, `1 Ch`, `1Ch`, `1 Chro`, `1Chro` |
| 14 | 2 Chronicles | `2 Chronicles`, `2Chronicles`, `2 Chron`, `2Chron`, `2 Chr`, `2Chr`, `2 Ch`, `2Ch`, `2 Chro`, `2Chro` |
| 15 | Ezra | `Ezra`, `Ezr`, `Ez`, `Esr` |
| 16 | Nehemiah | `Nehemiah`, `Neh`, `Ne` |
| 17 | Esther | `Esther`, `Est`, `Es`, `Esth` |
| 18 | Job | `Job`, `Jb` |
| 19 | Psalms | `Psalms`, `Psalm`, `Ps`, `Psa`, `Psm`, `Pss`, `Pslm`, `Psalmus` |
| 20 | Proverbs | `Proverbs`, `Proverb`, `Prov`, `Pro`, `Pr`, `Prv` |
| 21 | Ecclesiastes | `Ecclesiastes`, `Ecc`, `Eccl`, `Ec`, `Eccles`, `Qoh`, `Qoheleth` |
| 22 | Song of Solomon | `Song of Solomon`, `Song of Songs`, `SongofSolomon`, `SongofSongs`, `Song`, `SOS`, `So`, `Sng`, `Cant`, `Canticles`, `Canticle`, `Canticle of Canticles`, `Ca`, `Sg` |
| 23 | Isaiah | `Isaiah`, `Isa`, `Is` |
| 24 | Jeremiah | `Jeremiah`, `Jer`, `Je`, `Jr` |
| 25 | Lamentations | `Lamentations`, `Lam`, `La`, `Lamentations of Jeremiah` |
| 26 | Ezekiel | `Ezekiel`, `Ezek`, `Eze`, `Ek`, `Ezk` |
| 27 | Daniel | `Daniel`, `Dan`, `Da`, `Dn` |
| 28 | Hosea | `Hosea`, `Hos`, `Ho`, `Osee` |
| 29 | Joel | `Joel`, `Jl`, `Jol`, `Joe`, `Jo` |
| 30 | Amos | `Amos`, `Am`, `Amo` |
| 31 | Obadiah | `Obadiah`, `Oba`, `Ob`, `Obad`, `Abdias` |
| 32 | Jonah | `Jonah`, `Jon`, `Jnh`, `Jonas` |
| 33 | Micah | `Micah`, `Mic`, `Mc`, `Mi` |
| 34 | Nahum | `Nahum`, `Nah`, `Na`, `Nam` |
| 35 | Habakkuk | `Habakkuk`, `Hab`, `Hb` |
| 36 | Zephaniah | `Zephaniah`, `Zeph`, `Zep`, `Zp`, `Sophonias` |
| 37 | Haggai | `Haggai`, `Hag`, `Hg`, `Aggaeus` |
| 38 | Zechariah | `Zechariah`, `Zech`, `Zec`, `Zc` |
| 39 | Malachi | `Malachi`, `Mal`, `Ml` |
| 40 | Matthew | `Matthew`, `Matt`, `Mt`, `Mat` |
| 41 | Mark | `Mark`, `Mk`, `Mrk`, `Mr`, `Mar` |
| 42 | Luke | `Luke`, `Lk`, `Lu`, `Luk` |
| 43 | John | `John`, `Jn`, `Joh`, `Jhn`, `Jo` |
| 44 | Acts | `Acts`, `Ac`, `Act`, `Acts of the Apostles` |
| 45 | Romans | `Romans`, `Rom`, `Ro`, `Rm` |
| 46 | 1 Corinthians | `1 Corinthians`, `1Corinthians`, `1 Cor`, `1Cor`, `1 Co`, `1Co`, `1 C`, `1C`, `1 Corinthian` |
| 47 | 2 Corinthians | `2 Corinthians`, `2Corinthians`, `2 Cor`, `2Cor`, `2 Co`, `2Co`, `2 C`, `2C` |
| 48 | Galatians | `Galatians`, `Gal`, `Ga` |
| 49 | Ephesians | `Ephesians`, `Eph`, `Ep`, `Ephes` |
| 50 | Philippians | `Philippians`, `Phil`, `Php`, `Pp`, `Philip` |
| 51 | Colossians | `Colossians`, `Col`, `Co`, `Colos` |
| 52 | 1 Thessalonians | `1 Thessalonians`, `1Thessalonians`, `1 Thess`, `1Thess`, `1 Thes`, `1Thes`, `1 Th`, `1Th`, `1 Ths`, `1Ths` |
| 53 | 2 Thessalonians | `2 Thessalonians`, `2Thessalonians`, `2 Thess`, `2Thess`, `2 Thes`, `2Thes`, `2 Th`, `2Th`, `2 Ths`, `2Ths` |
| 54 | 1 Timothy | `1 Timothy`, `1Timothy`, `1 Tim`, `1Tim`, `1 Ti`, `1Ti`, `1 Tm`, `1Tm` |
| 55 | 2 Timothy | `2 Timothy`, `2Timothy`, `2 Tim`, `2Tim`, `2 Ti`, `2Ti`, `2 Tm`, `2Tm` |
| 56 | Titus | `Titus`, `Tit`, `Ti`, `Tt` |
| 57 | Philemon | `Philemon`, `Philem`, `Phm`, `Pm`, `Phlm`, `Phi`, `Phile` |
| 58 | Hebrews | `Hebrews`, `Heb`, `He` |
| 59 | James | `James`, `Jam`, `Ja`, `Jas`, `Jm` |
| 60 | 1 Peter | `1 Peter`, `1Peter`, `1 Pet`, `1Pet`, `1 Pe`, `1Pe`, `1 Pt`, `1Pt`, `1 P`, `1P` |
| 61 | 2 Peter | `2 Peter`, `2Peter`, `2 Pet`, `2Pet`, `2 Pe`, `2Pe`, `2 Pt`, `2Pt`, `2 P`, `2P` |
| 62 | 1 John | `1 John`, `1John`, `1 Jn`, `1Jn`, `1 Jhn`, `1Jhn`, `1 Joh`, `1Joh`, `1 J`, `1J`, `1 Jo`, `1Jo` |
| 63 | 2 John | `2 John`, `2John`, `2 Jn`, `2Jn`, `2 Jhn`, `2Jhn`, `2 Joh`, `2Joh`, `2 J`, `2J`, `2 Jo`, `2Jo` |
| 64 | 3 John | `3 John`, `3John`, `3 Jn`, `3Jn`, `3 Jhn`, `3Jhn`, `3 Joh`, `3Joh`, `3 J`, `3J`, `3 Jo`, `3Jo` |
| 65 | Jude | `Jude`, `Jud`, `Jd` |
| 66 | Revelation | `Revelation`, `Revelations`, `Rev`, `Re`, `Revs`, `Apocalypse`, `Apoc`, `Rv`, `The Revelation` |

**Notes:**

- All numbered-book prefixes `I`, `II`, `III`, `First`, `Second`, `Third`, `1st`, `2nd`, `3rd` are normalized to digits and may be written with or without a space: `1John`, `I John`, `First John`, `1stJohn`, `1 John` all resolve to 1 John. Case and attached punctuation do not matter (`1JN`, `1 Jn.`, `1 jn`).
- For `Song of Solomon` all `Song`, `SOS`, `Song of Songs`, `Canticles`, `Sng`, `So`, `Cant`, `Canticle of Canticles` are accepted (3 tokens max).
- `Ez` is kept as `Ezra` (use `Ezk` or `Eze` for `Ezekiel` to avoid ambiguity).
- Maximum book token length is 4 (`Acts of the Apostles`, `Canticle of Canticles`).
