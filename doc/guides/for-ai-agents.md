# For AI agents

This page is for coding agents that build Flutter apps with kumo_flutter.

## Install the skills

```sh
dart run kumo_flutter:install_skill            # into .claude/skills
dart run kumo_flutter:install_skill --agents   # also add a pointer to AGENTS.md
```

This installs two skills: `kumo-flutter` (components, tokens, recipes) and `kumo-flutter-craft` (the design, accessibility, motion and copy standard, with a delivery checklist). Read both before UI work.

## Where to look

- `llms.txt`: an index of every guide and component page. `llms-full.txt`: all of them in one file.
- `doc/components/<Name>.md`: one page per component with parameters, defaults, examples and the Kumo React mapping.
- The Kumo docs at https://kumo-ui.com describe the same components for React; prop names carry over (`variant`, `size`, `open`/`onOpenChange`, `value`/`onValueChange`).

## Rules that keep output on-brand

1. Wrap the app in `KumoThemeProvider`; read colors from `context.kumo`, never hardcode hex values.
2. Content text is 14px (`KumoText`), headings are sentence case and semibold. Never bold (w700).
3. Use `KumoButton` variants: one `primary` per view, `secondary` by default, `ghost` in toolbars, `destructive` for delete.
4. Controls are controlled: hold the value in your state and pass it back.
5. Build tappable custom surfaces on `KumoPressable`.
6. Every data view has empty, loading and error states.
7. Test at 390px wide, in dark mode, and with 2x text.
