# AGENTS.md — FrictionSales iOS App Rules

## Agent Directives & Skills
- This file (`AGENTS.md`) defines the core rules and architectural guidelines for this app.
- For strict implementation rules, coding practices, and protected code behavior, you MUST read and follow `SKILLS.md` before making any modifications to this project.
- Whenever a new task is assigned, you MUST go through `MEMORY.md` along with all other files and follow the instructions given in `MEMORY.md`. This file contains the user's personal preferences and dynamically updated self-learned rules.
## Project Identity

App name: FrictionSales  
Brand: Friction Energy Bikes  
Purpose: Backend showroom sales tracking app for electric bike sales, fleet model management, revenue analytics, model-wise performance, and historical peak detection.

## Core Technology Rules

- Always use Swift and SwiftUI.
- Use UIKit only when SwiftUI cannot reasonably provide the required UI, lifecycle behavior, or system integration.
- Prefer native Apple frameworks before adding third-party dependencies.
- Do not add external packages unless absolutely necessary and clearly justified.
- Follow Apple Human Interface Guidelines and Swift API Design Guidelines.
- Keep the app lightweight, fast, and optimized for storage, memory, and runtime performance.

## Architecture Rules

Use a clean layered architecture:

1. Domain Model Layer
   - Value-semantic models such as `Sale`, `EBikeModel`, `Timeframe`, `ModelPerformance`, and `PeakRecord`.
   - Prefer `struct` for immutable data snapshots.
   - Prefer `enum` for finite state such as timeframe filters.

2. Business Logic Layer
   - Keep analytics logic outside SwiftUI views.
   - Use a protocol-based analytics service, such as `SalesAnalyticsService`.
   - Implement calculations in a pure Swift engine, such as `LocalAnalyticsEngine`.
   - Analytics must be testable without rendering SwiftUI.

3. State & Orchestration Layer
   - Use an `ObservableObject` manager for shared app state.
   - Use `@StateObject` only at ownership/root boundaries.
   - Use `@EnvironmentObject` for dependency access across tabs.
   - Use `@State` only for local view state.

4. UI Layer
   - Use declarative SwiftUI views.
   - Keep views focused on presentation and user interaction.
   - Extract reusable components for cards, rows, forms, empty states, and analytics sections.

## Security & Safety Rules

- Validate all user input before saving or processing.
- Trim whitespace from text inputs.
- Never force unwrap optional values unless impossible by construction and clearly justified.
- Avoid unsafe casts.
- Avoid global mutable state.
- Avoid hardcoded secrets, tokens, credentials, API keys, or private data.
- Write code that is safe, deterministic, and easy to audit.
- After implementation, review all files for possible crashes, force unwraps, invalid assumptions, memory issues, or unsafe patterns.

## SwiftUI UI Rules

- Every SwiftUI screen must be responsive on iPhone standard, iPhone Plus/Max/Pro, and smaller screen sizes.
- Follow safe area rules.
- Avoid clipped content.
- Support Dynamic Type where practical.
- Use adaptive spacing, flexible frames, `ScrollView`, `List`, and `LazyVStack` where appropriate.
- Use system colors such as `systemGroupedBackground`, `secondarySystemGroupedBackground`, `.primary`, `.secondary`, and `.accentColor`.
- Do not hardcode layouts that break on different iPhone sizes.
- Every SwiftUI file must include a working `#Preview` or preview provider at the bottom.
- Previews should inject realistic mock data where needed.

## Commenting Rules

Write clear, useful comments for:

- Every public or reusable function.
- Every analytics calculation.
- Every non-obvious business rule.
- Every reusable component.
- Any complex grouping, sorting, filtering, or date logic.

Do not write noisy comments that simply repeat obvious code.

## Performance Rules

- Keep analytics calculations efficient.
- Prefer `Dictionary(grouping:by:)`, `reduce`, and sorted transformations where clean and efficient.
- Avoid nested loops where a linear grouping approach is better.
- Avoid unnecessary view recomputation where possible.
- Keep models lightweight.
- Keep app storage footprint small.
- Do not add unnecessary assets or dependencies.

## Quality Gate Before Final Answer

Before finishing any coding task:

1. Check that the app builds.
2. Check every Swift file for syntax errors.
3. Check all previews compile.
4. Check there are no unnecessary UIKit imports.
5. Check there are no force unwraps.
6. Check user input validation.
7. Check safe area and responsive layout.
8. Check naming consistency.
9. Check comments are clear and useful.
10. Summarize what was built and what files changed.

## App Design Direction

The UI should closely follow the attached reference screenshots:

- Premium iOS dashboard style.
- Clean cards.
- Rounded corners.
- Modern spacing.
- Showroom/business analytics feel.
- Native Apple visual language.
- Clear typography hierarchy.
- Professional, minimal, high-trust interface.

Do not create a childish or toy-like UI. This is an internal business tool for a real electric bike showroom.
