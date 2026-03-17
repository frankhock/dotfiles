---
name: workflow:research
description: "Research and document codebase comprehensively using parallel agents"
argument-hint: "[project-folder or research question]"
model: opus
disable-model-invocation: true
---

# Research Codebase

## Artifacts
- **Reads**: `spec.md` (recommended)
- **Produces**: `research.md`

Spawn parallel sub-agents to research the codebase, then synthesize their findings into `research.md`.

Your job is to **document what exists** — not to evaluate, critique, or suggest improvements. Describe where things are, how they work, and how they connect. When you find competing patterns or multiple approaches to the same problem, surface all of them as facts without picking a winner. `workflow:design` is where pattern decisions get made with human input.

## Initial Setup

1. **Check for project folder argument**
   - If argument provided (e.g., `/workflow:research 2025-01-27-ENG-1234-feature-name`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - If exists, read existing `research.md` for context
     - Read `spec.md` if it exists
     - Inform user: "Continuing research for project [folder-name]. Previous research loaded."
   - If no argument, proceed to step 2

2. **If no argument provided**: Ask the user what they'd like to research.

## Research Steps

1. **Read any directly mentioned files first** — read them fully in the main context before spawning sub-agents. You need this context to decompose well.

2. **Decompose the research question** into parallel sub-tasks. Track them with TodoWrite.

3. **Classify research depth and announce it:**

   Security, payments, cryptography, external API integrations, and compliance topics should automatically include web research for current best practices and advisories. Standard feature work only needs codebase research. Announce your classification so the user can override ("go deeper" or "that's enough").

   ```
   Research depth: [High/Standard/Low]
   Reason: [one sentence]
   [Proceeding with/Skipping] external research.
   ```

4. **Spawn parallel sub-agents:**

   **Codebase agents:**
   - **codebase-locator**: find WHERE files and components live
   - **codebase-analyzer**: understand HOW specific code works
   - **codebase-pattern-finder**: find existing patterns and usage examples

   **Web research** (for high-risk topics or when user asks):
   - Spawn **web-search-researcher** agents for best practices, docs, advisories
   - Instruct them to return source URLs — include these in `research.md` under "## External Sources"

   Start with locators to map what exists, then analyzers on the most relevant findings. Tell them what to find, not how to search.

5. **Wait for all sub-agents, then synthesize:**
   - Connect findings across components — highlight how things interact
   - Include specific file paths and line numbers

6. **Save to project folder:**

   Ask the user (via AskUserQuestion) whether to save to an existing project folder, create a new one (`~/brain/dev/projects/YYYY-MM-DD-TICKET-description/`), or skip. Write `research.md` using this format:

   ```markdown
   # Research: [Topic]

   **Project:** [folder-name]
   **Conducted:** YYYY-MM-DD

   ## Summary
   ## Detailed Findings
   ## Code References
   ## Competing Patterns
   [When multiple approaches exist for the same concern, document each:
   where it's used, how it differs, and any observable tradeoffs — without recommending one]
   ## External Sources
   [Only if web research was performed]
   ## Next Steps
   - [ ] Create design: `/workflow:design [folder-name]`
   ```

7. **Next steps** (via AskUserQuestion):
   - Proceed to design: `/workflow:design [folder-name]`
   - Research more — spawn new sub-agents building on previous findings
   - Done for now

## Important
- Always run fresh codebase research — never rely solely on existing documents
