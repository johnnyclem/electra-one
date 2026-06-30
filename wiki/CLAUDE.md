# Electra One Developer Wiki — Schema & Conventions

This directory is an **LLM-maintained knowledge base** about the Electra One MIDI
controller's developer-facing APIs and file formats. It follows the "LLM Wiki"
pattern: the LLM reads raw sources, extracts and integrates knowledge into
interlinked markdown pages, and keeps everything current. The human curates
sources and asks questions; the LLM does the bookkeeping.

> **Scope.** This wiki is about the Electra One *platform* (SysEx API, file
> transfer, Lua scripting, JSON preset/device/performance formats). It is not
> documentation for this repository's own application code. Keep the two separate.

## The three layers

1. **Raw sources** — `../docs/*.pdf` (and any future articles, schemas, code).
   Immutable. Read from them, never edit them. The source of truth.
2. **The wiki** — this directory. LLM-owned markdown. Created, updated, and
   cross-referenced by the LLM.
3. **The schema** — this file. How the wiki is structured and the workflows to
   follow. Co-evolve it as conventions change.

## Directory layout

```
wiki/
  CLAUDE.md            this file — schema & conventions
  index.md             content catalog (every page, one-line summary), by category
  log.md               append-only chronological record of ingests/queries/lints
  sources/             one page per ingested raw source (a faithful summary)
  concepts/            cross-cutting topic pages (synthesized across sources)
  entities/            pages for concrete named things (hardware, firmware, ports…)
```

## Page conventions

- **Filenames**: kebab-case, `.md`. Stable — other pages link to them.
- **Frontmatter**: every wiki page starts with YAML frontmatter:
  ```yaml
  ---
  title: Human Readable Title
  type: source | concept | entity
  tags: [sysex, lua, preset, ...]
  sources: [api-sysex, api-lua-extension]   # source page slugs this draws from
  updated: 2026-06-30
  ---
  ```
- **Cross-links**: use Obsidian-style `[[page-slug]]` (no `.md`). Link liberally;
  a link to a not-yet-written page is a valid TODO marker, not an error.
- **Citations**: when a claim comes from a source, name it — e.g.
  "(see [[sources/api-sysex]])" or cite the PDF page. SysEx byte values are in
  hex (`0xNN`) matching the source notation.
- **Altitude**: source pages stay faithful to one document. Concept pages
  synthesize across documents and are where contradictions get flagged.

## Workflows

### Ingest (add a source)
1. Read the raw source (`pdftotext -layout` for PDFs → `/tmp/<name>.txt`, then
   Read the text). poppler is installed.
2. Write/refresh a `sources/<slug>.md` summary — faithful to that one document.
3. Update or create the `concepts/` and `entities/` pages the source touches.
   A single source can touch 10–15 pages; update cross-references both ways.
4. Note any contradiction with existing pages inline (`> ⚠️ Contradiction: …`).
5. Update `index.md` (add/adjust entries).
6. Append a `log.md` entry: `## [YYYY-MM-DD] ingest | <Source Title>`.

### Query (answer a question)
1. Read `index.md` to find relevant pages, then drill in.
2. Answer with citations to wiki pages / source pages.
3. **File good answers back** as a new `concepts/` page when they have lasting
   value (a comparison, a derived table, a discovered connection), then index +
   log it (`## [YYYY-MM-DD] query | <question>`).

### Lint (health-check)
Periodically scan for: contradictions between pages, stale claims newer sources
supersede, orphan pages (no inbound links), concepts mentioned but lacking a
page, missing cross-references, and data gaps worth a web search. Record findings
and fixes with `## [YYYY-MM-DD] lint | <summary>` in `log.md`.

## Domain quick-reference (load-bearing facts)

- Everything here requires **firmware 4.0+**. Manufacturer SysEx Id is
  `0x00 0x21 0x45`. See [[entities/firmware-4-0]], [[concepts/sysex-message-structure]].
- A preset lives in a **slot**; 6 banks × 12 slots = **72 slots**. A slot folder
  can hold `preset.json`, `main.lua`, `devices.json`, `data.json`,
  `performance.json`. See [[concepts/preset-slots-and-banks]].
- The web editor at app.electra.one is built entirely on the SysEx API.
