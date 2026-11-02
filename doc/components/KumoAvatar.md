# KumoAvatar

A person's or account's picture, with initials while it loads or when there is none, optional live presence, and `KumoAvatarGroup` for stacks.

Kumo reference: none. Kumo has no avatar component; this one is inspired by shadcn's avatar and uses Kumo's fill, line and text tokens.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoAvatar(name: 'Ada Lovelace')
```

## When to use / when not to

Use it next to a person's or account's name in members lists, audit logs and comments. Only show a picture the person or account uploaded; without one the avatar shows initials (or a person glyph without a name). Never generate a face.

Set `status` only from live presence data; a stale "online" dot is worse than none.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `String?` | | Full or account name. Initials come from the first and last words; an email uses the part before the @ |
| `image` | `ImageProvider?` | | The uploaded picture. Initials show while it loads and if it fails |
| `size` | `KumoAvatarSize` | `base` | `sm` 24px, `base` 32px, `lg` 40px |
| `shape` | `KumoAvatarShape` | `circle` | `circle` for people, `square` (8px radius) for accounts and teams |
| `status` | `KumoAvatarStatus?` | | `online`, `away`, `busy`, `offline` dot at the bottom end |
| `statusLabel` | `String?` | | Replaces the English status name read by screen readers |
| `semanticLabel` | `String?` | | Replaces the spoken "name, status" |

`KumoAvatar.initialsOf(name)` returns the initials the avatar would show.

## Examples

### With a picture and presence

```dart
KumoAvatar(
  name: 'Grace Hopper',
  image: NetworkImage(member.avatarUrl),
  status: KumoAvatarStatus.online,
)
```

### Account

```dart
const KumoAvatar(name: 'example.com', shape: KumoAvatarShape.square, size: KumoAvatarSize.lg)
```

### Group

```dart
KumoAvatarGroup(
  max: 3,
  onOverflowPress: () => showMembers(),
  avatars: const [
    KumoAvatar(name: 'Ada Lovelace'),
    KumoAvatar(name: 'Grace Hopper'),
    KumoAvatar(name: 'Alan Turing'),
    KumoAvatar(name: 'Katherine Johnson'),
  ],
)
```

See `KumoAvatarGroup` for its parameters.

## Accessibility

The avatar is read as its name plus the status ("Grace Hopper, Online"); the picture itself is excluded. The status dot is never the only signal: screen readers hear the status, and wherever presence matters, show it as text next to the avatar too.

## Motion

A picture fades in over the initials when its first frame arrives (150ms). Under reduced motion it appears at once. Cached pictures appear without a fade. A status change eases the dot's color (150ms).

## Mobile

Initials scale with the text setting up to 1.3x, then stay inside the circle; the avatar keeps its size.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| (no Kumo component) | |
| shadcn `AvatarImage src` | `image` |
| shadcn `AvatarFallback` | `name` (initials) |
