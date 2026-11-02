# Security policy

## Supported versions

Security fixes go into the latest published minor version of `kumo_flutter`.

| Version | Supported |
| --- | --- |
| 0.1.x | Yes |

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report it privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability** (https://github.com/mralifakbar/kumo_flutter/security/advisories/new). Include the affected version, a description, and steps to reproduce.

You can expect an acknowledgement within 7 days. Once a fix is ready we publish a patched release and a GitHub security advisory, and credit you unless you prefer otherwise.

This package is a UI library with no network or storage code, so most reports will concern dependencies or the build tooling in `tool/` and `bin/`.
