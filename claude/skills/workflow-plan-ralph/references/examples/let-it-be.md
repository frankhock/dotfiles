# Example: Complex Transformation with Dependencies (let_it_be team_account)

This prompt handles a transformation with dependency chains, skip conditions, and nuanced edge cases. Note how the bulk of the prompt is edge case documentation — that's where autonomous instances need the most help.

---

## SCOPE CONSTRAINT — READ THIS FIRST

You have ONE job: complete YOUR assigned task. Nothing else.

**Rules:**
- ONLY do what your task's description and acceptance criteria ask for
- Do NOT fix unrelated issues you encounter (lint errors, refactoring opportunities, style inconsistencies, etc.)
- Do NOT explore or investigate beyond what is needed to complete your task
- Do NOT modify files or code unrelated to your task
- Do NOT continue working after committing — EXIT IMMEDIATELY with code 0
- If you catch yourself wanting to do anything outside your task — STOP. That is out of scope.

## Context

This project converts `let`/`let!` declarations that create team_account family factories to `let_it_be(refind: true)` in RSpec spec files. Each `create(:team_account)` produces 5 INSERTs + 3 SELECTs, so eliminating redundant per-example creation significantly reduces CI time. Phase 1 (7 high-impact files) is already done on this branch. You are doing Phase 2.

## Project-Specific Instructions

### The Transformation Pattern

```ruby
# BEFORE
let(:team_account) { create(:team_account, team:) }
let!(:team_account) { create(:team_account, verified: true) }

# AFTER
let_it_be(:team_account, refind: true) { create(:team_account, team:) }
let_it_be(:team_account, refind: true) { create(:team_account, verified: true) }
```

**Target factories**: `team_account`, `team_researcher`, `team_admin`, `team_teammate`, `organization_administrator`, `organization_owner`, `verified_team_member` (when `.account` is called on the result).

### Dependency Resolution (`team:` shorthand)

Many declarations use `team:` shorthand referencing a `let(:team)` in the same or parent scope:

1. **If `team` is already `let_it_be`** — works as-is
2. **If `team` is a plain `let` calling `create(:team, ...)`** — also convert to `let_it_be(:team, refind: true)` if nothing mutates/destroys it
3. **If `team` is derived** (e.g., `let(:team) { account.spec_team }`) — keep as plain `let`, inline the reference in the `let_it_be` block: `team: account.spec_team`

### What to SKIP

- `build_stubbed(:team_account)` — incompatible with `let_it_be`
- Declarations where the record is `destroy`ed or `delete`d in tests
- `sign_in_as` calls — must stay in `before(:each)`
- Declarations inside `shared_examples` that reference variables overridden by including context
- `subject(:name)` using `build_stubbed`

### Multi-line blocks and FactoryBot prefix

Preserve block structure and explicit `FactoryBot.create` prefix if present.

### `other_team_account` chains

If converting `team_account` and `other_team_account` references `team_account.spec_team`, also convert `other_team_account` — `let_it_be` variables are available to later `let_it_be` blocks.

## Step-by-Step Execution

### Step 1: Read your assigned task
Your task JSON is at the top of this prompt.

### Step 2: Understand the relevant code
Read each file. Identify which `let`/`let!` declarations create target factories, check `team:` dependencies, check for skip conditions.

### Step 3: Make your changes
Convert all eligible declarations following the patterns above. Resolve `team:` dependencies. Do NOT touch anything else.

### Step 4: Verify your changes
```bash
bundle exec rspec [files]
bundle exec rspec [files] --order random --seed 12345
bundle exec rspec [files] --order random --seed 54321
./bin/lintbot
```

If tests fail: check for unconverted dependencies or missing `refind: true`. If a file can't be safely converted, revert it and note in commit message.

### Step 5: Commit and EXIT
```bash
git add [changed files explicitly]
git commit -m "Convert team_account let/let! to let_it_be(refind: true) in [category] specs"
```

**After committing, you are DONE. Exit with code 0.**
