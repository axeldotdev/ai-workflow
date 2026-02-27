---
name: compare
description: Compares two or more tools, packages, libraries, or approaches side by side. Use when the user wants to choose between options.
---

# Compare

Compare tools, packages, libraries, or approaches side by side to help the user make an informed decision. All output in English.

## Process

### 1. Gather Data
Use WebSearch to collect up-to-date information for each option:
- GitHub stars, latest version, release date
- npm/packagist/PyPI weekly downloads
- Benchmark results (if available)
- Pricing (if applicable)
- Known issues or limitations

### 2. Comparison Table

Output a markdown table covering relevant dimensions:

| Criteria | Option A | Option B | Option C |
|---|---|---|---|
| GitHub Stars | ... | ... | ... |
| Latest Version | ... | ... | ... |
| Bundle Size / Performance | ... | ... | ... |
| Learning Curve | ... | ... | ... |
| Documentation Quality | ... | ... | ... |
| Community & Ecosystem | ... | ... | ... |
| TypeScript Support | ... | ... | ... |
| Pricing | ... | ... | ... |
| Active Maintenance | ... | ... | ... |

Adapt columns to the specific comparison — not all rows apply to every comparison.

### 3. Pros & Cons

For each option, provide:

**Option A**
- Pros: bullet list
- Cons: bullet list

**Option B**
- Pros: bullet list
- Cons: bullet list

### 4. Deal-Breakers & Context

Flag any deal-breakers:
- License incompatibilities
- Missing critical features
- End-of-life / abandoned projects
- Security concerns

Note context-dependent factors:
- "If your team already uses X, then Y is easier to adopt"
- "For small projects, A is simpler; for large projects, B scales better"

### 5. Recommendation

Give a clear, opinionated recommendation:
- State which option you'd pick and why
- Acknowledge trade-offs
- Specify for whom or what context the recommendation applies

## Guidelines

- Be objective in data, opinionated in recommendations
- Always cite sources (links from WebSearch)
- If data is outdated or unavailable, say so
- Don't compare more than 4-5 options at once — suggest narrowing down if needed
