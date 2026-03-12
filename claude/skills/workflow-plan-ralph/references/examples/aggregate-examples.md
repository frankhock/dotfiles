# Example: Simple Transformation (SUP-1824 Aggregate Examples)

This prompt is for a mechanical, one-file-per-task transformation. Note how tight and directive it is — every line prevents a specific mistake or enables a specific action.

---

## SCOPE CONSTRAINT — READ THIS FIRST

You have ONE job: fix RSpec/AggregateExamples offenses in YOUR ASSIGNED FILE. Nothing else.

**Rules:**
- You may ONLY modify the ONE file specified in your task
- You may NOT modify any other file for any reason
- You may NOT explore, read, or investigate files beyond your assigned file
- You may NOT fix other RuboCop cops, even if you see them
- You may NOT modify `.rubocop_todo.yml`, `.rubocop.yml`, or any config file
- After committing your one file, EXIT IMMEDIATELY with code 0

If you catch yourself wanting to look at or change anything outside your assigned file — STOP. That is out of scope.

## The Transformation

Combine consecutive single-expectation `it` blocks into `specify(:aggregate_failures)` blocks.

### Before (violation)

```ruby
it 'does not let nobodies delete projects' do
  expect(described_class).not_to permit_nobody(project)
end

it 'lets project owners delete their projects' do
  expect(described_class).to permit_account(account, project)
end

it 'lets admins delete projects' do
  expect(described_class).to permit_user(admin, project)
end
```

### After (fixed)

```ruby
specify(:aggregate_failures) do
  expect(described_class).not_to permit_nobody(project)
  expect(described_class).to permit_account(account, project)
  expect(described_class).to permit_user(admin, project)
end
```

## Step-by-Step Instructions

Follow these steps EXACTLY. Do not deviate.

### Step 1: Find your file

Your task JSON is at the top of this prompt. Note the SINGLE file path.

### Step 2: Run rubocop on your file

```bash
bundle exec rubocop --only RSpec/AggregateExamples <your-file>
```

This shows which `it` blocks to combine. Each offense says "Aggregate with the example at line N" — all offenses pointing to the same anchor line form one group.

### Step 3: Read your file and make edits

Read your assigned file. For each offense group:
1. Replace the consecutive `it`/`specify` blocks with a single `specify(:aggregate_failures) do ... end`
2. Keep only the `expect(...)` lines from each original block
3. Preserve expectation order — do NOT reorder
4. Keep the same indentation level as the original blocks
5. Drop the `it` block description strings — do not preserve them as comments

### Step 4: Verify rubocop passes

```bash
bundle exec rubocop --only RSpec/AggregateExamples <your-file>
```

Must report 0 offenses. If not, fix remaining issues.

### Step 5: Verify specs pass

```bash
bundle exec rspec <your-file>
```

Must pass. If it fails, you changed test behavior — revert and try again more carefully.

### Step 6: Commit ONLY your file and EXIT

```bash
git add <your-file>
git commit -m "Aggregate examples in <filename>"
```

Use just the filename (e.g., `project_policy_spec.rb`), not the full path. Stage ONLY your assigned file — do NOT use `git add .` or `git add -A`.

**After committing, you are DONE. Exit with code 0. Do not continue working.**

## Rules for Combining

- **Only combine blocks rubocop flags** — do not combine blocks that rubocop does not flag
- **Multiple groups per file** — a file may have several independent groups in different `describe`/`context`/`permissions` blocks. Each group becomes its own `specify(:aggregate_failures)` block
- **Multi-line expectations** — some `expect(...)` calls span multiple lines. Preserve the full expression
- **Shared examples** — `shared_examples` blocks are refactored the same way
- **Nested contexts** — each `context`/`describe` block's consecutive `it` blocks are independent groups
- **Do NOT modify** `subject`, `let`, `before`, `after`, or any non-`it`/`specify` blocks
- **Do NOT add or remove expectations** — only restructure them
- **Do NOT change test logic, assertions, or setup**

## Syntax

Always use this exact syntax:
```ruby
specify(:aggregate_failures) do
  # expectations here
end
```

Do NOT use: `it(:aggregate_failures)`, `it 'desc', :aggregate_failures do`, or `aggregate_failures do` block form.
