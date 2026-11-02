# KumoLink

A styled text link: link blue with a soft underline, or inheriting the surrounding color, or plain. Flutter has no `href`, so navigation happens in `onPress`.

Kumo reference: https://kumo-ui.com/components/link

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoLink(label: 'View deployment logs', onPress: () => Navigator.of(context).pushNamed('/logs'))
```

## When to use / when not to

Use a link to go somewhere: another page, a document, an external site. Use `KumoButton` for actions that change something (deploy, delete, save).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | |
| `onPress` | `VoidCallback?` | required | Navigates. Null shows inactive text |
| `variant` | `KumoLinkVariant` | `inline` | `inline`, `current` or `plain` |
| `external` | `bool` | `false` | Adds the arrow-in-box icon and the `externalHint` |
| `size` | `KumoTextSize?` | inherited | Null follows the surrounding `DefaultTextStyle` |
| `icon` | `IconData?` | | Leading icon, sized to the text |
| `disabled` | `bool` | `false` | `textInactive`, no presses |
| `padTapTarget` | `bool` | `true` | 44x44 hit area on touch. Turn off inside running text |
| `externalHint` | `String?` | `KumoStrings.opensInNewWindow` | Screen reader hint for external links |
| `semanticLabel` | `String?` | | |
| `focusNode` | `FocusNode?` | | |

Variants:

| Variant | Color | Underline |
| --- | --- | --- |
| `inline` | `textLink` | text color at 35% (65% in dark), solid on hover |
| `current` | inherited text color | same as inline |
| `plain` | `textLink`, 70% on hover | none |

## Examples

### External

```dart
KumoLink(label: 'Workers documentation', external: true, onPress: () {})
```

### Inside running text

```dart
Text.rich(TextSpan(children: [
  const TextSpan(text: 'Read the '),
  WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: KumoLink(label: 'routing guide', padTapTarget: false, onPress: () {}),
  ),
  const TextSpan(text: ' before adding a custom domain.'),
]))
```

### Inside colored text

```dart
DefaultTextStyle(
  style: context.kumo.text(color: KumoColor.textDanger),
  child: KumoLink(label: 'Create a new token', variant: KumoLinkVariant.current, onPress: () {}),
)
```

## Accessibility

Announced as a link with its label (and the external hint). Enter activates; focus shows Kumo's ring. Inline links in a paragraph may keep the line height as their target (the inline exception in WCAG 2.5.8); standalone links keep the 44px target.

## Motion

None. Hover changes color and underline instantly.

## Mobile

A long label wraps inside the link. In a `WidgetSpan` the link does not break across lines with the paragraph, like Kumo's `inline-flex` link, so keep inline labels short.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` | `label` |
| `href`, `to`, `render`, `LinkProvider` | `onPress` |
| `variant` | `variant` |
| `target="_blank"` + `<Link.ExternalIcon />` | `external: true` |
| `className` | not ported |

Deviation: Flutter text decorations have no offset, so the underline sits at the font's default position instead of Kumo's 0.15em offset.
