---
name: brainstorm
description: Helps brainstorm ideas, projects, features. Use when the user wants to explore an idea, plan a project, or think through a problem.
---

# Brainstorm

Help the user brainstorm and structure their ideas through a guided, iterative process. All output in English.

## Phase 1: Clarify

Before generating anything, ask 3-5 clarifying questions to understand:

- **What**: What is the idea/project/feature? What problem does it solve?
- **Who**: Who is the target audience or end user?
- **Why**: What's the motivation? Why now?
- **Constraints**: Budget, timeline, team size, tech stack preferences?
- **Scope**: MVP vs full vision? What's in/out of scope?

Wait for answers before proceeding.

## Phase 2: Structured Output

Once you have enough context, produce:

### 1. One-Liner Summary
A single sentence capturing the essence of the idea.

### 2. Idea Breakdown
Bullet-point decomposition of the idea into its core components, features, or workstreams.

### 3. Architecture / Flow Diagram
An ASCII diagram showing the high-level architecture, user flow, or system design. Use boxes, arrows, and labels.

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│   API    │────▶│    DB    │
└──────────┘     └──────────┘     └──────────┘
```

### 4. Technical Considerations
- Recommended stack, tools, libraries, patterns
- Trade-offs and alternatives
- Integration points

### 5. Action Plan
Step-by-step plan to go from idea to execution. Number each step. Include milestones.

### 6. Open Questions & Risks
- Unknowns that need answers
- Potential risks and mitigations

## Phase 3: Iterate

After presenting the output:
- Ask 2-3 follow-up questions to refine
- Offer to dive deeper into any section
- Suggest adjacent ideas or improvements

## Style

- Use simple, clear language for overviews and summaries
- Use precise technical terms for implementation details
- Keep formatting clean with headers, bullets, and code blocks
- Be opinionated — suggest a direction, don't just list options
