# add-domain skill

Use this skill when the user invokes `/add-domain <name>` or asks to "create a new domain", "add a knowledge domain", or "set up a new topic area".

This skill creates a new domain folder with minimal structure, templates, MOC, and updates all relevant navigation files.

---

## Command

### `/add-domain <name>`

Create a new knowledge domain in the vault.

**Example:** `/add-domain Cryptocurrencies`

---

## Process

### Step 1: Gather domain info

Ask the user (or infer from the name) for:
- **Domain name** (display name): e.g. `Cryptocurrencies`
- **domain_id** (kebab-case, short): e.g. `crypto`
- **Brief description**: e.g. "Blockchain, DeFi, tokenomics, protocols"
- **resource_type** (what "Resources" means in this domain): e.g. "Protocol / Platform"

If the user only provides the name, infer reasonable defaults:
- `domain_id` = lowercase kebab-case of name (e.g. `Cryptocurrencies` → `crypto`, `Game Development` → `gamedev`)
- `description` = generate a one-line description
- `resource_type` = "Resource"

### Step 2: Determine prefix number

Scan the vault root for existing `\d\d-*` directories using Glob `[0-9][0-9]-*/`.
Find the highest number and add 1. If the highest is `09`, the next is `10`.

### Step 3: Create domain folder structure

Create minimal structure inside `NN-<Name>/`:

```
NN-<Name>/
├── Concepts/          # empty, for atomic concept notes
├── Resources/         # empty, for domain-specific resources
└── _templates/        # domain-specific templates
```

### Step 4: Create `_domain.yaml`

Write `NN-<Name>/_domain.yaml`:

```yaml
domain_id: <domain_id>
domain_name: <Name>
created: <today's date YYYY-MM-DD>
prefix: "NN"
tag_namespace: <domain_id>
description: "<description>"
tag_axes:
  topic: []
  # user fills in domain-specific axes later
resource_type: "<resource_type>"
```

### Step 5: Create domain-specific templates

#### `NN-<Name>/_templates/Template - Concept.md`

```markdown
---
created: <% tp.date.now("YYYY-MM-DD") %>
last_verified: <% tp.date.now("YYYY-MM-DD") %>
confidence_level: medium
decay_rate: slow
status: current
domain: <domain_id>
tags: [type/concept, <domain_id>/topic/]
aliases: []
---

# <% tp.file.title %>

## Definition

> One-two sentences: what is this.

## How It Works

Explanation of the mechanism.

## Why It Matters

Why is this important in the context of <Name>?

## Variants / Extensions

- **Variant A** —
- **Variant B** —

## Examples

- [[]] — how it is used
- [[]] — how it is used

## Common Pitfalls

-
-

## Related Concepts

- [[]] —
- [[]] —

## References

- [[]] —
-

---
*Created: <% tp.date.now("YYYY-MM-DD") %>*
```

#### `NN-<Name>/_templates/Template - Resource.md`

```markdown
---
created: <% tp.date.now("YYYY-MM-DD") %>
source_date:
last_verified: <% tp.date.now("YYYY-MM-DD") %>
confidence_level: medium
decay_rate: fast
status: current
domain: <domain_id>
tags: [type/resource, <domain_id>/topic/]
resource_name: <% tp.file.title %>
resource_type: <resource_type>
website:
---

# <% tp.file.title %>

## Description

> Brief description: what is it and what makes it notable.

## Key Properties

| Property | Value |
|---|---|
| Type | |
| Status | |
| Website | |

## Evaluation / Comparison

| Metric | Value | Notes |
|---|---|---|
| | | |

## Limitations

-
-

## Links

- Website:
- Documentation:
- Source:

## Related

- [[]] —
- [[]] —

---
*Last verified: <% tp.date.now("YYYY-MM-DD") %> | Source: *
```

### Step 6: Create domain MOC

Write `NN-<Name>/MOC - <Name>.md`:

```markdown
---
created: <today YYYY-MM-DD>
last_verified: <today YYYY-MM-DD>
confidence_level: high
decay_rate: slow
status: current
domain: <domain_id>
tags: [type/moc, <domain_id>/topic/overview]
---

# MOC — <Name>

> Entry point for the <Name> knowledge domain.

---

## Key Topics

*(add links as the domain grows)*

## Resources

*(add [[resource]] links here)*

## Key Concepts

*(add [[concept]] links here)*

## Papers & References

*(add paper links if relevant)*

---

## Dataview: All <Name> notes

` ` `dataview
TABLE confidence_level, status, last_verified
FROM "<NN-Name>"
SORT file.mtime DESC
` ` `

## Dataview: Needs review

` ` `dataview
TABLE last_verified, decay_rate
FROM "<NN-Name>"
WHERE decay_rate = "fast" AND date(now) - date(last_verified) > dur(90 days)
SORT last_verified ASC
` ` `
```

**Note:** Replace ` ` ` with actual triple backticks (they are escaped here to avoid breaking the skill file).

### Step 7: Create raw/ and wiki/ subfolders

- Create `raw/<domain_id>/` directory
- Create `wiki/<domain_id>/` directory

### Step 8: Update MOC - Home.md

In `08-MOCs/MOC - Home.md`, find the section `## Другие домены` and **replace** `*(пусто)*` (if present) or **append** a new line:

```markdown
- [[MOC - <Name>]] — <description>
```

### Step 9: Update CLAUDE.md domains registry

In `CLAUDE.md`, find the domains registry table (`### Реестр доменов`) and append a new row:

```markdown
| NN        | <Name> | <domain_id> | <description> |
```

### Step 10: Update wiki/INDEX.md

In `wiki/INDEX.md`, find `## Другие домены` and **replace** `*(пусто)*` (if present) or **append**:

```markdown
### <Name>

*(пусто — добавляй статьи через `/wiki <тема>`)*
```

### Step 11: Report summary

Print a summary of everything created:

```
=== DOMAIN CREATED ===
Domain: <Name> (<domain_id>)
Prefix: NN
Folder: NN-<Name>/

Created:
  - NN-<Name>/Concepts/
  - NN-<Name>/Resources/
  - NN-<Name>/_templates/Template - Concept.md
  - NN-<Name>/_templates/Template - Resource.md
  - NN-<Name>/_domain.yaml
  - NN-<Name>/MOC - <Name>.md
  - raw/<domain_id>/
  - wiki/<domain_id>/

Updated:
  - 08-MOCs/MOC - Home.md (added domain link)
  - CLAUDE.md (added to domains registry)
  - wiki/INDEX.md (added domain section)

Next steps:
  1. Edit _domain.yaml to add tag_axes for your domain
  2. Start adding content: /wiki <topic> or /save <source>
  3. Add more subfolders as needed (Papers/, Projects/, Benchmarks/, etc.)
```
