# Writing Effective ralph-prompt.md Files

The ralph-prompt is the shared context every Claude instance receives alongside its task JSON. Your job is to give each instance everything it needs to complete its task autonomously — but nothing more.

## What the Instance Already Knows

ralph-loop automatically prepends each instance's task as:
```
# YOUR ASSIGNED TASK
```json
{ "id": "T-001", "title": "...", "description": "...", "acceptanceCriteria": [...] }
```
```

So the instance already has its specific assignment. The prompt provides the shared context that makes the assignment actionable.

## What Makes a Good Prompt

Study the examples in `references/examples/` — they show two different styles that both work well because they're tailored to their project.

### Core Sections Every Prompt Needs

1. **Scope constraint** — The most important section. Claude instances will drift without firm boundaries. Tell them exactly what their job is and what's out of scope. Be direct and specific to the project.

2. **Project context** — Just enough to orient. A few sentences, not paragraphs. What is this codebase, what are we changing, why.

3. **The change pattern** — What "making changes" means for this project. This is where prompts diverge most:
   - For mechanical transformations: show before/after examples, list edge cases and skip conditions
   - For feature work: describe the architecture, patterns to follow, conventions to match
   - For refactoring: explain what to change and what to preserve

4. **Verification** — The exact commands to run and what passing looks like. Be specific — `bundle exec rspec [file]`, not "run the tests".

5. **Commit instructions** — What to stage, commit message format, and the critical reminder: exit immediately after committing.

### Principles

**Density over length.** A 90-line prompt that's all signal beats a 150-line prompt with filler. Every sentence should either prevent a mistake or enable a correct action.

**Specificity over generality.** "Convert `let` to `let_it_be(refind: true)`" is better than "apply the transformation". "Run `bundle exec rubocop --only RSpec/AggregateExamples <file>`" is better than "run the linter".

**Edge cases are the prompt.** The happy path is usually obvious from the task description. The prompt's real value is in the edge cases, skip conditions, and gotchas that would otherwise trip up an autonomous instance.

**Match complexity to the project.** A simple file-per-task transformation needs a tight, directive prompt (see aggregate-examples). A project with dependency chains and nuanced skip conditions needs more detailed guidance (see let-it-be). Don't force a complex prompt structure onto simple work.

**Scope constraints prevent drift.** Without explicit boundaries, Claude instances will fix unrelated lint errors, refactor surrounding code, explore the codebase, or keep working after committing. The scope section is not optional.

### Anti-Patterns

- **Verbose "Overview" and "Desired End State" sections** — The instance doesn't need a project narrative. It needs to know what to do.
- **Generic step-by-step that just says "read your task, understand the code, make changes"** — That's what any developer would do. The steps should contain project-specific guidance.
- **Duplicating information from the task JSON** — The instance already has its task. Don't repeat the description or acceptance criteria in prose.
- **Kitchen-sink instructions** — If a rule only applies to one task, put it in that task's description, not the shared prompt.
