# kb-lint skill

Use this skill when the user invokes `/kb-lint` or asks to "check the vault", "find problems", "health check", or "lint the knowledge base".

This skill performs automated health checks on the Obsidian vault and reports issues.

---

## What `/kb-lint` Does

Run all checks below in sequence. Report findings grouped by severity.

---

## Check 1: Orphan Notes

Find notes with no incoming backlinks (nothing links to them).

```bash
# Notes that are never referenced by [[wikilinks]] in other files
```

**How to check:**
1. Glob all `.md` files in the vault (excluding `_Templates/`, `.obsidian/`, `.claude/`)
2. For each file, grep all other files for `[[filename]]` references
3. Report files with zero references

**Output format:**
```
ORPHANS (N found):
- path/to/file.md — created YYYY-MM-DD, tags: [...]
```

---

## Check 2: Stale Notes

Notes that haven't been verified recently based on their `decay_rate`.

**Thresholds:**
- `decay_rate: fast` → stale after 90 days
- `decay_rate: medium` → stale after 180 days
- `decay_rate: slow` → stale after 365 days

**How to check:** Read frontmatter `last_verified` and `decay_rate` from each `.md` file. Compare with today's date.

**Output format:**
```
STALE NOTES (N found):
- path/to/file.md — last_verified: YYYY-MM-DD, N days overdue, decay_rate: fast
```

---

## Check 3: Missing Frontmatter

Notes missing required frontmatter fields.

**Required fields:** `created`, `last_verified`, `confidence_level`, `decay_rate`, `status`, `tags`

**Output format:**
```
MISSING FRONTMATTER (N found):
- path/to/file.md — missing: [decay_rate, status]
```

---

## Check 4: Low Confidence Notes

Notes with `confidence_level: low` or `confidence_level: unverified`.

**Output format:**
```
LOW CONFIDENCE (N found):
- path/to/file.md — confidence: unverified, status: current
```

---

## Check 5: Broken Wikilinks

`[[links]]` that point to notes that don't exist.

**How to check:**
1. For each `.md` file, extract all `[[...]]` patterns
2. Check if a file with that name exists anywhere in the vault
3. Report broken links with their source file

**Output format:**
```
BROKEN LINKS (N found):
- 08-MOCs/MOC - Object Detection.md → [[NonExistentModel]] (line 23)
```

---

## Check 6: Outdated SOTA

Model and benchmark notes where `sota_as_of` is older than 60 days.

**Output format:**
```
OUTDATED SOTA (N found):
- 05-Models/YOLOv8-L.md — sota_as_of: YYYY-MM-DD, N days old
```

---

## Check 7: Empty Sections

Notes with placeholder text like `TODO`, `TBD`, `[NEEDS VERIFICATION]`, or empty headers.

**Output format:**
```
NEEDS ATTENTION (N found):
- 03-Concepts/attention-mechanism.md — contains [NEEDS VERIFICATION] (line 15)
```

---

## Summary Report Format

Always end with a summary:

```
=== KB-LINT SUMMARY ===
Vault: local_knowlege_base/
Scanned: N notes
Date: YYYY-MM-DD

Issues found:
  🔴 Broken links:      N
  🟠 Stale notes:       N  
  🟡 Low confidence:    N
  🟡 Outdated SOTA:     N
  🟢 Orphans:           N
  🟢 Missing frontmatter: N
  🟢 Needs attention:   N

Total issues: N
Next lint recommended: YYYY-MM-DD (in 7 days)
```

---

## Auto-Fix Mode

If the user says `/kb-lint --fix` or "fix the issues automatically":
- Add missing frontmatter with conservative defaults (`confidence_level: unverified`, `decay_rate: medium`)
- Update `status: needs-review` for stale notes
- Do NOT auto-delete orphans — report them for human review
- Do NOT change confidence levels of existing notes
