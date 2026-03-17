# Calibration Examples

Well-edited skills from Matt Pocock's collection (github.com/mattpocock/skills). Study the density — every line changes behavior.

## grill-me — 2 sentences, no phases

```
Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead.
```

Why it works: "relentlessly" sets intensity. "Each branch of the design tree" gives structure without numbered phases. The one constraint (prefer codebase over asking) is the only non-obvious behavior.

## triage-issue — minimal questions, bias toward action

```
Investigate a reported problem, find its root cause, and create a GitHub issue with a TDD fix plan. This is a mostly hands-off workflow - minimize questions to the user.

### 1. Capture the problem
Get a brief description of the issue from the user. If they haven't provided one, ask ONE question: "What's the problem you're seeing?"
Do NOT ask follow-up questions yet. Start investigating immediately.
```

Why it works: "ONE question" and "Do NOT ask follow-up questions" override default model chattiness. The phase structure earns its keep because the model needs to gate (investigate before proposing fixes).

## write-a-prd — phases earn their place

```
1. Ask the user for a long, detailed description of the problem they want to solve and any potential ideas for solutions.
2. Explore the repo to verify their assertions and understand the current state of the codebase.
3. Interview the user relentlessly about every aspect of this plan until you reach a shared understanding.
4. Sketch out the major modules you will need to build or modify to complete the implementation.
5. Once you have a complete understanding, use the template below to write the PRD.
```

Why it works: 5 steps, each one sentence. No sub-bullets explaining how to do each step. "You may skip steps if you don't consider them necessary" trusts the model.

## Pattern: what earns its place

- Output templates (verbatim structure the model should emit)
- Behavioral overrides (things the model wouldn't do by default)
- Boundary constraints ("do NOT do X" when X is a likely default)
- Philosophy that changes decisions ("deep modules over shallow modules")

## Pattern: what doesn't

- Describing standard LLM behavior (ask questions, validate, be flexible)
- Listing example questions the model could ask (it knows how to interview)
- Explaining what phases mean after naming them
- Hedged instructions ("consider whether", "you may want to")
