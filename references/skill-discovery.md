# Skill Discovery Protocol

## Overview

VBW discovers installed Claude Code skills, analyzes the project stack, suggests relevant skills from a curated mapping, and maintains a persistent capability map in `.planning/STATE.md`. This protocol is the single source of truth for how skills are discovered, suggested, and tracked across all VBW commands and agents.

Skill behavior is controlled by two config settings:
- `skill_suggestions` (default: true) -- controls whether skills are suggested during init and planning
- `auto_install_skills` (default: false) -- controls whether suggested skills are auto-installed without prompting

## Discovery Protocol

**(SKIL-01)** Scan for installed skills in three locations, in order:

### 1. Global skills

Scan `~/.claude/skills/` for directories containing skill definitions (e.g., SKILL.md or similar). Each directory name is a skill identifier (e.g., `nextjs-skill`, `testing-skill`). Record each as scope: `global`.

### 2. Project skills

Scan `.claude/skills/` in the project root for project-scoped skills. These override or supplement global skills. Record each as scope: `project`.

### 3. MCP tools

Check `.claude/mcp.json` (if it exists) for configured MCP servers. Each server name represents an available tool capability. Record each as scope: `mcp`.

### Skill record format

For each discovered skill, record:
- **name:** The directory name or server name (e.g., `nextjs-skill`)
- **scope:** One of `global`, `project`, or `mcp`
- **path:** Full path to the skill directory or MCP config entry

## Stack Detection Protocol

**(SKIL-02)** Analyze the project to determine its technology stack and recommend relevant skills.

### Procedure

1. Read `${CLAUDE_PLUGIN_ROOT}/config/stack-mappings.json` for the mapping table.
2. For each category (`frameworks`, `testing`, `services`, `quality`, `devops`):
   - For each entry's `detect` array:
     - **File-based pattern** (e.g., `next.config.js`): Check if the file exists using Glob.
     - **Dependency-based pattern** (e.g., `package.json:react`): Split on `:` to get the manifest filename and dependency name. Read the manifest file and check if the dependency string appears in the content (in `dependencies` or `devDependencies` for `package.json`, in requirements for `requirements.txt`, etc.).
3. Collect all matched entries with their `skills` arrays and `description` fields.

### Output

A list of matched stack entries:
```
{ category, entry_name, description, recommended_skills[] }
```

## Suggestion Protocol

**(SKIL-03, SKIL-04)** Compare detected stack skills against installed skills to generate suggestions.

### Procedure

1. Flatten all `recommended_skills` from stack detection into a unique set.
2. Flatten all installed skill names from the discovery step into a unique set.
3. Skills that are recommended but NOT installed become suggestions.
4. Read `skill_suggestions` from `.planning/config.json`:
   - If `false`: skip suggestion display entirely. End here.
5. Read `auto_install_skills` from `.planning/config.json`:
   - If `true`: for each suggested skill, run `npx @anthropic-ai/claude-code skills add {skill-name}` without prompting. Display result (success or failure) for each.
   - If `false` (default): display suggestions in a formatted list and let the user decide. Show the installation command for each:
     ```
     npx @anthropic-ai/claude-code skills add {skill-name}
     ```

## Capability Map

**(SKIL-05)** The capability map is a persistent section in `.planning/STATE.md` under `### Skills`. It is written during `/vbw:init` and refreshed when `/vbw:plan` reads it.

### Format

```markdown
### Skills

**Installed:**
- {skill-name} ({scope})
- ...
(or "None detected" if no skills found)

**Suggested (not installed):**
- {skill-name} -- recommended for {detected-stack-item}
- ...
(or "None" if all recommended skills are installed)

**Stack detected:** {comma-separated list of detected frameworks/tools}
```

This section is read by Lead, Dev, and QA agents during their respective protocols to make skill-aware decisions.

## Agent Usage

Each agent type consumes the capability map differently. Detailed protocols live in the respective agent `.md` files; this is a summary.

- **Lead:** References installed skills in plan context sections. When creating plans, the Lead notes which installed skills are relevant to each task. If a recommended skill is not installed, the Lead may suggest it in the plan objective.
- **Dev:** Before executing a task, the Dev checks the capability map for relevant installed skills (e.g., `testing-skill` for test tasks, `nextjs-skill` for Next.js work). Installed skills inform implementation approach and best practices.
- **QA:** Checks for quality-related skills (`linting-skill`, `security-audit`, `a11y-check`) to augment verification. When a quality skill is installed, QA incorporates its checks into the verification pass.

## Config Settings

**(SKIL-10)** Two settings in `.planning/config.json` control skill behavior:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `skill_suggestions` | boolean | `true` | Controls whether skills are suggested during init and planning. When false, skill discovery still runs (for the capability map) but suggestions are not displayed. |
| `auto_install_skills` | boolean | `false` | Controls whether suggested skills are auto-installed. When true, runs the install command automatically. When false, displays suggestions for user to act on. |

Both settings are defined in `config/defaults.json` and documented in `commands/config.md` Settings Reference. No changes to those files are needed for this protocol.
