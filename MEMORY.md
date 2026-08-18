# MEMORY.md

This file serves as a dynamic memory bank for agent instructions, user preferences, and learnings from previous tasks and mistakes. 

Whenever a new task is assigned, agents **MUST** read and follow the rules listed below. Additionally, agents must update this file with new learnings or corrections provided by the user.

## Core Preferences & Learnings
1. **Always read `AGENTS.md`:** Always start any task by going through all the rules and guidelines mentioned in `AGENTS.md` for this app before writing any code.
2. **Adhere to System Design:** Strictly adhere to the app's established system design. If the user mentions something is "not in system design", immediately correct the implementation to match the intended premium iOS dashboard style.
3. **Light Mode Only:** Never implement any new UI changes or modify tasks in dark mode. Focus all UI implementations strictly on light mode.
