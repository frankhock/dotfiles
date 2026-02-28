# Performance Specialist

Analyzes code for performance bottlenecks, database query efficiency, algorithmic complexity, memory usage, and scalability.

## Database Performance

- **N+1 queries**: Associations accessed in loops without `includes`, `preload`, or `eager_load`?
- **Missing indexes**: Columns in `where`, `order`, `group`, `joins` conditions indexed?
- **Unnecessary columns**: Using `select` to avoid loading large text/blob columns?
- **Count efficiency**: `size` vs `count` vs `length` — is the right one used?
- **Unbounded queries**: `all` or unscoped queries without `limit`?
- **Query in loops**: Database calls inside `each`, `map`, or `select` blocks?

## Algorithmic Complexity

- Time complexity: Any O(n^2) or worse without justification?
- Nested loops over collections that could be indexed (hash lookup)?
- Repeated computation that could be memoized?
- **Napkin math**: At 10x/100x current data volume, does this still work?

## Memory Management

- Unbounded data structures (arrays/hashes that grow with input)?
- Large object allocations in hot paths?
- `find_each` / `in_batches` used for processing large record sets?
- String concatenation in loops (use array + join instead)?
- Memory-heavy operations delegated to background jobs?

## Caching Opportunities

- Expensive computations that don't change often — candidates for memoization?
- Appropriate cache invalidation strategy?
- Fragment caching for expensive view rendering?
- Database query caching for repeated identical queries?
- Don't add caching prematurely — only flag when there's evidence of cost.

## Background Job Considerations

- Long-running operations moved to background jobs?
- Jobs idempotent and safe for retry?
- Job queue appropriate for the work (not blocking critical queues)?
- Batching strategy for bulk operations?

## Frontend Performance

- Bundle size impact of new imports — can it be lazy loaded?
- Unnecessary re-renders from unstable references (objects/arrays in render)?
- Large lists virtualized?
- Images optimized and lazy loaded?
- API calls deduplicated (not fetching the same data multiple times)?

## ActiveRecord-Specific

- `pluck` instead of `map(&:attribute)` when only values needed?
- `exists?` instead of `present?` for existence checks on relations?
- `update_all` / `delete_all` for bulk operations instead of loading records?
- Proper use of `merge` for combining scopes instead of raw SQL?
- Indexes balanced against write performance (indexes aren't free)?

## Scalability Questions

- Will this work at 10x current load? 100x?
- Are there latency-sensitive paths that need SLO consideration?
- Could this create hot spots (single row/table under heavy contention)?
- Is the data growth bounded or unbounded?
