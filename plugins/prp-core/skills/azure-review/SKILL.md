---
name: azure-review
description: Sync feature-review outcomes onto the Azure DevOps board — map each reviewed story to its verdict, move passed stories to Ready for Test, send failed/split-verdict stories back to In Development, and leave an evidence comment with GitHub issue links on every move. Use after a /feature-review completes (its Phase 7 close-out), or when the user asks to "update the board", "move the story", "look at the peer review column", or reconcile ADO with review results. Works via Claude in Chrome on the user's logged-in session.
---

# Skill: azure-review

Push the outcome of a completed feature review onto the client's Azure DevOps board. This is the board-sync half of the review workflow: `feature-review` produces verdicts + GitHub issues; this skill turns them into story moves with evidence comments. Never run it before the review's findings and issues exist — the comments must cite them.

## Project bindings — from the target repo's CLAUDE.md, never assumed

This skill is project-agnostic. Before touching the board, resolve these from the project's CLAUDE.md (its Issue Tracking section or equivalent) or by asking the user:

- **ADO org / project / team board** — e.g. `dev.azure.com/<org>/<project>` → Boards → `<team> / Stories`. ADO is typically the client's source of truth for story state.
- **Sprint-filtered board URL pattern** (adjust sprint numbers as they roll), e.g.
  `https://dev.azure.com/<org>/<project>/_boards/board/t/<team>/Stories?System.IterationPath=<project>%5CSprint%20NN%2C...`
- **Column ↔ State mapping.** On most boards the columns ARE the State field (e.g. `New, In Design, In Refinement, Ready For Sprint, In Development, Requires Peer Review, Blocked, Ready for Test, In QA Testing`, + downstream). Moving a card = changing State on the work item form. Confirm the actual state names on the live board before moving anything.
- **Access route:** Claude in Chrome on whichever Chrome profile holds the operator's ADO session (confirm via `list_connected_browsers`). If no az CLI/PAT is configured, don't attempt the REST API without asking.

## Operator identity — resolve it, don't assume it

This skill is not bound to one person. Before any mention-check or comment:

1. **Establish who is operating.** If the session doesn't already know (memory, user email in context), **ask for their name** via AskUserQuestion — don't guess and don't default to a previous operator.
2. **Verify against the signed-in ADO account**: the avatar/initials at top-right of dev.azure.com is who comments will be posted as, and `_workitems/mentioned/` shows *that account's* mentions. If the signed-in account ≠ the stated operator, say so before posting anything — comments will carry the wrong name.
3. **"Am I tagged?" checks** use `https://dev.azure.com/<org>/<project>/_workitems/mentioned/` (account-relative) plus the story's own Discussion; search the Discussion for the operator's display name, not a hard-coded one.
4. When the review was executed by Claude on the operator's behalf, the evidence comment reads naturally as the operator's — that's fine (their account, their review sign-off) — but never post from an account the operator hasn't confirmed is theirs.

## Verdict → move mapping (pilot rubric)

| Review outcome | Board action |
|---|---|
| PASSED — feature-brief/PRD ACs verified + data correctness held (deployed evidence in hand) | → **Ready for Test** |
| FAILED or SPLIT — any flagged issue on the story unresolved, or an AC broken | → **In Development** (never leave it parked in Peer Review) |
| Not reviewed (merged after the review pin, or out of scope) | **Leave untouched**; name it to the user as the next review candidate |
| Follow-up findings that do NOT block the story (filed as GitHub issues) | Story still moves forward; the comment carries the issue links |

Severity ≠ story-blocking: fix-now GitHub issues (data-correctness follow-ups) don't hold a story back if its own ACs passed — they ride in the comment.

## The move procedure (reliable mechanics, learned the hard way)

1. **Open the board** at the sprint-filtered URL; screenshot; read the **Requires Peer Review** column. Map every card to a review verdict BEFORE moving anything; report the mapping to the user if they haven't already approved it.
2. **Open each work item deterministically** — append `&workitem=<id>` to the board URL and navigate. (Board-card context menus and double-clicks are flaky; the URL always works.)
3. **Change State:** click the State value (top-left of the form) to open the combobox → use `find` ("<target state> option in the open State dropdown list") and click **by ref**, not coordinates — the list position shifts between renders.
4. **Leave the evidence comment** (find "discussion comment input box", click by ref, type). Structure: `Peer review PASSED/outcome (date): <what was verified, with the oracle numbers> — <follow-ups as GitHub links> — Moving to <state>.` For send-backs: give the split verdict per flagged issue, the receipts, and an **explicit exit gate** (what must be true to re-enter review).
5. **Save the comment with its own Save button first** (find it — "Save button for the discussion comment, not Save and Close"), THEN **Save and Close**. Save-and-Close alone can drop an unsaved comment.
6. **Verify on the board** — screenshot after each move; the column counters (e.g. "Ready To Test 4/5") confirm the move landed.

## Gotchas

- **`#NNN` in ADO comments links AZURE work items**, not GitHub. Always write GitHub references as `GitHub #264` / `GitHub issue #264`, never bare `#264`.
- The State combobox click needs the **value text**, not the label "State"; if the dropdown doesn't open, re-click precisely on the current value.
- Cards can sit in a sprint but belong to another team/owner — only move stories the review actually covered.
- Include **QA-relevant data caveats** in the comment when known (e.g. "Dev dates X..Y are double-booked until GitHub #268 is repaired — pick test dates outside that window"). QA reads the story comment, not the GitHub tracker.
- One story can carry multiple flagged issues with different outcomes — a story whose issues split pass/fail is a send-back with both halves documented, not a pass.

## Composition with feature-review

Run as the final step of feature-review Phase 7 (close-out), after the GitHub issues exist:
review verdicts → GitHub issues filed → **azure-review** moves the stories → memory updated with story numbers + moves. When the user says "review X and update the board", chain the two skills in that order.
