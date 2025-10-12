# Complete State Flow with Decision Points

1. create-issue
   └─> DECISION: implementable?
   ├─> NO: request-clarification → wait → goto 1
   └─> YES: continue

2. implement
   └─> DECISION: can make progress?
   ├─> NO: request-clarification → wait → goto 2
   ├─> BLOCKED: wrong-issue → redefine-issue → goto 1
   └─> YES: continue

3. implementation-done
   └─> trigger review

4. review-code
   └─> DECISION: quality check
   ├─> FAIL: provide-feedback → goto 2
   ├─> INCOMPLETE: provide-feedback → goto 2
   ├─> WRONG_APPROACH: redefine-issue → goto 1
   └─> PASS: continue

5. review-tests
   └─> DECISION: tests pass?
   ├─> FAIL: provide-feedback → goto 2
   ├─> MISSING: provide-feedback → goto 2
   └─> PASS: continue

6. create-pr
   └─> PR created, enter PR lifecycle

7. pr-ci-check
   └─> DECISION: CI status
   ├─> FAIL: goto 8
   └─> PASS: continue

8. pr-needs-changes
   └─> implement-changes → review-changes → goto 7

9. pr-review-comments
   └─> DECISION: actionable?
   ├─> YES: goto 8
   └─> NO: request-clarification → wait

10. pr-sync-check
    └─> DECISION: needs sync with main?
    ├─> YES: goto 11
    └─> NO: continue

11. pr-sync
    └─> DECISION: conflicts?
    ├─> YES: resolve-conflicts (human?) → goto 11
    └─> NO: goto 7 (recheck CI)

12. pr-approved
    └─> DECISION: all checks pass?
    ├─> NO: goto 10
    └─> YES: continue

13. pr-merge
    └─> DECISION: merge clean?
    ├─> NO: goto 11
    └─> YES: continue

14. cleanup
    └─> done

Key Insights

Hidden Complexity:

1. Multiple review loops - could cycle 2→4→5→2 many times
   exactly like real development and workflow
2. PR can regress - passing CI can start failing (main moved)
   just as in real life
3. Context shifts - implementation agent ≠ fix agent (PR has new context: comments, CI logs)
   at all this points we just need to go back and restart the chain again - we iterate
4. Sync timing - when to sync? Before review? After approval? On conflict only?
   always? when problem -> ask human
5. Human intervention points - conflicts, clarifications, scope changes
   _always_ a human / me is there. we have github workflows for the 100% automated things which we keep out of context

Decision Point Types:

Automated (agent decides):

- Can implement?
- Tests pass?
- Code quality OK?

Detected (system decides):

- CI status
- Merge conflicts
- Approval status

Human-triggered:

- Scope change
- Clarification needed
- Manual approval
- Review/Approval/Last Word to next step

Context Transformations:

- Issue → Implementation: issue description + links
- Implementation → Review: code diff + issue requirements
- Review → PR: review feedback + code + issue
- PR → Fixes: PR comments + CI logs + review feedback + original issue
- Sync → Resolution: conflict markers + main changes + PR changes

Missing from Simple Flow:

- Draft PR stage? - create PR early for CI feedback
- Stale PR handling - too many sync conflicts, recreate?
- Parallel PRs - multiple issues in flight
- Rollback - PR merged but causes issues
- Priority changes - urgent issue interrupts current work

Questions:

1. Should review happen before PR or use draft PR for early feedback?
   we have just finished the "issue"-review so these two are probably the same in concept? should we call the issue-changes for draft PR instead?
2. Sync cadence - sync on every main commit, or only when PR is approved?
   on approved it is only merge -> commit to main left?
3. Review crew re-run - after addressing comments, full review or just delta?
   not only full review - they also take into consideration the 50+ projects/repos that have dependencies on the one being changed
4. Clarification loops - who answers? Original issue creator or user directly?
   both / original issue creator / orchestrator will answer with users approval
5. Abort conditions - when is an issue/PR abandoned?
   when there is a reason to abort/abandon
