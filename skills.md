# AGENTS.md — iOS App Safe Development Rules

## Purpose

This file defines the mandatory rules for any AI coding tool, agent, assistant, or developer working on this iOS app.

This app was already created using Codex. Any new tool must treat the existing project as protected production code.

The main goal is simple:

> **Do not break the app. Do not change existing code unless absolutely necessary. Do not change UI unless specifically requested.**

---

## 1. First Rule: Read This File Before Coding

Before doing any work, the agent must read and follow this file completely.

The agent must not start modifying files without understanding these rules.

These rules apply to:

- Codex
- ChatGPT Work
- Cursor
- Windsurf
- Claude Code
- Any other AI coding tool
- Any human developer working on this project

---

## 2. Existing Code Protection Rule

The agent must not change the existing code unnecessarily.

### Required behavior

- Do not change even a single line of existing code unless the request requires it.
- Do not rewrite working code.
- Do not clean up code without permission.
- Do not refactor code without permission.
- Do not rename variables, functions, structs, classes, enums, files, folders, or assets unless explicitly requested.
- Do not move files unless explicitly requested.
- Do not change app architecture unless explicitly requested.
- Do not change unrelated logic while implementing a new feature.
- Do not improve code just because it looks improvable.

### Correct behavior

If a new feature or logic is requested:

- Inspect only the relevant files.
- Understand the existing implementation.
- Change only the necessary logic.
- Keep all unrelated code untouched.
- Preserve the original structure, style, and behavior.

---

## 3. UI Protection Rule

The agent must not change the UI unless the user specifically asks for a UI change.

### Do not change UI items such as:

- Layout
- Spacing
- Padding
- Margins
- Colors
- Fonts
- Font size
- Font weight
- Font style
- Icons
- Images
- Shadows
- Corner radius
- Animations
- Navigation style
- Tab bar style
- Button style
- Card style
- Backgrounds
- Safe area behavior
- Screen structure

### If the user asks for a specific UI change

Only change the exact requested UI property.

#### Example

If the user says:

> Change only the font weight of the title to bold.

Then only change the font weight.

Do not change:

- Font size
- Font color
- Font family
- Text alignment
- Spacing
- Padding
- Layout
- Any other style

---

## 4. No Unrequested Features Rule

The agent must not add new features unless the user asks for them.

### Forbidden behavior

- Do not add extra screens.
- Do not add extra buttons.
- Do not add extra animations.
- Do not add extra settings.
- Do not add extra models.
- Do not add extra services.
- Do not add analytics.
- Do not add onboarding logic.
- Do not add authentication.
- Do not add networking.
- Do not add persistence.
- Do not add package dependencies.

Only implement what the user requested.

---

## 5. Permission Before Development Rule

Before changing code, the agent must explain the planned work and ask for approval.

The agent must not start development immediately unless the user has clearly already approved implementation.

### Before coding, the agent must explain:

- What the user requested
- Which files need to be inspected
- Which files may be changed
- What exact code or logic may be changed
- What will not be changed
- Whether UI will be touched or preserved
- Possible risk level
- Whether new files are needed
- Whether new dependencies are needed

### Required approval

The agent must wait for the user to say something like:

> Approved. Continue.

or:

> Yes, implement it.

or:

> Go ahead.

Without approval, the agent must not modify files.

---

## 6. Before-Development Response Template

Before implementing, the agent must respond in this format:

```markdown
## Planned Change Review

### Request understood
I understand that you want to: [clear summary of the request]

### Files I need to inspect
- [file name or folder]
- [file name or folder]

### Files I may need to change
- [file name] — [reason]
- [file name] — [reason]

### What I will change
- [specific change 1]
- [specific change 2]

### What I will not change
- I will not change unrelated code.
- I will not change UI unless requested.
- I will not change app architecture.
- I will not rename existing files or symbols.
- I will not add unnecessary new code.
- I will not add new dependencies without approval.

### Risk level
Low / Medium / High

### Permission needed
Please confirm with: “Approved. Continue.”
```

---

## 7. Minimum Change Rule

Every implementation must use the smallest possible change.

### Required behavior

- Change only the required lines.
- Edit only the required files.
- Reuse existing code where possible.
- Reuse existing components where possible.
- Reuse existing models where possible.
- Reuse existing managers or services where possible.
- Avoid duplicate logic.
- Avoid unnecessary abstractions.
- Avoid unnecessary helper files.
- Avoid full-file rewrites.

### Important

The agent must not do this:

> “I also improved the structure while implementing the feature.”

The agent may only improve unrelated structure if the user specifically asks for a refactor.

---

## 8. Naming Convention Rule

Before adding new code, the agent must understand the project’s existing naming conventions.

The agent must inspect how the project names:

- Views
- ViewModels
- Models
- Services
- Managers
- Enums
- Functions
- Variables
- Constants
- Extensions
- Assets
- Preview data
- Mock data

### Required behavior

Follow the existing style exactly.

If the project uses names like:

```swift
SalesManager
HistoryTabView
AddSaleFormView
LocalAnalyticsEngine
```

Then new names must follow the same style.

Do not introduce inconsistent names like:

```swift
sales_handler
HistoryScreenNew
AddSaleModalComponent
AnalyticsServiceImpl2
```

---

## 9. Commenting Rule

The agent must follow the project’s existing commenting style.

### Required behavior

Before writing new comments, inspect existing comments.

If the project uses simple comments, write simple comments.

If the project uses section comments, follow the same style.

If the project has very few comments, do not over-comment.

### Comment new code only when useful

Add comments when they explain:

- Why new logic exists
- Why a condition is needed
- What a new feature does
- Why a safety check is required
- How the new logic connects to existing behavior

### Bad comment

```swift
// Creates a VStack
VStack {
}
```

### Good comment

```swift
// Keeps the selected item available after validation so the form does not reset unexpectedly.
```

---

## 10. SwiftUI Rule

This is an iOS SwiftUI app. The agent must preserve SwiftUI patterns.

### Required behavior

- Do not use UIKit unless SwiftUI cannot solve the requirement.
- Do not replace SwiftUI views with UIKit views.
- Do not change `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, or `@Observable` usage without understanding the existing data flow.
- Do not change navigation structure unless required.
- Do not change lifecycle behavior without permission.
- Do not create global state unless necessary and approved.
- Do not remove SwiftUI previews.
- Do not break Xcode previews.

### UIKit exception

UIKit may be used only if:

1. SwiftUI cannot reasonably handle the requirement.
2. The agent explains why UIKit is needed.
3. The user approves it.

---

## 11. Xcode Preview Rule

If the project uses Xcode previews, every new SwiftUI view must include a preview.

### Required behavior

- Follow the existing preview format.
- Use existing mock data style.
- Do not delete old previews.
- Do not break preview dependencies.
- Do not connect previews to live APIs.
- Do not connect previews to production services.
- Do not add preview-only logic into production code unless clearly separated.

---

## 12. Major Revamp Rule

If the user asks for a major revamp, redesign, rebuild, or architecture change, the agent must first understand the complete app.

Before implementing a major change, inspect:

- Project structure
- Every relevant Swift file
- Every relevant View
- Every ViewModel
- Every Model
- Every Service
- Every Manager
- Every asset dependency
- Every preview dependency
- Navigation flow
- State management flow
- Existing naming conventions
- Existing comments
- Existing app architecture

### Required process for major changes

1. Read and understand the full project area.
2. Summarize the current architecture.
3. Identify impacted files.
4. Explain the implementation plan.
5. Explain the risk.
6. Ask for approval.
7. Implement only after approval.
8. Validate the build and app safety.

The agent must not begin a major revamp with partial knowledge.

---

## 13. File Creation Rule

The agent must not create new files unless necessary.

Before creating a new file, the agent must explain:

- File name
- File location
- Purpose of the file
- Why an existing file cannot be used
- What code will be added inside it

The user must approve file creation before the file is created.

---

## 14. File Deletion Rule

The agent must never delete files unless explicitly requested.

Protected files include:

- Swift files
- Asset catalogs
- Preview files
- Config files
- Project files
- Package files
- Test files
- Documentation files
- Generated files
- Any file required by Xcode

If file deletion is requested, the agent must first explain the risk.

---

## 15. Dependency Protection Rule

The agent must not add new packages, SDKs, frameworks, or dependencies without permission.

Before adding a dependency, explain:

- Why the dependency is needed
- Why existing code cannot solve the request
- What package or SDK will be added
- What risk it creates
- Whether it affects app size
- Whether it affects privacy
- Whether it affects build time

The user must approve before any dependency is added.

---

## 16. Asset Protection Rule

The agent must not rename, remove, replace, or reorganize assets unless specifically requested.

Protected assets include:

- Images
- App icons
- Launch screen assets
- Color assets
- Font files
- JSON files
- Local data files
- Preview assets
- SF Symbol usage
- Design-system assets

If a new asset is required, the agent must ask permission first.

---

## 17. Data Model Protection Rule

The agent must not change existing data models unless required by the request.

Protected model items include:

- Struct properties
- Class properties
- Enum cases
- Codable keys
- Identifiable IDs
- Initializers
- Persistence models
- API response models
- Mock data models

If a model must change, the agent must explain:

- Which model changes
- Why it changes
- Which files depend on it
- Whether fallback logic is needed
- Whether migration is needed

---

## 18. State Management Rule

The agent must preserve the existing state management approach.

### Required behavior

If the project uses `ObservableObject`, continue using that style.

If the project uses `@Observable`, continue using that style.

If the project uses local `@State`, do not convert it to global state unless necessary.

If the project uses managers or services, follow the existing manager/service structure.

Do not introduce a new state architecture without approval.

---

## 19. Navigation Rule

The agent must not modify navigation unless required.

Protected navigation areas include:

- App entry flow
- Root view
- Tab structure
- NavigationStack
- Sheets
- Full-screen covers
- Back navigation
- Onboarding flow
- Authentication flow
- Deep links

If a new screen is required, connect it using the smallest safe navigation change.

Do not redesign navigation unless explicitly requested.

---

## 20. Bug Fix Rule

When fixing a bug, the agent must fix only the root cause.

### Required process

1. Understand the bug.
2. Find the smallest root cause.
3. Fix only the required code.
4. Do not change UI unless the bug is UI-related.
5. Do not change unrelated logic.
6. Do not rewrite the full feature.
7. Explain the fix clearly.

---

## 21. Feature Implementation Rule

When implementing a new feature, the agent must follow this order:

1. Understand the current feature area.
2. Find existing reusable code.
3. Follow existing naming conventions.
4. Follow existing UI patterns.
5. Add the smallest required logic.
6. Add comments only where helpful.
7. Add or update previews if required.
8. Check for compile risks.
9. Check for crash risks.
10. Summarize exactly what changed.

---

## 22. Refactor Rule

Refactoring is forbidden unless the user explicitly asks for it.

If refactoring is requested, the agent must:

1. Explain the current structure.
2. Explain the refactor plan.
3. List affected files.
4. Explain the risk.
5. Ask for approval.
6. Preserve behavior exactly.
7. Avoid UI changes unless requested.
8. Validate the app after changes.

---

## 23. Formatting Rule

The agent must not auto-format entire files unless necessary.

### Required behavior

- Format only edited lines.
- Preserve existing spacing style.
- Preserve existing import order unless a new import is required.
- Preserve existing file organization.
- Do not reorder properties.
- Do not reorder methods.
- Do not reorder extensions.
- Do not reorder views.

---

## 24. Build Safety Rule

After changes, the agent must check for build and crash risks.

### Required checks

Check for:

- Missing imports
- Broken references
- Deleted symbols still being used
- Incorrect access control
- Optional force unwraps
- Unsafe array indexing
- Invalid asset names
- Invalid color names
- Broken preview data
- Broken navigation links
- Broken bindings
- Broken environment objects
- Broken initializer arguments
- Compilation errors
- Runtime crash risks

### Avoid unsafe Swift

Avoid using:

```swift
!
try!
as!
fatalError()
```

These are allowed only if already used by the project pattern or clearly justified.

---

## 25. Security and Privacy Rule

The agent must not introduce insecure code.

### Forbidden

- Hardcoded API keys
- Hardcoded tokens
- Hardcoded passwords
- Logging sensitive user data
- Sending user data to unknown services
- Adding analytics without permission
- Adding tracking SDKs without permission
- Disabling App Transport Security without permission
- Weak storage of private data

Sensitive data should use secure storage patterns such as Keychain when appropriate.

---

## 26. Error Handling Rule

The agent must not add fragile logic.

Use safe error handling for:

- Network calls
- JSON decoding
- Persistence
- Optional values
- User input
- Empty states
- Loading states
- Failed operations

Avoid silent failures.

Avoid force unwraps.

Avoid crash-prone assumptions.

---

## 27. Performance Rule

The agent must avoid performance problems.

### Required behavior

- Do not add heavy work inside SwiftUI `body`.
- Do not trigger unnecessary re-renders.
- Do not load large assets synchronously.
- Do not block the main thread.
- Do not repeatedly compute expensive values inside views.
- Move expensive calculations into existing services or managers when appropriate.

---

## 28. Accessibility Rule

The agent must not break accessibility.

Preserve or add accessibility support where needed:

- Accessibility labels
- Dynamic Type support
- Proper contrast
- Button tap targets
- VoiceOver clarity
- Meaningful labels for icons
- Text that does not get clipped
- Clear error messages

Do not reduce accessibility quality while changing UI.

---

## 29. Localization Rule

The agent must follow the existing localization style.

If the project uses localization files, add new user-facing text using the same localization pattern.

If the project does not use localization, follow the existing text style.

Do not introduce a new localization system unless requested.

---

## 30. App Store Safety Rule

The agent must not add behavior that may cause App Store review issues.

Avoid adding:

- Private APIs
- Hidden tracking
- Unclear permission prompts
- Background behavior without user value
- Insecure authentication
- Misleading subscription logic
- Unsupported payment logic
- Data collection without explanation

Any permission-related feature must clearly explain why the permission is needed.

---

## 31. Testing Rule

If the project has tests, preserve them.

### Required behavior

- Do not delete existing tests.
- Do not weaken existing tests.
- Do not skip failing tests without permission.
- Do not change test expectations unless behavior intentionally changed.
- Add tests only when the new logic requires it and the project already supports tests.

---

## 32. Strict No-Touch Areas

Unless the user specifically asks, do not modify:

- App entry point
- Root navigation
- Global theme
- Design system
- Asset catalog
- Package dependencies
- Project settings
- Bundle identifier
- Deployment target
- Signing settings
- Entitlements
- Info.plist
- Launch screen
- Existing previews
- Existing mock data
- Existing models
- Existing analytics
- Existing persistence layer
- Existing networking layer

---

## 33. Emergency Stop Rule

If the agent is unsure about the impact of a change, it must stop and ask before editing.

Stop immediately if:

- A requested change affects many files.
- A requested change may break navigation.
- A requested change requires model changes.
- A requested change requires dependency changes.
- A requested change requires project setting changes.
- Existing code behavior is unclear.
- The app architecture is not understood.
- The change may break previews.
- The change may break builds.
- The change may cause app crashes.

---

## 34. After-Development Summary Template

After implementation, the agent must summarize changes using this format:

```markdown
## Implementation Summary

### Files changed
- [file name]
- [file name]

### What changed
- [specific change 1]
- [specific change 2]

### What was preserved
- Existing UI was preserved.
- Existing architecture was preserved.
- Existing naming conventions were preserved.
- Unrelated files were untouched.
- No unnecessary dependencies were added.

### Validation
- Checked for compile risks.
- Checked for crash risks.
- Checked previews where relevant.
- Checked that no unrelated UI changed.

### Notes
[Any important notes or limitations]
```

---

## 35. Golden Rule

When in doubt:

> **Do less, not more.**

The correct implementation is the smallest safe change that satisfies the user’s exact request.

Do not improve unrelated code.

Do not redesign unrelated UI.

Do not refactor unrelated architecture.

Do not rename unrelated symbols.

Do not touch unrelated files.

---

## 36. Final Instruction for All Agents

Every AI tool working on this iOS app must follow this order:

1. Read this `AGENTS.md` file first.
2. Understand the user request exactly.
3. Inspect only relevant files first.
4. Prepare a change plan.
5. Ask for user approval.
6. Implement only after approval.
7. Make the smallest possible change.
8. Preserve existing UI unless UI change is requested.
9. Preserve naming, comments, architecture, and style.
10. Validate the app for build and crash risks.
11. Summarize the exact changes made.

This project must always be treated as a protected production iOS app.
