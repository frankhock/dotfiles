# TypeScript & React Specialist

Reviews TypeScript, JavaScript, and React code for type safety, modern patterns, component design, and maintainability.

## Type Safety

- No `any` without strong justification and a comment explaining why?
- Proper type inference used (don't annotate what TypeScript can infer)?
- Union types and discriminated unions over loose string types?
- Type guards used for narrowing instead of type assertions (`as`)?
- Generics used where they add value, not just complexity?
- **Stringly-typed code**: Using strings where union types or enums would give compile-time safety?

## React Component Design

- **UI is a function of state**: Can you predict UI output from state alone?
- **Unidirectional data flow**: Data flows down via props, events flow up via callbacks?
- Components have a single, clear responsibility?
- **Presentation vs. logic separation**: Mixed concerns extracted into hooks or utilities?
- Component API (props) is minimal and well-typed?
- `key` props used correctly in lists (stable, unique identifiers)?

## Hooks

- Custom hooks extract reusable stateful logic?
- `useEffect` dependencies correct and complete?
- `useEffect` cleanup functions prevent memory leaks?
- `useMemo` / `useCallback` used for expensive computations or stable references, not prematurely?
- Hook rules followed (not called conditionally or in loops)?
- **Hook extraction signals**: When a component has 3+ hooks doing related work, consider a custom hook

## State Management

- State lifted to the lowest common ancestor, no higher?
- Server state managed via RTK Query (not local state for API data)?
- Form state handled appropriately (controlled vs uncontrolled)?
- Derived state computed, not stored (no state that could be a `useMemo`)?
- Global state justified — not used for component-local concerns?

## Modern Patterns

- Destructuring, spread, optional chaining used appropriately?
- `satisfies` operator used for type-safe object literals?
- Prefer immutable patterns over mutation?
- Functional patterns (map, filter, reduce) over imperative loops where clearer?
- Named exports over default exports for better refactoring?

## Import Organization

- Grouped: external libs, internal modules, types, styles?
- No wildcard imports?
- No circular imports?
- Dead imports removed?

## Naming & Clarity

- **5-second rule**: Can you understand what a component/function does from its name?
- Components use PascalCase, hooks use `use` prefix?
- Event handlers use `handle` prefix (`handleClick`, `handleSubmit`)?
- Boolean props use `is`/`has`/`should` prefix?
- Files named to match their primary export?

## Testing

- Components tested for user-visible behavior (not internal state)?
- RTK Query endpoints mocked at the MSW handler level?
- Accessibility checked in tests (`getByRole`, `getByLabelText`)?
- Test file suffix matches project convention (`_spec.tsx`)?
- Snapshot tests used sparingly and intentionally?

## Common React Smells

- Props drilling more than 2-3 levels (use context or composition)?
- Unstable references causing unnecessary re-renders (objects/arrays created in render)?
- `useEffect` as a state synchronization mechanism (usually a sign of wrong mental model)?
- Over-fetching data (loading entire objects when only a few fields needed)?
- Imperative DOM manipulation instead of declarative React patterns?
