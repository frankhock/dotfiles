---
name: code-trace
description: Use when tracing code paths, understanding "what happens when X", or documenting flows - comprehensive multi-phase tracing with event chain expansion, concern expansion, callback tracing, and async job following. Use BEFORE debugging (to understand), during onboarding (to document), or when asked to explain how something works
---

# Code Trace

## Overview

Tracing code paths reveals how systems actually work. Incomplete traces lead to wrong assumptions.

**Core principle:** Follow every path to completion. Incomplete traces are wrong traces.

**Violating the letter of this process is violating the spirit of tracing.**

## The Iron Law

```
NO TRACE COMPLETE WITHOUT FOLLOWING ALL ASYNC HANDOFFS AND EXPANDING ALL CONCERNS
```

If you haven't traced every event handler, expanded every concern, and followed every async job, the trace is incomplete.

## Gate Function: When to Use This Skill

```
BEFORE claiming you understand a code path:

1. IDENTIFY: What am I being asked to trace?
2. SCOPE: Is this a simple method or a system-spanning flow?
   - Simple method (< 3 calls, no async, no events) → Quick trace OK
   - Complex flow → MUST use full process below
3. VERIFY: Does the flow involve ANY of these?
   - Model callbacks (after_*, before_*)
   - Event publishing (EventService.publish)
   - Background jobs (perform_later, perform_async)
   - Multiple concerns (include statements)
   - Service objects calling other services

If YES to ANY above → Use full multi-phase process
```

## The Five Phases

You MUST complete each phase before claiming the trace is complete.

### Phase 1: Scope and Entry Point Discovery

**Find the starting point efficiently:**

1. **For Web Flows - Routes First**
   ```bash
   # Find route definition
   grep -r "pattern_from_url" config/routes.rb

   # Find controller action
   grep -rn "def action_name" app/controllers/
   ```

2. **For Events - Publisher Case Statement**
   ```ruby
   # Check app/services/events/publishers/active_job_event_publisher.rb
   # Find: when Events::YourEventName then [handlers...]
   ```

3. **For Models - Start with Model File**
   ```bash
   # List includes at top of model
   head -50 app/models/your_model.rb
   ```

4. **Naming Convention Search**
   ```bash
   # Service objects: app/services/*/
   # Event handlers: app/services/events/event_name/
   # Concerns: app/models/concerns/
   ```

**Discovery Strategy:**
- Use `grep` with file type filters (`--include="*.rb"`)
- Read line ranges, NOT entire files (`head -100`, specific line numbers)
- Follow naming conventions first, grep second
- Stop at entry point file:line before proceeding

**Phase 1 Output:**
- Entry point: `path/to/file.rb:line`
- Type: controller/service/model/job/event_handler
- Initial scope assessment

### Phase 2: Primary Path Tracing (Breadth-First)

**Follow the main execution flow:**

1. **Read the Entry Point Method**
   - Note all method calls (service objects, model methods)
   - Note all conditionals (branching logic)
   - Note all data transformations

2. **Trace Each Call One Level Deep**
   - For each method call, find its definition
   - Record: file:line, what it does (1 sentence)
   - Don't go deeper yet - breadth first

3. **Flag Important Details**
   | Type | What to Note |
   |------|-------------|
   | **Decisions** | `if`, `case`, `unless` - what branches exist |
   | **Rules** | Business logic, validations, authorization |
   | **Gotchas** | Surprising behavior, tech debt, edge cases |
   | **Side Effects** | Emails, webhooks, audit logs, analytics |
   | **Async Handoffs** | Background jobs, event publishes |

4. **Build Initial Flow**
   ```
   Entry → Call1 → Call2 → [branches]
                         → [async handoff] (mark for Phase 4)
   ```

**Phase 2 Output:**
- Linear flow from entry to completion
- List of async handoffs to trace in Phase 4
- List of concerns to expand in Phase 3

### Phase 3: Expansion (Concerns, Callbacks, Event Handlers)

**Expand hidden behavior that Phase 2 skipped:**

#### 3A: Concern Expansion

For EVERY `include` statement in involved models:

1. **List All Includes**
   ```ruby
   # From model file:
   include CanAcceptTerms
   include HasCalendar
   include Actor
   # etc.
   ```

2. **Read Each Concern**
   ```bash
   # Find concern file
   find app/models/concerns -name "*.rb" | xargs grep -l "module ConcernName"
   ```

3. **Document What Each Adds**
   - Methods added
   - Callbacks defined
   - Associations added
   - Validations added

#### 3B: Callback Chain Tracing

For EVERY model touched in the flow:

1. **Find All Callbacks**
   ```bash
   grep -E "after_|before_|around_" app/models/model_name.rb
   ```

2. **Trace Each Callback**
   - What does it do?
   - Does it publish events? (→ Phase 4)
   - Does it enqueue jobs? (→ Phase 4)
   - Does it modify other records?

3. **Document Callback Chain**
   ```
   Model.save
   → before_validation: validate_something
   → after_create: set_defaults
   → after_commit: EventService.publish(Event)
   ```

#### 3C: Event Handler Identification

For EVERY `EventService.publish` found:

1. **Find Handler List**
   ```ruby
   # In active_job_event_publisher.rb:
   when Events::YourEvent then [
     Handler1,
     Handler2,
     Handler3,
   ]
   ```

2. **Document Each Handler**
   - File location
   - What it does (1 sentence)
   - Mark for Phase 4 tracing

**Phase 3 Output:**
- Complete list of concerns with their additions
- Complete callback chain for each model
- Complete list of event handlers to trace

### Phase 4: Async Chain Tracing

**Follow every async handoff to completion:**

#### 4A: Event Handlers

For EACH event handler identified in Phase 3:

1. **Read the Handler**
   ```ruby
   # app/services/events/event_name/handler_name_event_handler.rb
   def handle_event(event, actor)
     # What does this do?
   end
   ```

2. **Trace Handler Logic**
   - What service objects does it call?
   - What models does it modify?
   - Does it enqueue MORE jobs?
   - Does it publish MORE events? (recursive)

3. **Document Side Effects**
   - External API calls (Mixpanel, HubSpot, etc.)
   - Emails sent
   - Records created/updated

#### 4B: Background Jobs

For EACH `perform_later` or `perform_async`:

1. **Find Job Class**
   ```bash
   find app/jobs -name "*.rb" | xargs grep -l "class JobName"
   ```

2. **Read `perform` Method**
   - What does the job do?
   - Does it call services?
   - Does it publish events?

3. **Document Job**
   - Queue name (priority)
   - What triggers completion/failure
   - Retry behavior

#### 4C: Recursive Event Chains

If handlers/jobs publish MORE events:
- Add to trace list
- Repeat Phase 4 for new events
- Continue until no more async handoffs

**Phase 4 Output:**
- Complete async flow diagram
- All side effects documented
- All external service calls listed

### Phase 5: Documentation and Verification

**Compile and verify the complete trace:**

#### 5A: Compile Documentation

Use this output format:

```markdown
# [Question as title]
**Traced:** [Date]
**Entry Point:** `path/to/file.rb:line`

## Summary
[2-3 sentences in plain language. No jargon. A PM should understand
what happens and what could go wrong. Focus on business impact.]

## Flow

### 1. [Step Name]
`path/to/file.rb:45-67`

[What happens at this step]

- **Decision:** [Key branching logic if any]
- **Rule:** [Business rule if any]
- **Gotcha:** [Surprising behavior if any]
- **Async:** [Event/job triggered if any]

→ Calls: `NextService#method`

### 2. [Next Step]
...continue pattern...

## Concerns Expanded
| Concern | Adds | Impact on Flow |
|---------|------|----------------|
| `ConcernName` | methods, callbacks | [how it affects this flow] |

## Callback Chain
```
Model.save
→ before_validation: ...
→ after_commit: EventService.publish(...)
```

## Event Handlers Traced
| Event | Handler | Side Effects |
|-------|---------|--------------|
| `EventName` | `HandlerName` | [what it does] |

## Async Jobs
| Job | Triggered By | Does |
|-----|--------------|------|
| `JobName` | [event/direct] | [what it does] |

## Diagram
[Mermaid sequence diagram or ASCII flow]

## Key Findings
| What | Where | Why It Matters |
|------|-------|----------------|
| [Finding] | `file:line` | [Impact] |

## Open Questions
- [ ] [What couldn't be determined from code]
```

#### 5B: Verification Checklist

**STOP. Before claiming trace complete, verify:**

- [ ] Entry point identified with exact file:line
- [ ] All `include` statements expanded (list concerns checked)
- [ ] All callbacks traced (list callbacks found)
- [ ] All event handlers identified and traced
- [ ] All async jobs followed to completion
- [ ] All external service calls documented
- [ ] Side effects listed (emails, webhooks, analytics)
- [ ] Open questions documented (what you couldn't determine)
- [ ] PM-readable summary written

**If ANY checkbox is unchecked, return to appropriate phase.**

## Red Flags - STOP and Return to Earlier Phase

If you catch yourself:
- Saying "I think this calls..." without verifying → Return to Phase 2
- Seeing `EventService.publish` but not tracing handlers → Return to Phase 4
- Seeing `include ConcernName` but not expanding → Return to Phase 3
- Seeing `perform_later` but not following the job → Return to Phase 4
- Seeing `after_commit` but not tracing the callback → Return to Phase 3
- Skipping a model's callbacks because "it's just a helper" → Return to Phase 3
- Assuming an event handler is "just analytics" without reading it → Return to Phase 4

**ALL of these mean: Trace is incomplete. Go back.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "This event handler is just Mixpanel" | Read it. It might do more. Analytics handlers sometimes contain business logic. |
| "I already know what this concern does" | Verify. Concerns change. Read the actual file. |
| "The callback is obvious from the name" | Names lie. `after_create :notify` might publish 5 events. |
| "That job is just cleanup" | Trace it. Cleanup jobs often have side effects. |
| "Too many handlers to trace them all" | Trace them all. Comprehensive means comprehensive. |
| "The async chain is too deep" | Keep going. Incomplete traces are wrong traces. |
| "I'll trace the async part later" | No. Trace it now or mark trace as incomplete. |

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Read entire 1000-line files | Use line ranges: `head -100`, specific line numbers |
| Skip concern expansion | List ALL includes, expand EACH one |
| Stop at event publish | Follow through to ALL handlers |
| Ignore callbacks | Search for ALL `after_*`, `before_*` patterns |
| Trace framework internals | Stop at Rails/library boundaries |
| Assume handler behavior from name | Read the `handle_event` method |
| Leave async as "to be traced" | Complete Phase 4 before Phase 5 |

## Rails-Specific Patterns

### Tracing Events

```
Model callback publishes event
→ EventService.publish(Event.new(...))
→ ActiveJobEventPublisher.publish(event, actor)
→ case event matches handlers array
→ Each handler.perform_later(event_name, event_json, actor)
→ Handler#perform deserializes and calls handle_event
→ handle_event executes business logic
```

**Key file:** `app/services/events/publishers/active_job_event_publisher.rb`
- Contains the case statement mapping events to handlers
- ALWAYS check this file for any event

### Tracing Concerns

```
class Model < ApplicationRecord
  include ConcernA  # → app/models/concerns/concern_a.rb
  include ConcernB  # → app/models/concerns/model_name/concern_b.rb
```

Concerns can live in:
- `app/models/concerns/`
- `app/models/concerns/model_name/`
- `app/controllers/concerns/`

### Tracing Service Objects

Pattern: `app/services/domain/action_name.rb`

Service objects inherit from `ActiveInteraction`:
```ruby
class Services::Domain::ActionName < ActiveInteraction
  def execute
    # Business logic here
  end
end
```

Called via: `Services::Domain::ActionName.run!(params)`

## Composability with Other Skills

**Use this skill BEFORE:**
- `systematic-debugging` - Trace to understand before debugging
- Writing implementation plans - Know the system before changing it

**Use DURING this skill:**
- `root-cause-tracing` - When tracing backward from symptoms
- `verification-before-completion` - Before claiming trace is complete

**After tracing, consider:**
- `defense-in-depth` - If trace reveals missing validations
- `brainstorming` - If trace reveals design issues

## Quick Reference

| Phase | Key Activity | Output |
|-------|-------------|--------|
| **1. Discovery** | Find entry point | file:line, type |
| **2. Primary Path** | Breadth-first trace | Linear flow, async list |
| **3. Expansion** | Concerns, callbacks, handlers | Hidden behavior documented |
| **4. Async** | Follow all handoffs | Complete async chains |
| **5. Documentation** | Compile and verify | PM-readable trace document |

## Real-World Impact

From actual traces:
- Single model save triggered 15 event handlers
- "Simple" update modified records in 4 tables via callbacks
- Concern added 12 methods to model silently
- Event chain was 4 levels deep (event → handler → job → event → handler)

**Incomplete traces miss this complexity. Complete traces reveal it.**
