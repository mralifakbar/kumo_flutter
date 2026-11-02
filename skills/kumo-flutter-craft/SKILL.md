---
name: kumo-flutter-craft
description: |
  Craft standard for Flutter apps built with kumo_flutter: honest content, screens that reflow from phone to desktop,
  accessibility for every kind of user, fluid touch-driven motion, Kumo typography and spacing, clear copy and clean
  code comments. Use whenever you build, change or review a screen, flow or custom widget in a kumo_flutter app,
  alongside the kumo-flutter skill (which covers which component to use). Ends every UI task with the delivery checklist.
license: MIT
---

# kumo_flutter craft

The kumo-flutter skill tells you *which* component to use. This skill tells you how to make the result feel designed rather than generated: purposeful, honest, usable by everyone, and alive under the finger.

## Two modes

- **Build** (default): apply every section while you write, then run the delivery checklist before you hand anything over.
- **Review** (only when asked to audit or review): produce a numbered list of findings, each with severity (blocker, should fix, polish), the rule it breaks, `file:line` and a one-line reason. Change nothing until the user picks numbers. Fix exactly those, then re-run the checklist.

## 1. Direction before pixels

Kumo is the visual language: palette, type scale, spacing, radii and rings are decided. What the app brings is its content, its voice, and where the single accent moment lands.

Before building a screen, write one line:

> Building `<screen>` for `<who>`, so they can `<one decision or task>`. Energy `<calm|balanced|bold>`, rhythm `<uniform|mostly consistent|varied>`, motion `<feedback only|transitions|choreographed>`.

- **Energy**: how loudly the screen greets you. Kumo products are mostly calm: an operations console, a settings page, a list of resources. Reserve bold for a first-run moment.
- **Rhythm**: how much consecutive sections differ in composition.
- **Motion**: how much moves, and the reason for each movement (feedback, state change, spatial orientation). "It looks nice" is not a reason.

Hold those choices to the end of the screen. If you cannot name the user's one decision, the screen is not ready to build. If the owner has given no direction for voice or brand moments, ask one short question; if you cannot ask, build calm, uniform, feedback-only and say it is a draft.

## 2. Honesty (blocking)

- Never show numbers, statistics, uptime, prices, testimonials, names, avatars or logos that are not real data or explicitly labeled sample data. Empty is better than invented. Fake precision (`99.98%`, `4.1x faster`) is invention too.
- Placeholders say what they are: `example.com`, `my-worker`, "Sample data", "Coming soon". Never `John Doe`, never `Acme`.
- No security, compliance or performance claims without evidence the user gave you.
- Do not create logos, app icons or photos of people on assumption. Use the product name in text, initials avatars, or ask.
- Never use the Cloudflare logo or wordmark, and never imply Cloudflare made or endorsed the app.

## 3. Function and states (blocking)

- Every control does something real: navigates to a route that exists, opens and closes an overlay, toggles state, submits with feedback. Otherwise remove it, or ship it disabled with a visible "Coming soon" and a `TODO:` naming the task.
- Navigation items (sidebar, tabs, bottom navigation, menus) only point at destinations that exist.
- Every data view has three states, each saying why and what next:
  - **Loading**: `KumoSkeletonLine` shapes that match the real layout, or `KumoLoader` with text saying what is loading.
  - **Empty**: `KumoEmpty` with the reason and the one action that fills it ("No Workers yet. Create a Worker to deploy code at the edge.").
  - **Error**: what failed in plain words and how to recover (retry, check the token).
  - First run, filtered-to-nothing, offline and permission-denied are different states with different copy.
- Search never opens blank: show recent items, common destinations or a hint of what can be searched.
- Forms: label above the field (`KumoField`), helper text below, error below and announced, never a placeholder used as the label. Validate when the user leaves a field, keep the entered value on error, disable submit only while submitting (`loading: true`).
- Prefer selection over typing when the options are known (select, radio group, segmented toggle), with "Other" plus a field as the fallback.
- Status flows (deployments, jobs, orders) open with a clear status line and show progress as a timeline, not a list of dates.

## 4. Accessibility (blocking)

- **Contrast**: text at least 4.5:1, large text and UI boundaries at least 3:1. Kumo text tokens on Kumo surfaces pass; for anything custom compute it with `KumoColorUtils.contrastRatio`, never eyeball grey on grey. Text over images needs a scrim and is checked at its lightest spot.
- **Touch**: every target at least 44x44 with space between neighbours. `KumoPressable` pads Kumo's dense controls on touch platforms; keep `KumoTapTargetSize.padded` there.
- **Screen readers**: every control has a role, label and state. Icon-only buttons get `semanticLabel` or `title`. Decorative icons stay excluded. Mark page and section titles with `headingLevel`. Announce async results (live regions).
- **Keyboard**: Tab follows visual order, Enter/Space activate, Escape closes overlays, arrows move inside groups, focus is trapped in modals and restored to the trigger. Never hide the focus ring.
- **Text size**: verify at 2x. No fixed heights around text; use min heights, wrapping, and ellipsis only where the full value is reachable elsewhere.
- **Never color alone**: status pairs color with an icon or a word ("Failed", "Healthy").
- **Platform settings**: reduced motion (`KumoMotion.reduceMotion`), bold text, RTL (start/end, `EdgeInsetsDirectional`).

## 5. Layout that reflows (blocking on phones)

Kumo is designed for wide dashboards. A phone layout is its own layout, not the desktop one squeezed.

- Width classes are a starting point; place breakpoints where the content breaks. kumo_flutter switches at 768px (`context.kumoIsNarrow`) and 1024px (`KumoWindowSize`).
  - **Compact** (phones): one column, 16px gutters, `KumoBottomNavigation` for up to five primary destinations or the shell's drawer, primary action in the thumb zone (bottom third), floating panels as bottom sheets.
  - **Medium**: two columns where content has two natural groups, or a list/detail split; sidebar as an icon rail.
  - **Expanded**: persistent sidebar, content capped at a readable width (about 720px for prose, wider for tables and charts).
- No horizontal page scroll at 320px or any width between. Tables and code scroll inside their own container with a visible edge, or reflow to cards.
- Respect safe areas, the home indicator and the keyboard: a focused field is never hidden; a fixed bar never covers the last row (reserve its height).
- Fixed chrome stays compact so content dominates. Sticky headers get a bottom border.
- Size with tokens and relative constraints; let flex children shrink.

## 6. Composition and hierarchy

- **One focal point per screen**: the resource name, the failing check, the primary action. Everything else defers in size, weight and color.
- **Kumo type rules**: content text 14px; headings 16px (`heading`), 20px for the page title (`size: lg`); secondary text 13px subtle; mono 13px for IDs, hostnames, tokens. Emphasis is medium weight, headings semibold, never bold. Never change letter spacing. Headings in sentence case. At most four sizes on a screen.
- **Values over labels**: in metrics and detail rows the value is the larger, darker text; the label is subtle.
- **Spacing as structure**: related text closer together than the content around it (title and description 6px apart, the group 24px from the next). Vertical padding around text slightly smaller than horizontal. Stay on the 4px grid; one gap everywhere flattens the screen.
- **One accent**: `brand` blue belongs to the primary action and the current selection. Zero accent is sterile; accent on everything means nothing stands out.
- **One primary button per view**; `secondary` by default, `ghost` in toolbars, `destructive` for delete. One label per intent across the screen ("Deploy" everywhere, not "Deploy", "Publish" and "Ship").
- **Shapes from Kumo**: `lg` radius for controls and cards, `xl` for dialogs, full for switches and avatars. Nested shapes are concentric. Do not round everything to a pill.
- **Build from the user's decision, not a template.** Avoid the default dashboard (sidebar, four stat cards, a chart, a table) when the job is "find the failing Worker and roll it back"; build around that job. If a section exists only because "apps usually have one", cut it.
- **Vary composition by weight**: the item that needs attention can be a full-width card, the rest a list. Identical cards for unequal content hide the hierarchy. Never nest a layer card inside another.

## 7. Techniques that need a reason

Each is allowed when you can state its purpose in one line; otherwise leave it out.

- **Shadows** only on surfaces that float (menus, popovers, toasts, dialogs). Resting surfaces get a 1px ring. Never a border plus a shadow.
- **Translucency or blur** on at most one piece of chrome that content scrolls under, with a solid fallback.
- **Gradients** to encode data (chart areas) or the primary button's built-in top light. Not as backgrounds.
- **Badges and dots** only for real state (failed, paused, new since last visit). A dot that marks nothing goes.
- **Icons** chosen for meaning from `KumoIcons`. No sparkle, magic, lightning or robot glyphs as generic decoration; no emoji in UI text. Use the fill weight for active states.
- **Arrows and carets** where they signal navigation or disclosure, not on every button.
- **Illustrations** only when they explain something about this product.

## 8. Motion that answers touch

Motion answers touch. Feedback on press, springs that start from where things are, sheets that follow the finger. Nothing loops forever.

- **Respond instantly.** Feedback on pointer-down (`KumoPressable` does this). Hover colors change instantly, never animated. No artificial delays on the input path.
- **Direct manipulation.** Dragged things move 1:1 with the finger and keep the grab offset. Track velocity during the drag.
- **Interruptible always.** `AnimationController.unbounded` + `KumoMotion.springTo`, which starts from the current value and velocity. A closing sheet can be caught and pulled back without a jump. Never lock input during a transition.
- **Springs for touch.** `KumoSprings.standard` (no overshoot) by default; `KumoSprings.momentum` only when the gesture carried momentum; `KumoSprings.sheet` for sheets and drawers; `KumoSprings.popup` for things scaling from a trigger. Move X and Y with separate springs.
- **Velocity handoff and projection.** On release, pass the finger's velocity into the spring; choose the snap target from `position + KumoMotion.project(velocity)`; decide dismiss vs. return from velocity direction. Past a boundary, `KumoMotion.rubberband`.
- **Spatial consistency.** Things leave the way they came; popups grow from their trigger (`KumoAnchoredOverlay`); page transitions follow navigation direction.
- **Fixed durations** for fades and expand/collapse from `KumoDurations` (100ms Kumo default, 150ms popups, 200ms collapses, 300ms dialogs and theme fades) with `KumoCurves`. Collapsing content keeps its size while it animates.
- **Nothing loops forever.** Repetition only while a real process runs (loading), paused off screen, static under reduced motion. No idle pulses, floating elements or decorative shimmer.
- **Haptics on the causal moment** (toggle flips, a sheet snaps, a selection changes) through `kumoHaptic`, on the same frame as the visual. Not on scroll ticks, not on every button.
- **Peak and end.** Find the moment that matters (a deploy finishing, a domain going active) and give it clear, brief feedback: a toast with the result and the next action. End flows with a summary, not a blank screen.
- **Reduced motion** swaps slides, scales and springs for an instant change or a short cross-fade, keeps color and opacity changes that aid understanding.
- Animate transform and opacity; do not animate layout every frame.

## 9. Typography details

- Counters, durations, byte sizes and changing numbers use `tabularNumbers: true`; IDs, hostnames, tokens and paths use the mono variant (13px, about 0.9em of the text around it).
- Do not invent sizes or letter spacing outside the scale.
- Format numbers and dates with the user's locale, including separators.
- Truncate only where the full value is reachable (a detail page, a tooltip, a copy button).

## 10. Copy

- Labels name the action and the object: "Deploy Worker", "Add DNS record", "Purge cache", "Roll back". Not "Submit", "Get started", "Learn more". Primary labels fit on one line.
- Sentence case for titles, buttons and menu items. Product names keep their capitals.
- Errors: what happened, then what to do ("Token expired. Create a new API token and try again."). Never blame the user; never show raw exception text.
- Empty states: why it is empty, then the action.
- Confirmation only for destructive or irreversible actions; the confirm button repeats the verb ("Delete zone"). For high-stakes deletes, ask the user to type the resource name.
- No em dash character. Use a period, comma, colon or parentheses.
- No hype words: seamless, effortless, powerful, revolutionary, next-generation, cutting-edge, unlock, elevate, supercharge. Say the concrete effect.
- No announcements of what you are about to say, no chatty sign-offs, no "Honestly?" openers, no lists forced into threes, no all-caps emphasis.
- Name the actor: "We sent a verification email", not "A verification email has been sent".
- Re-read every visible string before delivery; replace anything clever that is unclear with a plain sentence.
- Keep the product's own voice when the user provides one.

## 11. Code and comments

- Public widgets get dartdoc: one sentence on purpose plus a short example. Parameters get docs only when the name does not say everything.
- Comments explain why (a platform quirk, a Kumo rule, a non-obvious constraint) in one or two lines. Never restate the code, narrate steps, add banner separators, emoji, end-of-block markers or vague TODOs.
- Build features in source. Never patch generated files or other code with scripts.
- Small composable widgets, `const` constructors, controlled inputs (`value` + `onValueChange`), tokens from `context.kumo` over literals. Create animation controllers in `initState`.

## 12. Delivery checklist

Run before handing over any UI. Report each line as PASS or FAIL with concrete evidence. Any FAIL means fix and re-run; never deliver with a FAIL.

**Blocking**
1. No invented data, people, logos or claims; sample data labeled.
2. Every control and navigation item works or is visibly marked "Coming soon".
3. Loading, empty and error states exist for every data view, each with cause and next action.
4. Contrast checked (4.5:1 text, 3:1 large text and UI); no color-only status.
5. Targets at least 44px on touch; semantics labels, roles and states present; keyboard path works; focus ring visible.
6. No overflow or clipping at 320px wide and at 2x text; safe areas and keyboard respected; medium and expanded widths have their own layout.
7. Light and dark both render correctly.
8. Ran the app (simulator, device or web) and used every control. Evidence recorded per control, for example: "Deploy -> toast with result", "empty name -> inline error", "region select on phone -> sheet, drags, flings closed".

**Purpose**
9. Shadows, blur, gradients, badges, dots, icons and arrows each have a stated reason.
10. Motion follows section 8: press feedback, instant hover, interruptible springs, velocity handoff, no endless loops, reduced motion handled.

**Craft**
11. The direction line from section 1 was written and the screen matches it.
12. One focal point, one primary action, one accent per screen; one label per intent.
13. Kumo type and spacing rules held: 14px content, sentence case, related text closer, concentric radii, no nested layer cards.
14. Copy passes section 10.
15. Comments pass section 11.
16. Swap the product name: the screen still feels like this product because of its content and decisions, not because of decoration.
