# Rails Specialist

Reviews Ruby and Rails code for convention adherence, clarity, and maintainability.

## Convention Over Configuration

- RESTful routes used? Custom actions justified?
- Fat models, skinny controllers — business logic not in controllers?
- Callbacks used sparingly and only for model-internal concerns?
- ActiveRecord over repository patterns — don't fight Rails?
- Standard Rails directory structure followed?

## Controller Quality

- Actions limited to standard CRUD (index, show, new, create, edit, update, destroy)?
- Complex actions extracted to dedicated controllers rather than custom actions?
- Strong parameters properly defined?
- Before actions used for shared setup (authentication, loading resources)?
- Response format handling clean (respond_to blocks not overly complex)?

## Model Quality

- Validations present and appropriate?
- Scopes used for reusable query logic?
- Enums defined cleanly?
- Associations correctly defined with proper dependent options?
- No business logic that belongs in a service object?
- Concerns used judiciously (not a dumping ground)?

## Service Object Conventions

- Uses the project's service object pattern (ActiveInteraction or equivalent)?
- Single responsibility — one service, one job?
- Clear inputs and outputs?
- Error handling via the service pattern (not raising random exceptions)?
- Composed services for multi-step workflows?

## Naming & Clarity

- **5-second rule**: Can you understand what a class/method does in 5 seconds from its name?
- `class Module::ClassName` pattern (not nested `module` blocks)?
- Method names express intent, not implementation?
- Boolean methods end with `?`?
- Bang methods (`!`) reserved for dangerous/mutating operations?

## Simplicity Over Abstraction

- **Duplication > Complexity**: Simple duplicated code is better than complex DRY abstractions
- Adding controllers is cheap; making them complex is expensive
- Don't add patterns (presenters, decorators, form objects) until the simpler approach fails
- Configuration bloat: hardcoded sensible defaults > flexible configuration nobody uses
- Don't cargo-cult enterprise patterns — justify every abstraction

## Testing Conventions

- Request specs for controller behavior?
- Model specs for validations, scopes, and business logic?
- Service specs for service objects?
- Factory Bot factories kept minimal (no unnecessary attributes)?
- `let` and `let!` used appropriately (lazy vs eager)?
- `describe` / `context` / `it` hierarchy clear?

## Common Rails Smells

- Logic in views (move to helpers, decorators, or view components)?
- God models with too many responsibilities?
- Callbacks creating hidden side effects?
- `after_save` / `after_commit` doing too much?
- Overuse of `rescue` blocks hiding real errors?
- String-based queries where ActiveRecord methods exist?
