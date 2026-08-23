# AI Execution Routing

Primary goal: conserve Claude usage. Cursor is the default implementation environment whenever it can reasonably do the work.

## CURSOR HANDOFF
Use Cursor for routine implementation. Before writing code, ask: **Does Claude actually need to implement this?** If not, STOP and output `CURSOR HANDOFF`, then provide a ready-to-paste Cursor prompt with the objective, relevant project context, files or directories involved, implementation requirements, constraints, acceptance criteria, tests, and verification commands. Do not continue implementing unless explicitly told to stay in Claude. When uncertain between Cursor and Claude implementation, prefer Cursor.

## CLAUDE
Reserve Claude for architecture, system design, difficult reasoning, ambiguous requirements, complex debugging and root-cause analysis, security-sensitive decisions, technical tradeoffs, planning, task decomposition, code review, and integration. Once the hard reasoning is solved, hand straightforward implementation to Cursor when practical.

## RINGER
Use Ringer when it is available in the current environment and parallel execution provides meaningful advantage. Claude owns architecture, decomposition, acceptance criteria, integration, and final review. Every Ringer task requires executable verification. If Ringer would be preferred but is unavailable, output `RINGER RECOMMENDED` and provide the task breakdown and verification plan.

## VERIFICATION
Never trust an AI worker completion claim by itself. Run the repository's relevant type checks, lint, tests, build, and end-to-end checks. Review substantial diffs. Never weaken, remove, or bypass tests simply to make verification pass.

## PRIORITY
Implementation: **Cursor first → Ringer for meaningful parallelism → Claude only when genuinely necessary.**

Reasoning: **Claude first → Cursor or Ringer for implementation → Claude final review.**

The question is not **Can Claude do this?** It is **Does Claude need to do this?**