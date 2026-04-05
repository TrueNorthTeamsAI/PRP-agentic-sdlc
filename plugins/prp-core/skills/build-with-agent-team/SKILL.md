---
name: build-with-agent-team
description: Build a project using Claude Code Agent Teams with tmux split panes. Takes a plan document path and optional team size. Use when you want multiple agents collaborating on a build.
argument-hint: [plan-path] [num-agents]
disable-model-invocation: true
---

# Build with Agent Team

You are coordinating a build using Claude Code Agent Teams. Read the plan document, determine the right team structure, spawn teammates, and orchestrate the build.

## Arguments

- **Plan path**: `$ARGUMENTS[0]` - Path to a markdown file describing what to build
- **Team size**: `$ARGUMENTS[1]` - Number of agents (optional)

## Preconditions

Check the model that you are using. If it is NOT "claude-opus-4-6" you must STOP and exit the skill. Inform the user that agent teams can only run on claude Opes 4.6


## Step 1: Read the Plan

Read the plan document at `$ARGUMENTS[0]`. Understand:
- What are we building?
- What are the major components/layers?
- What technologies are involved?
- What are the dependencies between components?

## Step 2: Determine Team Structure

If team size is specified (`$ARGUMENTS[1]`), use that number of agents.

If NOT specified, analyze the plan and determine the optimal team size based on:
- **Number of independent components** (frontend, backend, database, infra, etc.)
- **Technology boundaries** (different languages/frameworks = different agents)
- **Parallelization potential** (what can be built simultaneously?)

**Guidelines:**
- 2 agents: Simple projects with clear frontend/backend split
- 3 agents: Full-stack apps (frontend, backend, database/infra)
- 4 agents: Complex systems with additional concerns (testing, DevOps, docs)
- 5+ agents: Large systems with many independent modules

For each agent, define:
1. **Name**: Short, descriptive (e.g., "frontend", "backend", "database")
2. **Ownership**: What files/directories they own exclusively
3. **Does NOT touch**: What's off-limits (prevents conflicts)
4. **Key responsibilities**: What they're building

## Step 3: Set Up Agent Team

Enable tmux split panes so each agent is visible:

```
teammateMode: "tmux"
```

Before spawning, enter **Delegate Mode** (Shift+Tab) to restrict yourself to coordination only. You should NOT implement code yourself.

## Step 4: Contract-First Spawning

**CRITICAL LESSON:** Agents that build in parallel WILL diverge on interfaces (endpoint URLs, response shapes, trailing slashes, data storage semantics) unless they agree on contracts FIRST. The lead must enforce a **contract-first, build-second** protocol.

### Identify the Contract Chain

Before spawning anyone, map out the interface dependency chain:

```
Database → publishes function signatures → Backend
Backend → publishes API contract → Frontend
```

Agents UPSTREAM in this chain must publish their contract BEFORE downstream agents start building. This means spawning is **staggered, not fully parallel**.

### Spawn Order

1. **Spawn upstream agents first** (e.g., database, then backend)
2. Each upstream agent's FIRST task is: define and send their contract via SendMessage
3. **Lead receives and verifies the contract** — check for ambiguities, missing details
4. **Lead forwards the verified contract to downstream agents** — do NOT rely on agents messaging each other
5. **Only then spawn or unblock downstream agents** with the contract included in their prompt

### Lead as Active Contract Relay

**Do NOT just tell agents "share your contract with the other agent."** This fails because:
- The upstream agent may finish and share too late
- The downstream agent may already be building with wrong assumptions
- Messages between agents may be missed or unclear

Instead, the lead must:
1. Receive the contract from the producing agent
2. **Verify it** — check for: exact URLs with trailing slashes, exact JSON response shapes, exact status codes, SSE event format, any envelope wrappers like `{session: {...}, messages: [...]}`
3. **Forward it to consuming agents** with explicit instructions: "Build to this contract exactly. Do not deviate."

### Identify Cross-Cutting Concerns

Some behaviors span multiple agents and WILL fall through the cracks unless explicitly assigned. Before spawning, identify these from the plan and assign ownership:

Common cross-cutting concerns:
- **Streaming data storage**: If backend streams chunks to frontend, should chunks be stored individually in the DB or accumulated into one row? (Affects how frontend renders on reload)
- **URL conventions**: Trailing slashes, path parameters, query params — both sides must match exactly
- **Response envelopes**: Flat objects vs nested wrappers — both sides must agree
- **Error shapes**: How errors are returned (status codes, error body format)
- **UI accessibility**: Interactive elements need aria-labels for automated testing

Assign each concern to ONE agent with instructions to coordinate with the other.

### Spawn Prompt Structure

```
You are the [ROLE] agent for this build.

## Your Ownership
- You own: [directories/files]
- Do NOT touch: [other agents' files]

## What You're Building
[Relevant section from plan]

## Mandatory Communication (REQUIRED)

### Before You Build
- Your FIRST deliverable is your [API contract / schema / interface]
- Send it to the lead via SendMessage BEFORE writing implementation code
- Include: exact URLs (with trailing slashes if applicable), exact request/response JSON shapes, status codes, SSE event formats
- Wait for the lead to confirm before proceeding

### The Contract You Must Conform To
[Include the upstream agent's verified contract here]

### Cross-Cutting Concerns You Own
[Explicitly list integration behaviors this agent is responsible for]

## Coordination
- Share with [other agent] when: [trigger]
- Ask [other agent] about: [dependency]
- Challenge [other agent]'s work on: [integration point]
```

## Step 5: Facilitate Collaboration

Agent teams are NOT just parallel workers. They must communicate. The lead enforces this with the contract-first protocol.

### Phase 1: Contracts (Sequential, Lead-Orchestrated)

Spawn agents in dependency order. Each agent's first task is publishing their contract:

1. **Database agent** → publishes function signatures and data shapes → lead verifies → forwards to backend
2. **Backend agent** → receives DB contract → publishes API contract (exact URLs, JSON shapes, SSE format, status codes) → lead verifies → forwards to frontend
3. **Frontend agent** → receives verified API contract → builds to match exactly

**Lead verification checklist for API contracts:**
- Are URLs exact, including trailing slashes? (e.g., `POST /api/sessions/` vs `POST /api/sessions`)
- Is the response shape explicit? (e.g., `{"session": {...}, "messages": [...]}` NOT just "returns session with messages")
- Are all SSE event types documented with exact JSON?
- Are error responses specified? (404 body, 422 body, etc.)
- Are there any streaming storage semantics to clarify? (accumulated vs per-chunk)

### Phase 2: Implementation (Parallel where safe)

Once contracts are verified, agents build in parallel. They MUST:
- Send a message to the lead when they discover something that affects the contract
- Ask before deviating from the agreed contract
- Flag cross-cutting concerns that weren't anticipated

### Phase 3: Pre-Completion Contract Verification

Before any agent reports "done", the lead runs a **contract diff**:
- "Backend: what exact curl commands test each endpoint?"
- "Frontend: what exact fetch URLs are you calling with what request bodies?"
- Lead compares and flags mismatches BEFORE integration testing

### Phase 4: Polish (Cross-Review)
Each agent reviews another's work:
- Frontend reviews Backend API usability
- Backend reviews Database query patterns
- Database reviews Frontend data access patterns

## Collaboration Anti-Patterns

**Anti-pattern 1: Fully parallel spawn** (agents diverge)
```
Lead spawns all 3 agents simultaneously
Each agent builds to their own assumptions
Integration fails on URL mismatches, response shape mismatches ❌
```

**Anti-pattern 2: Late contract sharing** (rework required)
```
Backend finishes → sends API contract to frontend
Frontend already built with wrong URLs/shapes → has to redo work ❌
```

**Anti-pattern 3: "Tell them to talk"** (they won't reliably)
```
Lead tells backend "share your contract with frontend"
Backend sends contract but frontend already built half the app ❌
```

**Good pattern: Contract-first with lead relay**
```
Backend publishes contract → Lead verifies → Lead forwards to frontend with "build to this exactly"
Frontend builds to verified contract → zero integration mismatches ✅
```

**Good pattern: Active collaboration**
```
Agent A: "Here's my API contract — Agent B, does this work for you?"
Agent B: "The response shape needs a 'metadata' field for pagination"
Agent A: "Good catch, updating now"
Agent C: "I see you need user.email — I'll add an index for that query"
```

## Task Management

Create a shared task list with dependencies:

```
[ ] Agent A: Set up project structure
[ ] Agent B: Set up project structure
[ ] Agent C: Design schema (blocks Backend)
[ ] Agent B: Implement API (blocked by Database schema)
[ ] Agent A: Build UI components
[ ] Agent A + B: Integration testing (blocked by API + UI)
```

Track progress and unblock agents when dependencies complete.

## Common Pitfalls to Prevent

1. **File conflicts**: Two agents editing the same file → Assign clear ownership
2. **Lead over-implementing**: You start coding → Stay in Delegate Mode
3. **Isolated work**: Agents don't talk → Require explicit handoffs via lead relay
4. **Vague boundaries**: "Help with backend" → Specify exact files/responsibilities
5. **Missing dependencies**: Agent B waits on Agent A forever → Track blockers actively
6. **Fully parallel spawn**: All agents start simultaneously → Interface divergence. Spawn upstream agents first, get contracts, then spawn downstream
7. **Implicit contracts**: "The API returns sessions" → Ambiguous. Require exact JSON shapes, URLs with trailing slashes, status codes
8. **Orphaned cross-cutting concerns**: Streaming storage, URL conventions, error shapes → Nobody owns them. Explicitly assign to one agent
9. **Per-chunk storage**: Backend stores each streamed text chunk as a separate DB row → Frontend renders N bubbles on reload. Accumulate chunks into single rows
10. **Hidden UI elements**: CSS `opacity-0` on interactive elements → Invisible to automation. Add aria-labels, ensure keyboard/focus visibility

## Definition of Done

The build is complete when:
1. All agents report their work is done
2. Each agent has validated their own domain
3. Integration points have been tested
4. Cross-review feedback has been addressed
5. The plan's acceptance criteria are met
6. **Lead agent has run end-to-end validation**

---

## Step 6: Validation

Validation happens at two levels: **agent-level** (each agent validates their domain) and **lead-level** (you validate the integrated system).

### Agent Validation

Before any agent reports "done", they must validate their work. When analyzing the plan, identify what validation each agent should run:

**Database agent** validates:
- Schema creates without errors
- CRUD operations work (create, read, update, delete)
- Foreign keys and cascades behave correctly
- Indexes exist for common queries

**Backend agent** validates:
- Server starts without errors
- All API endpoints respond correctly
- Request/response formats match the spec
- Error cases return proper status codes
- SSE streaming works (if applicable)

**Frontend agent** validates:
- TypeScript compiles (`tsc --noEmit`)
- Build succeeds (`npm run build`)
- Dev server starts
- Components render without console errors

When spawning agents, include their validation checklist:

```
## Before Reporting Done

Run these validations and fix any failures:
1. [specific validation command]
2. [specific validation command]
3. [manual check if needed]

Do NOT report done until all validations pass.
```

### Lead Validation (End-to-End)

After ALL agents return control to you, run end-to-end validation yourself. This catches integration issues that individual agents can't see.

**Your validation checklist:**

1. **Can the system start?**
   - Start all services (database, backend, frontend)
   - No startup errors

2. **Does the happy path work?**
   - Walk through the primary user flow
   - Each step produces expected results

3. **Do integrations connect?**
   - Frontend successfully calls backend
   - Backend successfully queries database
   - Data flows correctly through all layers

4. **Are edge cases handled?**
   - Empty states render correctly
   - Error states display user-friendly messages
   - Loading states appear during async operations

If validation fails:
- Identify which agent's domain contains the bug
- Re-spawn that agent with the specific issue
- Re-run validation after fix

### Validation in the Plan

Good plans include a **Validation** section with specific commands for each layer. When reading the plan:

1. Look for a Validation section
2. If present, use those exact commands when instructing agents
3. If absent, derive validation steps from the Acceptance Criteria

Example plan validation section:
```markdown
## Validation

### Database Validation
[specific commands to test schema and queries]

### Backend Validation
[specific commands to test API endpoints]

### Frontend Validation
[specific commands to test build and UI]

### End-to-End Validation
[full flow to run after integration]
```

---

## Step 0: Read Plan & Extract Metadata

Before team setup, extract metadata from the plan:

1. **Source PRD**: Check the plan's `## Metadata` table for `Source PRD` row. If found, read the PRD file.
2. **Git Strategy**: If a source PRD exists, read its `Git Strategy` field from the Technical Approach section. Default to `main-only` if not specified or no PRD.

---

## Execute

Now read the plan at `$ARGUMENTS[0]` and begin:

1. Read and understand the plan
2. **Extract metadata** (Step 0 above — Source PRD, git strategy)
3. Determine team size (use `$ARGUMENTS[1]` if provided, otherwise decide)
4. Define agent roles, ownership, **cross-cutting concern assignments**, and **validation requirements for each**
5. **Map the contract chain** — which agent produces interfaces that others consume?
6. Enter Delegate Mode
7. **Spawn upstream agents first** — their first task is publishing their contract
8. **Receive and verify each contract** — check for ambiguities, exact URLs, response shapes
9. **Forward verified contracts to downstream agents** — include in their spawn prompt
10. Spawn downstream agents with verified contracts + their validation checklist
11. **Run contract diff before integration** — compare backend's curl commands vs frontend's fetch URLs
12. When all agents return, run **end-to-end validation yourself** (start both servers, use agent-browser for UI testing)
13. If validation fails, re-spawn the relevant agent with the specific issue
14. Confirm the build meets the plan's requirements
15. **Run completion protocol** (Step 7 below)

---

## Step 7: Completion Protocol

After all agents are done and validation passes, run the same completion steps as `prp-implement`:

### 7.1 Update Source PRD (if applicable)

Check if the plan was generated from a PRD (try each method in order):

1. **Metadata table**: Look for `Source PRD` row in the plan's `## Metadata` table
2. **Inline reference**: Search the plan file for `Source PRD:` text anywhere
3. **PRD directory scan**: If neither found, scan `.claude/PRPs/prds/` for any `.prd.md` file whose Implementation Phases table references this plan's filename or feature name

If PRD source found:
1. Read the PRD file
2. Find the matching phase row in the Implementation Phases table
3. Update the phase: Change Status from `in-progress` to `complete`
4. Save the PRD

If no PRD source found: Log a warning: "No source PRD found — skipping PRD status update."

**Check if ALL PRD phases are now complete:**

If a PRD was found and updated, re-read the PRD's Implementation Phases table. If every phase has Status `complete`:
1. Archive the PRD to the completed folder:
   ```bash
   mkdir -p .claude/PRPs/prds/completed
   mv {prd_path} .claude/PRPs/prds/completed/
   ```
2. Log: "All PRD phases complete — PRD archived to `.claude/PRPs/prds/completed/`"

### 7.2 Archive Plan

```bash
mkdir -p .claude/PRPs/plans/completed
mv {plan_path} .claude/PRPs/plans/completed/
```

### 7.4 Git Operations

**Read git strategy from Step 0** (default `main-only` if not determined).

- **`none`**: Skip all git operations. Do not stage or commit.
- **`main-only`**: Commit on current branch and push:
  ```bash
  git add -A
  git commit -m "feat: implement {feature-name}"
  git push -u origin HEAD
  ```
- **`branch-per-prd`**: Verify on the PRD branch (`feat/{prd-name}`). If not, check it out. Then commit and push:
  ```bash
  git checkout feat/{prd-kebab-name}  # if not already on it
  git add -A
  git commit -m "feat: implement {feature-name}"
  git push -u origin HEAD
  ```
- **`branch-per-phase`**: Should already be on the phase branch (created by prp-plan). Verify, then commit and push:
  ```bash
  git add -A
  git commit -m "feat: implement {feature-name}"
  git push -u origin HEAD
  ```

Use the conventional commit type that best matches the work (feat, fix, refactor, etc.).
