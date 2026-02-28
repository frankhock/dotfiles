# Rigs: Vision PRD

> **Status**: Rough Draft
> **Date**: 2026-02-27
> **Author**: Frank Hock

---

## What is Rigs?

A **code factory** — a human-on-the-loop system where AI agents (rigs) do the development work and the developer steers. The name borrows from manufacturing: a "dark factory" is a facility that runs with the lights off because no humans are on the floor. The developer's role shifts from writing code to **setting direction, reviewing output, and making judgment calls**.

The goal: **10x a single developer's throughput** without 10x-ing their hours.

---

## Why Now?

1. **AI agents can now complete real tasks** — not just autocomplete, but plan, implement, test, and iterate across files and systems.
2. **The bottleneck has moved** — it's no longer "how fast can I type code" but "how fast can I make good decisions and unblock work."
3. **Claude Code already exists as the foundation** — we're not starting from scratch. We're building the orchestration, trust, and pipeline layers on top of a proven CLI agent.
4. **The gap is coordination, not capability** — a single agent can do a task. A factory coordinates *many* tasks flowing through *many* agents with a human approving at the right moments.

---

## Core Principles

1. **Human on the loop, not in the loop** — The AI works; the human steers. The developer should never be the bottleneck in the pipeline.
2. **Progressive autonomy** — Start with tight oversight. Earn trust. Unlock more autonomy based on track record. Never grant autonomy that can't be revoked.
3. **CLI-first** — Power users live in the terminal. The factory meets them there. Other surfaces (web, IDE) come later and are views into the same system.
4. **Factory, not workshop** — This isn't one agent doing one thing. It's a *pipeline* with parallelism, quality gates, and continuous operation. Work keeps moving even when the developer steps away.
5. **Opinionated but extensible** — Ship strong defaults. Allow customization for different teams and codebases.
6. **Continuous self-improvement** — The factory learns from its own work. Every task execution produces not just code but *insight* — what worked, what didn't, what took too long, what confused the agent. These reflections feed back into the system, tuning skills, prompts, sub-agents, and workflows over time. The factory that ships v2 should be measurably better than the one that shipped v1 — not because we manually improved it, but because it improved itself.

---

## The Developer Experience

### A Day in the Life

```
Morning:
  Developer reviews overnight rig output — 3 PRs ready for review,
  2 tasks blocked on architectural decisions, 1 merged automatically
  after passing all quality gates.

  They approve 2 PRs, reject 1 with feedback (factory will iterate),
  make the 2 architectural calls, and queue 5 new tasks from Linear.

  Total active time: 30 minutes.
  Factory output: what would have taken 2-3 days of hands-on coding.

Midday:
  Factory pings: "I've hit an ambiguity in the auth refactor — two valid
  approaches. Here's the tradeoff analysis. Which direction?"

  Developer picks option B. Factory continues.

Afternoon:
  Developer is deep in a design session for next quarter's architecture.
  Factory is running 4 parallel workstreams in the background.
  Status dashboard shows: 12 tasks completed today, 3 in progress, 1 blocked.
```

---

## Feature Areas

### 1. Work Intake & Task Management

**Why**: The factory needs a queue of work to process. Developers need to feed it tasks at various levels of granularity and see what's happening.

**Features**:
- **Task queue** — A prioritized backlog of work items the factory pulls from. Tasks can be granular ("add input validation to signup form") or broad ("implement the notification system from this spec").
- **Linear integration** — Pull issues directly from Linear. Status syncs bidirectionally. Factory updates issues as work progresses.
- **Task decomposition** — When a developer queues a feature-level task, the factory breaks it into subtasks, presents the plan, and asks for approval before executing.
- **Priority & scheduling** — Developer sets priority. Factory manages its own execution order based on dependencies, blocking status, and available context.
- **Natural language intake** — "Build the thing we talked about in the design doc" should work if the factory has access to the doc.

### 2. Agent Orchestration Engine

**Why**: A single agent is a tool. A *fleet* of coordinated agents is a factory. This is the core differentiator — managing multiple agents working in parallel across isolated environments.

**Features**:
- **Parallel workstreams** — Multiple agents working on independent tasks simultaneously, each in their own git worktree/branch.
- **Agent specialization** — Different agent configurations for different task types (implementation, testing, code review, documentation, refactoring). Not different models — different system prompts, tools, and constraints.
- **Dependency-aware scheduling** — The orchestrator understands task dependencies and sequences work correctly. Won't start "write integration tests" before "implement the API endpoint" is done.
- **Resource management** — Rate limiting, cost tracking, context window management. The factory shouldn't burn through API budget on low-priority work.
- **Failure handling & retry** — When an agent gets stuck, the orchestrator can: retry with different context, escalate to the developer, or reassign to a differently-configured agent.

### 3. Progressive Trust & Autonomy System

**Why**: This is what makes the factory safe to run with the lights off. Without a trust model, you either babysit everything (defeating the purpose) or let agents run wild (terrifying).

**Features**:
- **Trust tiers**:
  - **Supervised** — Agent works, developer reviews every output before it's applied. Starting point for new task types.
  - **Semi-autonomous** — Agent works and applies changes, but creates a PR for review before merge. Developer reviews async.
  - **Autonomous** — Agent works, tests pass, quality gates pass, changes merge automatically. Developer is notified but doesn't need to act.
- **Trust is scoped** — Trust level is per-repository, per-task-type, per-file-area. The factory might be autonomous for test files but supervised for auth code.
- **Track record** — The system tracks agent success rate, revert rate, and developer override frequency. Trust is earned through demonstrated reliability.
- **Guardrails** — Hard limits that apply regardless of trust level. Examples: never modify production configs without approval, never delete data migrations, never push to main.
- **Trust revocation** — If quality degrades (reverts increase, tests start failing), trust automatically ratchets down. The developer can also manually revoke at any time.

### 4. Quality Assurance Pipeline

**Why**: Trust requires verification. The factory needs built-in quality gates that are more rigorous than what a human would typically do, because the whole point is that the human *isn't* checking every line.

**Features**:
- **Automated test generation** — When the factory implements a feature, it also writes tests. Tests are a first-class output, not an afterthought.
- **Multi-agent review** — A separate review agent examines implementation agent output before it's presented to the developer. Catches obvious issues before they waste human attention.
- **Static analysis integration** — Linting, type checking, security scanning run automatically. Failures block progression.
- **Regression detection** — Run the full test suite. Compare behavior before/after. Flag any unexpected changes.
- **Consistency checking** — Does this change follow the patterns established in the codebase? Does it match the project's conventions? An agent specifically trained on *this* codebase's style.
- **Diff review scoring** — Every output gets a confidence score. Low-confidence outputs get routed to the developer even in autonomous mode.

### 5. Context & Knowledge System

**Why**: Agents are only as good as their context. The factory needs deep, persistent understanding of the codebase, conventions, architecture, and business domain — far beyond what fits in a single context window.

**Features**:
- **Codebase indexing** — Maintain a structured understanding of the codebase: architecture map, dependency graph, module boundaries, API surfaces.
- **Convention extraction** — Automatically learn patterns from the existing code: naming conventions, file organization, error handling patterns, test structure.
- **CLAUDE.md hierarchy** — Leverage and extend the existing CLAUDE.md convention for project-specific instructions, architectural decisions, and constraints.
- **Institutional memory** — Track decisions made, approaches tried and rejected, and why. Agents should never repeat a mistake the factory already learned from.
- **Documentation ingestion** — Consume design docs, specs, ADRs, and READMEs. Use them as context when planning and implementing.
- **Cross-task learning** — Patterns learned on task A inform how task B is approached. The factory gets smarter over time.

### 6. Developer Interface (CLI-First)

**Why**: The developer needs to control the factory, monitor progress, and intervene when needed — all from the terminal.

**Features**:
- **`rig status`** — Overview of all active workstreams, pending tasks, blocked items, and recent completions.
- **`rig queue <task>`** — Add work to the factory's backlog. Accepts natural language, Linear issue IDs, or structured task definitions.
- **`rig review`** — Enter review mode. Step through completed work that needs approval. Approve, reject with feedback, or request changes.
- **`rig watch`** — Live stream of what agents are doing right now. Tail the factory's activity log.
- **`rig config`** — Manage trust levels, guardrails, agent configurations, and integration settings.
- **`rig pause/resume`** — Halt all work or resume. Sometimes you need the factory to stop while you think.
- **Notification hooks** — Configure how/when the factory gets your attention: terminal notifications, Slack, email. Tunable urgency thresholds.
- **Session handoff** — Seamlessly pick up where the factory left off. "Show me what you were doing on the auth refactor" should give full context.

### 7. Integration Layer

**Why**: The factory doesn't exist in isolation. It needs to plug into the existing development ecosystem.

**Features**:
- **Git-native** — All work happens in branches/worktrees. Every change is traceable. Nothing is applied directly to main.
- **GitHub/GitLab** — PR creation, review comments, CI status checks, merge automation.
- **Linear** — Bidirectional sync. Issues become tasks, task completion updates issues.
- **CI/CD awareness** — Factory understands the CI pipeline. It can wait for CI results, interpret failures, and fix them.
- **Slack/notifications** — Configurable alerts for blocked tasks, completed reviews, trust changes.
- **Extensible** — Plugin architecture for adding new integrations without modifying core.

### 8. Observability & Analytics

**Why**: You can't improve what you can't measure. The factory needs to prove its value and surface problems early.

**Features**:
- **Throughput metrics** — Tasks completed per day/week, lines of code shipped, PRs merged.
- **Quality metrics** — Revert rate, bug rate in rig-produced code, test coverage of rig output.
- **Efficiency metrics** — Human time spent per task (review time), cost per task (API spend), time-to-completion.
- **Bottleneck detection** — Where is the factory spending the most time? Where does it get stuck most often? Where does it need the most human intervention?
- **Audit trail** — Every decision, every agent action, every human override is logged. Full traceability for compliance and debugging.

### 9. Self-Reflection & Harness Optimization

**Why**: The factory isn't just a static set of prompts and tools — it's a system that should get smarter with every task it runs. Agents have a unique vantage point: they know where they got stuck, what context was missing, which approaches failed before they found one that worked. That signal is gold, and today it's thrown away at the end of every session.

**Features**:
- **Post-task reflection** — After completing (or failing) a task, the agent produces a structured retrospective: what went well, what was harder than expected, where it got stuck, what context it wished it had, how long each phase took.
- **Reflection store** — A persistent, queryable log of reflections. Indexed by task type, codebase area, agent configuration, and outcome. Not just raw text — structured data the system can act on.
- **Pattern detection** — Aggregate reflections to surface recurring themes. "Agents consistently struggle with the payment module because the domain model isn't documented" or "test generation for React components fails 40% of the time because the test harness setup is non-standard."
- **Harness optimization loop** — Reflections feed directly into improvements to the factory's own configuration: refine system prompts, update CLAUDE.md files, tune agent specializations, add new sub-agent types, improve skill definitions. The factory proposes these changes; the developer approves.
- **Skill evolution** — When the factory discovers a better approach to a task type (e.g., "always run the type checker before writing tests for this repo"), it can codify that as a new or updated skill/command that future agents inherit.
- **Failure taxonomy** — Categorize *why* agents fail: missing context, ambiguous requirements, tooling gaps, model limitations, wrong approach. Each category has a different remedy, and the system should learn which remedy to apply.
- **Developer feedback integration** — When a developer rejects a PR, requests changes, or overrides a decision, that's high-signal reflection from the human side. Capture *what* they changed and *why*, and feed that back into the system.

---

## What We're NOT Building (Scope Boundaries)

- **Not an IDE** — We're building the engine and CLI. IDE integrations are a view layer that comes later.
- **Not a deployment platform** — The factory produces code and PRs. Deployment is handled by existing CI/CD.
- **Not a project manager** — The factory executes work. Product decisions, roadmap prioritization, and sprint planning stay with humans.
- **Not a replacement for code review** — Even in autonomous mode, the factory creates reviewable artifacts. The human can always inspect. The factory augments review, not replaces it.

---

## Progressive Rollout Strategy

### Phase 1: Foundation (Task-Level Rig)
- Single-agent task execution with human review of every output
- Basic task queue and status tracking
- Git worktree isolation
- Linear integration for intake
- Trust system scaffolding (everything starts at "supervised")
- CLI with `status`, `queue`, `review` commands
- Post-task reflection capture (structured retros after every task)

### Phase 2: Parallelism (Multi-Rig)
- Multiple agents running concurrently on independent tasks
- Agent specialization (implementation vs. testing vs. review)
- Dependency-aware scheduling
- Quality gates (automated tests, lint, type checking)
- Semi-autonomous trust tier unlocked
- Cost tracking and resource management
- Reflection store with pattern detection across tasks
- Developer feedback loop (rejections/overrides captured as learning signal)

### Phase 3: Autonomy (Lights-Off)
- Full progressive trust system with automatic trust adjustment
- Multi-agent review pipeline (agents reviewing agents)
- Autonomous tier unlocked for qualifying task types
- Cross-task learning and institutional memory
- Advanced observability and analytics dashboard
- Notification system for async developer engagement
- Harness optimization loop (factory proposes improvements to its own skills, prompts, and agent configs)
- Skill evolution (agents codify discovered best practices into reusable skills)

---

## Open Questions

1. **Model flexibility** — Should the factory be Claude-only or model-agnostic? Claude-only simplifies everything but creates vendor lock-in.
2. **Security model** — How do we handle codebases with secrets, credentials, and sensitive data? The factory needs access to code but shouldn't leak.
3. **Collaboration** — How do multiple developers share a factory? Does each developer have their own, or is it team-level?
4. **Offline/local mode** — Can the factory run entirely locally for airgapped environments?

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Developer throughput multiplier | 5-10x measured by tasks completed per week |
| Human time per rig-produced PR | < 15 minutes average review time |
| Factory-produced code revert rate | < 5% (on par with or better than human-produced code) |
| Time from task intake to merged PR | < 4 hours for task-level, < 24 hours for feature-level |
| Developer satisfaction | "I can't imagine going back" — qualitative |
