---
type: meta-contract
created: 2026-02-09
status: active
tags: [obsidian, convention, tagging, routing, meta]
---

# Tag & Heading Convention

> **Purpose:** A contract between the vault author, Claude, and the Obsidian toolchain (REST API, Dataview, CardBoard, patch operations).

---

## Principle 1: Headings Are Structure, Tags Are Metadata

Headings exist for **navigation and patch targeting**. They must be plain text.
Tags exist for **classification, routing, and queries**. They live in frontmatter or inline.

---

## Principle 2: Tag Taxonomy

### Priority Tags
| Tag | Meaning |
|-----|---------|
| `#priority/critical` | Must do — blocks progress if incomplete |
| `#priority/important` | Should do — meaningful but not blocking |
| `#priority/normal` | Standard work — do in order |
| `#priority/low` | Nice to have — do when time permits |
| `#priority/blocked` | Cannot proceed — dependency exists |

### Lifecycle / Status Tags (CardBoard Columns)
| Tag | CardBoard Column | Meaning |
|-----|-----------------|---------|
| `#status/inbox` | Inbox | Untriaged — just captured |
| `#status/backlog` | Backlog | Triaged, scoped, not yet started |
| `#status/active` | Active | In progress |
| `#status/build` | Build / Test | Being provisioned or tested |
| `#status/deploy` | Deploy | Moving through CD pipeline |
| `#status/monitoring` | Monitoring | Deployed and live |
| `#status/feedback` | Feedback | Alert or issue detected |
| `#status/parked` | (no column) | Acknowledged, not active |
| `#status/killed` | (no column) | Intentionally abandoned |

### Source Tags
| Tag | Meaning |
|-----|---------|
| `#source/manual` | Created by a developer directly |
| `#source/cloudreport` | Auto-generated from threshold breach |
| `#source/journal` | Extracted from a journal entry |
| `#source/review` | Created during code review or retro |
| `#source/dfw-feedback` | Methodology improvement identified |

### Routing Tags
| Tag | Destination | Trigger |
|-----|-------------|---------|
| `#route/journal` | `journal/` daily entry | Learning, reflection, decision |
| `#route/wishlist` | Project `_WISHLIST.md` | Future idea, not actionable now |
| `#route/handoff` | Project `handoffs/` folder | Session state capture |
| `#route/todo` | Project `_TODO.md` | Actionable task surfaced |
| `#route/global` | `meta/` | Applies beyond one project |

---

## CardBoard Integration Rules

- Tags must be on the **task line** itself: `- [ ] My task #status/backlog`
- Tasks must be **top-level** (not indented) to appear as cards
- Subtasks (indented under a top-level task) appear inside the card body
- Path filters on each board scope it to one project: `projects/{name}/`
- CSS snippet `cardboard-dfw-theme.css` provides column color coding

---

*This is a living contract. Amendments require `#constitution/amendment` tag and rationale.*
