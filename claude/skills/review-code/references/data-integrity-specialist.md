# Data Integrity Specialist

Reviews database migrations, data models, schema changes, and persistent data code for safety and correctness.

## Migration Safety

For every migration in the diff:

- **Reversibility**: Is `down` defined and safe? Or clearly documented as irreversible?
- **Data loss**: Could this migration destroy or corrupt existing data?
- **NULL handling**: Are defaults set for new NOT NULL columns? Are existing NULLs handled?
- **Lock duration**: Will this lock large tables? Use `disable_ddl_transaction!` for long-running ops?
- **Batching**: Large data updates should use `in_batches` or chunked processing, not unbounded `UPDATE`
- **Idempotency**: Can this migration be safely re-run?
- **Index safety**: Use `algorithm: :concurrently` for indexes on large tables

## Schema Drift Detection

When `db/schema.rb` is in the diff:

1. List all migrations in the PR: `git diff main --name-only -- db/migrate/`
2. Cross-reference every schema.rb change against those migrations
3. Flag any schema changes NOT explained by a PR migration — these are drift from running other branches' migrations locally

**Drift indicators:**
- Columns not in any PR migration
- Tables not referenced in PR migrations
- Schema version higher than the PR's newest migration
- Indexes not created by PR migrations

**Fix:** `git checkout main -- db/schema.rb && bin/rails db:migrate`

## Referential Integrity

- Foreign keys defined at the database level, not just Rails associations?
- Cascade behaviors on deletions appropriate? (destroy vs. nullify vs. restrict)
- Orphaned record prevention for polymorphic associations?
- Dependent associations handled (`dependent: :destroy` or `:nullify`)?

## Transaction Boundaries

- Atomic operations wrapped in transactions?
- Transaction scope appropriate (not too broad, not too narrow)?
- Potential deadlock scenarios from lock ordering?
- Rollback handling for failed operations?
- Nested transactions using `requires_new: true` when needed?

## Data Migration / Backfill Checklist

For PRs with data transformations:

- [ ] Mappings verified against production data, not fixtures
- [ ] Every CASE/IF branch has a match (no silent NULL from unmatched values)
- [ ] Hard-coded constants compared against production query output
- [ ] Backfill runs in batches with throttling
- [ ] Verification SQL provided to confirm correctness post-deploy
- [ ] Rollback plan documented
- [ ] Feature flag or dual-write strategy for safe transition

## Common Bugs

1. **Swapped IDs**: `1 => TypeA, 2 => TypeB` in code but reversed in production
2. **Missing error handling**: `.fetch(id)` crashes on unexpected values
3. **Orphaned eager loads**: `includes(:deleted_association)` causes runtime errors
4. **Incomplete dual-write**: New records only write new column, breaking rollback
