# KumoAccordion

A stack of collapsible sections separated by hairlines, for FAQs and grouped settings where people open one or a few sections at a time. Shaped after shadcn's accordion and drawn with Kumo tokens; Kumo has no accordion of its own.

Kumo reference: https://kumo-ui.com/components/collapsible (the building block)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoAccordion(
  value: open,
  onValueChange: (v) => setState(() => open = v),
  items: const [
    KumoAccordionItem(value: 'cache', title: 'Cache rules', child: KumoText('3 rules apply to example.com')),
    KumoAccordionItem(value: 'waf', title: 'WAF custom rules', child: KumoText('1 rule blocks /wp-admin')),
  ],
)
```

## When to use / when not to

Use it for three or more related sections that are too long to show at once. For a single block, use `KumoCollapsible`; for views that replace each other, use `KumoTabs`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoAccordionItem>` | required | |
| `value` | `Set<String>` | required | Values of the open items |
| `onValueChange` | `ValueChanged<Set<String>>?` | required | The next set. Null makes it read-only |
| `type` | `KumoAccordionType` | `single` | `single` closes the others; `multiple` opens independently |
| `collapsible` | `bool` | `true` | For `single`: whether the open item can be closed |
| `keepMounted` | `bool` | `false` | Keep closed panels alive |

`KumoAccordionItem`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | |
| `title` | `String` | required | Medium 14px |
| `child` | `Widget` | required | Panel content; plain `Text` is shown in subtle 14px |
| `description` | `String?` | | Second line under the title |
| `icon` | `IconData?` | | Leading 16px icon; the panel indents to line up |
| `disabled` | `bool` | `false` | |

## Examples

### Multiple open

```dart
KumoAccordion(
  type: KumoAccordionType.multiple,
  value: open,
  onValueChange: (v) => setState(() => open = v),
  items: const [
    KumoAccordionItem(value: 'routes', title: 'Routes', icon: KumoIcons.globe, child: Text('example.com/api/*')),
    KumoAccordionItem(value: 'logs', title: 'Logs', icon: KumoIcons.listBullets, child: Text('Workers Logs')),
  ],
)
```

## Accessibility

Each header is a header and a button with an expanded state. Tab moves between headers; Up and Down also move (wrapping, skipping disabled items), Home and End jump to the ends, Enter or Space toggles. Closed content is out of the focus order and hidden from screen readers.

## Motion

Panels open with `KumoCollapsiblePanel`: 200ms height and fade, content clipped at full size, reversible mid-flight. The caret is a `KumoDisclosureCaret` on the same timing, so it turns in step with its panel while another item closes. Reduced motion is instant.

## Mobile

Headers are full width with at least 44px of height on touch; titles and descriptions wrap at 2x text.

## Kumo React mapping

Kumo builds accordions from controlled `Collapsible` roots (see its "Controlled Accordion Pattern"). Here:

| Kumo pattern | Flutter |
| --- | --- |
| `activeIndex` state + `open={activeIndex === i}` | `value` (a set) + `type: single` |
| several independent `Collapsible.Root`s | `type: multiple` |
| `Collapsible.DefaultTrigger` | the section header |
| `Collapsible.DefaultPanel` | the section panel (no accent rule) |
