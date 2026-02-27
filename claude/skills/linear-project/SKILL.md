---
name: linear-project-prd
description: Write PRDs for Linear projects with goals, technical constraints, acceptance criteria. Optimized for CarJudge workflow.
---

Write PRDs for Linear projects that are clear, actionable, and ready for issue breakdown.

## Structure

### Context

2-3 sentences explaining WHY this project exists. What problem are we solving?

### Goals

Numbered list of concrete outcomes. Keep to 3-5 goals max.

### Technical Constraints

Bullet points covering:

- Existing architecture to preserve
- Tech stack specifics (versions, libraries)
- Data sources and their locations
- Integration points

### File Locations

List the key files/folders that will be touched:

- `path/to/file.php` — what it does
- `path/to/folder/` — what lives there

### Requirements

Detailed breakdown by feature area. Use tables for structured data (widgets, endpoints, fields). Include:

- Field names, types, constraints
- Data sources and calculations
- UI components and their behavior

### Acceptance Criteria

Checkboxes. One per verifiable outcome. These become the project's definition of done.

- [ ] Specific, testable statement
- [ ] Another specific outcome

### Out of Scope

Explicit list of what this project does NOT include. Prevents scope creep and sets clear boundaries.

## Rules

1. **Be specific** — "Track costs" is bad. "Store cost in EUR as decimal(10,6) in api_request_logs table" is good.
2. **Reference real paths** — Use actual file paths from the codebase, not placeholders.
3. **Include data shapes** — Tables, JSON structures, database columns.
4. **No implementation details** — Describe WHAT, not HOW. Issues handle the how.
5. **Link dependencies** — If this depends on other projects/systems, mention them in constraints.

## Length

- Context: 2-3 sentences
- Goals: 3-5 items
- Requirements: As detailed as needed, prefer tables for structured info
- Total: 300-600 words typical
