---
name: outsystems-review
description: OutSystems-side evidence for reviews of work that ports, syncs or replaces OutSystems (O11) behaviour — read the real OS model (Service Studio MCP, read-only), the module dependency graph (Service Center via Claude in Chrome), and OS data/output (SQL tool, generated files) so parity verdicts rest on what OutSystems actually does, not on PRDs, runbooks or the developer's claim. Use inside /feature-review whenever a story has OutSystems scope (OS publishers, sync timers, OS-generated files like DataHub/MyRest XML, "copy OS exactly" parity, entity/FK mapping), or when the user asks how OS modules are layered, what depends on a module, or "check it in OutSystems / use the OS MCP".
---

# Skill: outsystems-review

OutSystems is the target: parity means copying what OS does, quirks included. Docs about OS (PRDs, field-source runbooks, ADRs, a teammate's "use the Site FK") are claims. This skill produces **receipts from OS itself** — the model, the dependency graph, and OS-produced data — and feeds them into the review's gates.

**Environment bindings come from the project, not this skill.** Read the workspace / target repo CLAUDE.md for the OS environment's Service Center and LifeTime URLs, any SQL tool, and where OS-generated files land. Concrete values below are worked examples from the reference implementation (Maxtel O11 Dev: Service Center `https://dev.maxtel.com/ServiceCenter/Home.aspx`, SQL tool `dev.maxtel.com/sql/Execute.aspx?ModuleId=2338`).

Worked example that motivated it (Maxtel ADO 4023, eventledger PR #923 report `PRPs/reports/review-ado-ayush-batch-20261023.md`): PRD, runbook and a recorded decision all said the DataHub owner came from `Site.BusinessOwner_Id`. Reading `NewPos6_CS → XML_DailyQtrHourSales → GetSiteById` showed OS joins `Site → Business → BusinessConfiguration` and takes `BusinessConfiguration.BusinessOwner_Id`. The shipped AWS design could never match; Dev files had already regressed Licensee/701218 → McOpCo.

## Hard guardrails — read first

- **Read-only, always.** Never call `omlPublish`, `omlMerge`, `omlReset`, `omlRefreshReferences`, `startOmlEditSession`, `endOmlEditSession`, or `applyModelApiCode` — the last one runs arbitrary C# with Service Studio's privileges. No exceptions without an explicit, specific instruction from the user, — reviews never change the OS estate.
- **Service Center module pages carry live buttons** — *Redeploy Published Version*, *Publish All Consumers*, per-version *Publish*, *Delete*. Never click them. Read tabs only.
- **Credentials are the user's.** Service Center / LifeTime / app logins: navigate to the login page and ask the user to sign in. Never type passwords.
- Never press "Send now" / re-send on any outbound/FTP screen to get evidence.

## The three evidence sources

| Source | Gives you | Doesn't give you | How |
|---|---|---|---|
| **Service Studio MCP** (`mcp__<server>__*`) | Exact logic of a module the user has open: actions, aggregates (sources, joins, filters), assignments, entities, timers, structures, forward references | Modules not open; reverse dependencies | below §A |
| **Service Center** (Claude in Chrome) | Per module: Producers (uses) **and Consumers (used by)**, outdated flags, last publisher, timers, site properties | Internals of any logic | below §B |
| **OS data / output** | What OS actually emitted or stored — the oracle for parity | Why | The environment's SQL tool (if the project has one), OS-generated files (e.g. an FTP admin "files sent" screen, committed fixtures with provenance), the OS app's own screens |

A parity verdict needs **model + output**: the model says how, the output proves it on real data. One without the other is PLAUSIBLE, not CONFIRMED.

## §A — Service Studio MCP (internals)

Facts (official README, github.com/OutSystems/outsystems11-mcp): embedded in Service Studio ≥ 11.55.91; started per session via **Edit → MCP Configuration → Start MCP Server** (port 41820); **there is no tool that opens a module** — the user opens it; several open modules are tracked separately; **every connection (including reconnects) needs an approval click in Service Studio**.

1. The tool prefix is whatever name the MCP server was registered under — `servicestudio` in the official setup (`mcp__servicestudio__*`), `outsystems-studio` in the reference implementation. Load tools in one ToolSearch, e.g. `select:mcp__outsystems-studio__createSessionToken,mcp__outsystems-studio__listApps,mcp__outsystems-studio__runQuery,mcp__outsystems-studio__getServerAction,mcp__outsystems-studio__getDataModel,mcp__outsystems-studio__getActionNames`.
2. `createSessionToken` **once**, with a `clientName` the user will recognise (e.g. "Claude Code — story 4023 review (read-only)"). It blocks until the user approves in Service Studio — if it runs long, tell the user to click Allow; don't re-call it. Reuse the token for the whole session.
3. `listApps`. If the module you need isn't listed, ask the user to open it (Service Studio → File → Open from environment, or LifeTime's "Open in Service Studio"). Name the exact module — find it via §B first if unsure.
4. Read:
   - Whole action: `getServerAction {eSpaceName, objectName, includeJson:"Never"}` — returns Model API C#; aggregates show `CreateSource`, `CreateJoin` + `SetCondition`, `CreateFilter`; assigns show `CreateAssignment(target, expr)`.
   - Graph queries: `runQuery` with ModelQL, e.g. `Root { Name References { Name } }`, `Root { ServerActions { Name } }`, `Root { Entities { Name Attributes { Name DataType } } }`, `Root { Timers { Name } }`.
   - `getDataModel` also shows entities reachable through references.
5. Receipt format for the report: `Module vVersion → Action → Node: <join/expression quoted verbatim>` (version from `listApps`).

## §B — Service Center (dependencies, both directions)

1. Navigate to `<env>/ServiceCenter/Home.aspx` (the bare `/ServiceCenter/` can show the login form even when signed in). If it's a login page, ask the user to sign in.
2. Top-right search → the module → `eSpace_Edit.aspx?EspaceId=N`. Note *Application*, *Last Published by*, and the *Status* line.
3. **Dependencies** tab → read with `get_page_text`: **Producers** (what it consumes) and **Consumers** (who consumes it; paginated ~100/page — use *Next*). `(outdated)` = consumer compiled against an older version.
4. What to look for in a review:
   - **Blast radius** of the OS change in the story: consumers of the module/action touched.
   - **Cycles**: a module that is both producer and consumer (Maxtel example: Access_CS ↔ NewPos6_CS / Stock_CS / AwsMaxtelSync / Auditing_CS / CommonFunctions_Lib). A sync or publisher inside a cycle can't be reasoned about as a clean layer.
   - **Layer violations** vs the 4-layer canvas: `_Lib`/extensions at the bottom, `_CS` core services, `_Roles`, end-user `_UI/_CW/_MCW`. A `_Lib` or foundation `_CS` consuming a domain `_CS` is a smell to note (advisory unless it breaks an AC).
   - Who last published the module and when — does it line up with the story's OS-side changes?

## Procedure inside a feature review

1. **Phase 0 — flag OS scope.** Any AC mentioning OS parity, OS publishers/timers, OS entities, or a file OS also generates → this skill applies. List the OS modules/actions in scope (ask Service Center if unsure which module owns an action).
2. **Find the OS source of truth** (§A): for each parity-relevant field or behaviour, read the OS logic that produces it. Quote it.
3. **Compare to the AWS implementation** (`file:line`). Mismatch in source, join path, filter, default/null handling, rounding or formatting = candidate finding.
4. **Prove on data**: OS output (SQL tool, OS-generated file, fixture with provenance) vs AWS output for the **same site/date**, across more than one tenant where the data allows. Watch for test data that was hand-set on the AWS side — it proves a code path, not parity.
5. **Grade**: a source/semantics mismatch that makes stored or emitted data differ from OS on the core path is **GATING** (verdict rule exception b). Layering/cycle/outdated observations are **ADVISORY**.
6. **Fix the record**: any PRD, runbook, ADR, rule-file comment or memory that states the wrong OS source gets named in the finding (and operator memory corrected in the same turn).
7. Report: add an "OutSystems evidence" section — receipts from §A, dependency facts from §B, the data comparison table, and the guardrail statement "read-only; nothing published".

## Gotchas

- `createSessionToken` "timing out" almost always means the approval prompt in Service Studio wasn't clicked.
- `listApps` returning `[]` = no module open in Service Studio.
- A module open with a leading `*` in its Service Studio tab has unsaved local changes — read, but don't trust it as the published version; prefer the published version number Service Center shows.
- Service Studio's open module may be newer/older than what's published on Dev — check the version against Service Center *Versions* before treating the model as what produced Dev data.
- Docs drift: field-source runbooks and PRDs have been wrong about OS joins. The model wins.
