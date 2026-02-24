# PRP Commands for Dummies

## What is PRP?

**PRP = PRD + codebase intelligence + validation loop**

You give the AI a detailed plan with context and validation commands. The AI implements, tests, and self-corrects until everything passes.

---

## The Commands (New Simplified Flow)

### Core Workflow

| Command          | What it does                                    |
| ---------------- | ----------------------------------------------- |
| `/prp-prd`       | Create a PRD with implementation phases         |
| `/prp-plan`      | Create an implementation plan                   |
| `/prp-implement` | Execute a plan step-by-step with user oversight |
| `/prp-ralph`     | Autonomous loop until all validations pass      |
| `/build-with-agent-team` | Multiple agents building in parallel (Opus 4.6 only) |

### Issue & Debug Workflow

| Command                  | What it does                          |
| ------------------------ | ------------------------------------- |
| `/prp-issue-investigate` | Analyze a GitHub issue, create a plan |
| `/prp-issue-fix`         | Implement the fix                     |
| `/prp-debug`             | Deep root cause analysis (5 Whys)     |

### Git & Review

| Command       | What it does                              |
| ------------- | ----------------------------------------- |
| `/prp-commit` | Smart commit with natural language targeting |
| `/prp-pr`     | Create a pull request                     |
| `/prp-review` | Review a pull request                     |

---

## The Basic Flow

### For Big Features

```
/prp-prd "user authentication system"
    ↓
Creates PRD with phases (stored in .claude/PRPs/prds/)
    ↓
/prp-plan .claude/PRPs/prds/user-auth.prd.md
    ↓
Creates implementation plan for next phase
    ↓
Choose ONE execution path:
  /prp-implement .claude/PRPs/plans/user-auth-phase-1.plan.md   ← step-by-step
  /prp-ralph .claude/PRPs/plans/user-auth-phase-1.plan.md       ← autonomous
  /build-with-agent-team .claude/PRPs/plans/user-auth-phase-1.plan.md  ← parallel (Opus)
    ↓
Executes plan, updates PRD status, archives plan, commits per git strategy
    ↓
Repeat /prp-plan for next phase
```

### For Medium Features

Skip the PRD. Go straight to a plan:

```
/prp-plan "add pagination to the API"
    ↓
/prp-implement .claude/PRPs/plans/add-pagination.plan.md
```

### For Bug Fixes (GitHub Issues)

```
/prp-issue-investigate 123
    ↓
/prp-issue-fix 123
```

### For Debugging (Errors, Stack Traces)

```
/prp-debug "TypeError: Cannot read property 'x' of undefined"
    ↓
Creates RCA report with root cause and fix specification
```

---

## Three Ways to Execute a Plan

After creating a plan, you have three execution paths. All three share the same completion protocol: update PRD status, update Plane tracking, archive the plan, and commit per the PRD's git strategy.

### 1. Sequential (`/prp-implement`) — You Watch

```
/prp-implement .claude/PRPs/plans/my-feature.plan.md
```

Step-by-step execution. You see each task, can intervene, and approve as it goes. Best for learning or high-stakes changes.

### 2. Autonomous (`/prp-ralph`) — Go Make Coffee

```
/prp-ralph .claude/PRPs/plans/my-feature.plan.md --max-iterations 20
```

Runs in a loop:
1. Implements the plan
2. Runs all validations
3. If something fails → fixes it → re-validates
4. Keeps going until everything passes
5. Exits when done

**Cancel with:** `/prp-ralph-cancel`

### 3. Parallel (`/build-with-agent-team`) — Multiple Agents

```
/build-with-agent-team .claude/PRPs/plans/my-feature.plan.md
```

Spawns multiple agents (frontend, backend, database, etc.) that build in parallel. A lead agent coordinates contracts between them. **Requires Opus 4.6 model.**

Best for full-stack features where frontend, backend, and database work can happen simultaneously.

---

## The Git Flow

Git operations happen automatically based on the **Git Strategy** set in your PRD:

| Strategy | What happens |
|----------|-------------|
| `none` | No git operations. You manage git manually. |
| `main-only` | Commits on current branch (default). |
| `branch-per-prd` | One feature branch for the whole PRD. |
| `branch-per-phase` | Separate branch per phase. |

For manual git operations:

```
/prp-commit                    # Stage and commit with smart message
/prp-pr                        # Create pull request
/prp-review 123                # Review someone else's PR
```

---

## Where Stuff Gets Saved

```
.claude/PRPs/
├── prds/              # PRD documents
├── plans/             # Implementation plans
│   └── completed/     # Archived plans
├── reports/           # Implementation reports
├── issues/            # Issue investigations
└── reviews/           # PR reviews
```

---

## Quick Examples

### "I have a rough idea"

```bash
/prp-prd "I want users to be able to like posts"
```

This asks you clarifying questions, does research, and creates a structured PRD with phases.

### "I know what I want to build"

```bash
/prp-plan "add a like button to posts with real-time count updates"
```

Creates a detailed implementation plan with tasks and validation commands.

### "Just build it"

```bash
/prp-ralph .claude/PRPs/plans/like-button.plan.md --max-iterations 15
```

Autonomous execution until done.

### "There's a bug"

```bash
/prp-issue-investigate 456
/prp-issue-fix 456
```

### "I'm done, let's commit"

```bash
/prp-commit typescript files except tests
/prp-pr
```

---

## Tips

1. **Context is king** - The more context in your plan, the better the output
2. **Validation matters** - Plans with test commands work better than plans without
3. **Use Ralph for big stuff** - Let it iterate instead of babysitting
4. **Max iterations** - Always set `--max-iterations` on Ralph loops
5. **Start specific** - "Add OAuth2 with Google" beats "add authentication"

---

## The Old Commands

Previous commands like `/prp-base-create`, `/prp-spec-create`, `/api-contract-define`, etc. are preserved in `old-prp-commands/` for reference. The new streamlined flow replaces all of them.

---

## That's It

1. Big feature? → `/prp-prd` → `/prp-plan` → `/prp-ralph` (or `/prp-implement` or `/build-with-agent-team`)
2. Medium feature? → `/prp-plan` → pick any execution path
3. GitHub issue? → `/prp-issue-investigate` → `/prp-issue-fix`
4. Weird bug? → `/prp-debug "error message"`
5. Done? → `/prp-commit` → `/prp-pr`

Happy building.
