// Sample data for the console demo. None of it describes real services,
// traffic or customers.

import 'dart:math' as math;

enum WorkerHealth { healthy, degraded, failing, paused }

class SampleDeployment {
  const SampleDeployment({
    required this.version,
    required this.message,
    required this.author,
    required this.ago,
    this.failed = false,
  });

  final String version;
  final String message;
  final String author;
  final String ago;
  final bool failed;
}

class SampleWorker {
  SampleWorker({
    required this.name,
    required this.description,
    required this.route,
    required this.health,
    required this.lastDeploy,
    required this.deployments,
    required this.seed,
    this.logsEnabled = true,
    this.compatibilityDate = '2026-09-01',
  });

  String name;
  final String description;
  final String route;
  WorkerHealth health;
  final String lastDeploy;
  final List<SampleDeployment> deployments;
  final int seed;
  bool logsEnabled;
  String compatibilityDate;

  /// A deterministic, made-up request curve for the last 24 hours.
  List<(DateTime, double)> requests(DateTime now) {
    final rnd = math.Random(seed);
    final start = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).subtract(const Duration(hours: 23));
    final base = 400 + seed % 7 * 90;
    return [
      for (var h = 0; h < 24; h++)
        (
          start.add(Duration(hours: h)),
          (base * (0.6 + 0.4 * math.sin((h - 6) / 24 * 2 * math.pi).abs()) +
                  rnd.nextInt(120))
              .roundToDouble(),
        ),
    ];
  }

  /// Made-up error counts aligned with [requests].
  List<(DateTime, double)> errors(DateTime now) {
    final rnd = math.Random(seed + 1);
    final faulty =
        health == WorkerHealth.failing || health == WorkerHealth.degraded;
    return [
      for (final (t, v) in requests(now))
        (t, (v * (faulty ? 0.04 : 0.005) + rnd.nextInt(4)).roundToDouble()),
    ];
  }
}

class SampleDnsRecord {
  SampleDnsRecord({
    required this.type,
    required this.name,
    required this.content,
    required this.proxied,
    this.ttl = 'Auto',
  });

  final String type;
  final String name;
  final String content;
  bool proxied;
  final String ttl;
}

List<SampleWorker> sampleWorkers() => [
  SampleWorker(
    name: 'image-resizer',
    description: 'Resizes and converts images on request.',
    route: 'example.com/images/*',
    health: WorkerHealth.healthy,
    lastDeploy: '12 min ago',
    seed: 3,
    deployments: const [
      SampleDeployment(
        version: 'v42',
        message: 'Serve AVIF when the browser accepts it',
        author: 'ci-token',
        ago: '12 min ago',
      ),
      SampleDeployment(
        version: 'v41',
        message: 'Cache resized images for a day',
        author: 'ci-token',
        ago: '2 days ago',
      ),
      SampleDeployment(
        version: 'v40',
        message: 'Reject images over 20 MB',
        author: 'sam',
        ago: '5 days ago',
        failed: true,
      ),
      SampleDeployment(
        version: 'v39',
        message: 'Initial deploy',
        author: 'sam',
        ago: 'Sep 30',
      ),
    ],
  ),
  SampleWorker(
    name: 'auth-proxy',
    description: 'Checks session cookies before requests reach the origin.',
    route: 'app.example.com/*',
    health: WorkerHealth.degraded,
    lastDeploy: '1 hour ago',
    seed: 8,
    deployments: const [
      SampleDeployment(
        version: 'v17',
        message: 'Refresh tokens five minutes before expiry',
        author: 'riya',
        ago: '1 hour ago',
      ),
      SampleDeployment(
        version: 'v16',
        message: 'Log rejected sessions',
        author: 'riya',
        ago: 'Yesterday',
      ),
    ],
  ),
  SampleWorker(
    name: 'geo-redirect',
    description: 'Sends visitors to the nearest regional site.',
    route: 'example.com/',
    health: WorkerHealth.failing,
    lastDeploy: '3 hours ago',
    seed: 5,
    logsEnabled: false,
    deployments: const [
      SampleDeployment(
        version: 'v8',
        message: 'Add Portuguese redirect',
        author: 'ci-token',
        ago: '3 hours ago',
        failed: true,
      ),
      SampleDeployment(
        version: 'v7',
        message: 'Respect the language cookie',
        author: 'ci-token',
        ago: 'Oct 28',
      ),
    ],
  ),
  SampleWorker(
    name: 'og-image',
    description: 'Renders social preview images for blog posts.',
    route: 'blog.example.com/og/*',
    health: WorkerHealth.paused,
    lastDeploy: 'Oct 12',
    seed: 11,
    deployments: const [
      SampleDeployment(
        version: 'v3',
        message: 'Use the new title font',
        author: 'sam',
        ago: 'Oct 12',
      ),
    ],
  ),
];

List<SampleDnsRecord> sampleDnsRecords() => [
  SampleDnsRecord(
    type: 'A',
    name: 'example.com',
    content: '192.0.2.10',
    proxied: true,
  ),
  SampleDnsRecord(
    type: 'AAAA',
    name: 'example.com',
    content: '2001:db8::10',
    proxied: true,
  ),
  SampleDnsRecord(
    type: 'CNAME',
    name: 'www',
    content: 'example.com',
    proxied: true,
  ),
  SampleDnsRecord(
    type: 'CNAME',
    name: 'blog',
    content: 'blog-host.example.net',
    proxied: false,
  ),
  SampleDnsRecord(
    type: 'MX',
    name: 'example.com',
    content: 'mail.example.net',
    proxied: false,
    ttl: '1 hr',
  ),
  SampleDnsRecord(
    type: 'TXT',
    name: '_dmarc',
    content: 'v=DMARC1; p=quarantine',
    proxied: false,
    ttl: '1 hr',
  ),
];
