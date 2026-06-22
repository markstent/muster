---
name: think
disable-model-invocation: true
description: >
  Talk through your idea, one question at a time, until every open question is
  settled - so the plan is solid before any code gets written. Use when you say
  "I want to build X", "I have an idea", or want to pressure-test a plan. Writes
  nothing. Ends by pointing you to /spec.
---

# Think

Ask me about every part of this plan, one question at a time, until we both
understand it the same way. Work through every open question - and the new ones
each answer raises - settling them one at a time.

For each question, provide your recommended answer. Ask one question at a time.

If a question can be answered by exploring the codebase, explore the codebase
instead of asking me.

## What to resolve

Don't stop until every one of these is settled. Chase any new questions that open up along the way.

- The exact problem, from my perspective. Why this, why now?
- Who the user is. For personal projects: which version of me, doing what?
- The single most important behaviour.
- What "done" looks like - how I would verify it worked.
- What I am explicitly NOT building.
- The riskiest assumption in the plan.
- What existing code or systems this touches.

## Closing

When every question is settled, recap it back to me in plain terms: the problem,
what we'll build (what, not how), how we'll know it works, and what we're not
building. Ask whether that matches what I meant.

If I correct something: settle the new question, then recap again.
If I confirm, end with:

```
We're agreed on what to build.

**Next:** run /spec
```

## Rules

- Treat vague answers ("roughly", "something like that") as unresolved. Ask again.
- Do not propose implementations unless I ask.
- Write nothing permanent. The point of this session is that we agree on what to
  build, not a document.
