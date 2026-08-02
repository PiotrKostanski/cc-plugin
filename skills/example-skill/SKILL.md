---
name: example-skill
description: Example skill showing the SKILL.md format. Replace this description with one that tells Claude precisely when to invoke the skill, since the model decides based on this text alone.
---

# Example Skill

This is a scaffold skill. Replace this content with real instructions.

Skills are invoked either by the model (based on `description` matching the
task) or explicitly by the user via `/cc-plugin:example-skill`.

## Arguments

If the user passes arguments after the slash command, they're available as
`$ARGUMENTS`:

```
/cc-plugin:example-skill some input here
```

## Structure

- `SKILL.md` — required, this file
- Add `reference.md`, `scripts/`, or other supporting files alongside it as
  needed; keep `SKILL.md` itself short and link out to details.

## Removing this skill

Delete the `skills/example-skill/` directory, or rename it and rewrite the
frontmatter and body for your own use case.
