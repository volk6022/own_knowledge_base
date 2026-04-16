# obsidian-wiki skill

Use this skill when the user invokes `/wiki`, `/save`, `/autoresearch`, or any request to write, update, or compile content into the wiki/ directory of this vault.

---

## Commands

### `/wiki <topic>`
Create or update a wiki article on the given topic.

**Process:**
1. Check if an article already exists — search with Glob `wiki/**/*.md` and Grep for the topic name
2. Determine domain:
   - If topic clearly belongs to a domain (10+), use that domain's wiki subfolder
   - If source is in `raw/<domain_id>/`, use that domain
   - Default: ML domain (`wiki/` or `wiki/ml/`)
3. If `raw/` or `raw/<domain_id>/` contains source material on this topic, read it first
4. Write a comprehensive, well-linked `.md` file following the schema below
5. Add wikilinks to related concepts, models, papers that exist or should exist in the vault
6. Always fill in full YAML frontmatter (include `domain:` field for non-ML domains)

**Output path:**
- ML: `wiki/<kebab-case-topic>.md`
- Other domains: `wiki/<domain_id>/<kebab-case-topic>.md`

---

### `/save <source>`
Process a source from `raw/` and compile it into the vault.

**Process:**
1. Read the source file from `raw/` or `raw/<domain_id>/`
2. Determine domain from source path or content:
   - Source in `raw/<domain_id>/` → that domain
   - Source in `raw/` root → infer from content or ask user
3. Determine the type: paper, concept, model, benchmark, tutorial, resource
4. Apply the appropriate template:
   - ML (00-09): `_Templates/`
   - Other domain: `NN-Domain/_templates/` → fallback to `_Templates/`
5. Write the compiled article to the correct directory:
   - **ML domain:** Paper → `02-Papers/`, Model → `05-Models/`, Concept → `03-Concepts/`, Benchmark → `06-Benchmarks/`, General → `wiki/`
   - **Other domain:** Concept → `NN-Domain/Concepts/`, Resource → `NN-Domain/Resources/`, General → `wiki/<domain_id>/`
6. Add backlinks in relevant MOC files (`08-MOCs/` or domain MOC)

---

### `/autoresearch <question>`
Research a topic and populate the wiki with findings.

**Process:**
1. Break the question into sub-topics
2. Determine domain for the research
3. For each sub-topic, create or update a wiki article in `wiki/` or `wiki/<domain_id>/`
4. Cross-link articles with `[[wikilinks]]`
5. Create or update the relevant MOC in `08-MOCs/` or domain folder
6. Set `confidence_level: medium` and add source references
7. End with a summary of what was created/updated

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

Maintain `wiki/INDEX.md` as a table of contents, organized by domain:

```markdown
# Wiki Index
## ML / Computer Vision
### CV Tasks
- [[topic]] — one-line description
### Concepts
...

## Другие домены
### <Domain Name>
- [[topic]] — one-line description
```

Update the correct domain section whenever new wiki articles are created.
