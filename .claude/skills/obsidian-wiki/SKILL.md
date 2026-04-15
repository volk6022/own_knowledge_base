# obsidian-wiki skill

Use this skill when the user invokes `/wiki`, `/save`, `/autoresearch`, or any request to write, update, or compile content into the wiki/ directory of this vault.

---

## Commands

### `/wiki <topic>`
Create or update a wiki article on the given topic.

**Process:**
1. Check if an article already exists in `wiki/` — search with Glob `wiki/**/*.md` and Grep for the topic name
2. If `raw/` contains source material on this topic, read it first
3. Write a comprehensive, well-linked `.md` file to `wiki/` following the schema below
4. Add wikilinks to related concepts, models, papers that exist or should exist in the vault
5. Always fill in full YAML frontmatter

**Output path:** `wiki/<kebab-case-topic>.md`

---

### `/save <source>`
Process a source from `raw/` and compile it into `wiki/`.

**Process:**
1. Read the source file from `raw/`
2. Determine the type: paper, concept, model, benchmark, tutorial
3. Apply the appropriate template from `_Templates/`
4. Write the compiled article to the correct directory:
   - Paper → `02-Papers/`
   - Model → `05-Models/`
   - Concept → `03-Concepts/`
   - Benchmark → `06-Benchmarks/`
   - General wiki → `wiki/`
5. Add backlinks in relevant MOC files in `08-MOCs/`

---

### `/autoresearch <question>`
Research a topic and populate the wiki with findings.

**Process:**
1. Break the question into sub-topics
2. For each sub-topic, create or update a wiki article in `wiki/`
3. Cross-link articles with `[[wikilinks]]`
4. Create or update the relevant MOC in `08-MOCs/`
5. Set `confidence_level: medium` and add source references
6. End with a summary of what was created/updated

---

## Wiki Article Schema

Every wiki article MUST have this frontmatter:

```yaml
---
created: YYYY-MM-DD
source_date: YYYY-MM-DD
last_verified: YYYY-MM-DD
confidence_level: high | medium | low | unverified
decay_rate: fast | medium | slow | static
status: current | needs-review | outdated | archived
tags: [type/wiki, ...]
---
```

**decay_rate guide:**
- `fast` — benchmarks, SOTA results, API details, model comparisons (update every 3 months)
- `medium` — techniques, methods, library usage (update every 6 months)
- `slow` — mathematical concepts, theory (update every 12 months)
- `static` — historical facts, fundamental algorithms

---

## Linking Rules

1. **Always use `[[wikilinks]]`** for any concept, model, paper, or benchmark mentioned
2. Create stub entries for things that don't exist yet — just `[[Name]]` is enough
3. In MOC files, add a one-line comment after each link: `- [[Model]] — why it's here`
4. Add `aliases:` in frontmatter for alternative names

---

## Quality Rules

1. Never invent benchmark numbers — mark with `[NEEDS VERIFICATION]` if uncertain
2. For SOTA claims, always add `sota_as_of: YYYY-MM-DD`
3. If citing a paper, include arxiv ID or URL in frontmatter
4. Keep `wiki/` articles longer and more detailed than individual concept notes
5. Prefer linking to existing vault notes over writing duplicate content

---

## Index File

Maintain `wiki/INDEX.md` as a table of contents:

```markdown
# Wiki Index
## CV Tasks
- [[topic]] — one-line description
## Concepts
...
```

Update this file whenever new wiki articles are created.
