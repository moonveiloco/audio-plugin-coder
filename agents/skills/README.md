# APC Skills Index

Catalog of the skills available in `agents/skills/`. Each skill is a folder
with `SKILL.md` (the loaders detect them flat, one level under `skills/`).

## Phase skills (APC workflow)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [`dream`](dream/SKILL.md) | `/dream [Name]` | Ideation, creative brief |
| [`plan`](plan/SKILL.md) | `/plan [Name]` | Architecture and planning |
| [`design`](design/SKILL.md) | `design UI for [plugin]` | Visual interface (frontmatter `skill_design`) |
| [`impl`](impl/SKILL.md) | — (phase 4) | DSP implementation (+ WebView integration) |
| [`test`](test/SKILL.md) | `/test [Name]` | Validation (delegates to `testing`) |
| [`ship`](ship/SKILL.md) | `/ship [Name]` | Cross-platform packaging |
| [`debug`](debug/SKILL.md) | — | Autonomous debugging in VSCode (frontmatter `skill_debug`) |
| [`setup`](setup/SKILL.md) | — | First-run setup/onboarding |

## Domain skills

| Skill | Description |
|-------|-------------|
| [`skill_design_webview`](skill_design_webview/SKILL.md) | WebView guides: KNOWN-ISSUES, WEBVIEW-PRODUCTION-GUIDE |
| [`testing`](testing/SKILL.md) | Testing/validation procedure |
| [`troubleshooting`](troubleshooting/SKILL.md) | Note-based problem resolution (known-issues.yaml) |

## Fix skills (incremental fixes)

Solution skills obtained by resolving real bugs during development. `fix_*`
groups by problem. The agent must load them when the symptom matches
(trigger in the frontmatter `description`).

| Skill | Fixed problem | Symptoms / triggers |
|-------|----------------|-------------------|
| [`fix_windowsize`](fix_windowsize/SKILL.md) | WebView UI with correct X but short Y (vertical scroll) under Wayland/REAPER fractional scaling | WebView, app, height, vertical scroll, dpr, fractional HiDPI, scaling |

## How to add a new `fix_*` skill

1. Create the `agents/skills/fix_<name>/` folder with `SKILL.md`.
2. The `name:` in the frontmatter MUST match the folder name (`fix_windowsize`).
3. Write the `description` with **trigger terms** (keywords the agent uses to
   recognize the problem and load the skill).
4. If it's a fix that surfaced during `impl`, add a line in the TROUBLESHOOTING
   section of `impl/SKILL.md`.
5. Add a row to the `## Fix skills` table.