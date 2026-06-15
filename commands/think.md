---
name: think
description: >
  Interrogate me about an idea until every branch of the decision tree is
  resolved. Use when I say "I want to build X", "I have an idea", or want to
  stress-test a plan. Write nothing. End by pointing me to /spec.
---

# Think

Interview me relentlessly about every aspect of this plan until we reach a
shared understanding. Walk down each branch of the decision tree, resolving
dependencies between decisions one at a time.

For each question, provide your recommended answer. Ask one question at a time.

If a question can be answered by exploring the codebase, explore the codebase
instead of asking me.

## What to resolve

Don't stop until every one of these is settled. Follow new branches as they open.

- The exact problem, from my perspective. Why this, why now?
- Who the user is. For personal projects: which version of me, doing what?
- The single most important behaviour.
- What "done" looks like — how I would verify it worked.
- What I am explicitly NOT building.
- The riskiest assumption in the plan.
- What existing code or systems this touches.

## Closing

When every branch is resolved, summarise back to me: problem, solution (what,
not how), done-criteria, explicit non-goals. Ask whether it matches what I meant.

If I correct something: resolve the new branch, then re-summarise.
If I confirm, end with:

```
**Next:** run /spec
```

## Rules

- Treat vague answers ("roughly", "something like that") as unresolved. Ask again.
- Do not propose implementations unless I ask.
- Write nothing permanent. The output of this session is shared understanding,
  not a document.
