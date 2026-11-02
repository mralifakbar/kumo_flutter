part of 'kumo_charts.dart';

/// A value axis: nice bounds and the ticks between them.
@immutable
class _NiceScale {
  const _NiceScale(this.min, this.max, this.step, this.ticks);

  final double min;
  final double max;
  final double step;
  final List<double> ticks;

  /// Decimals needed to print [step] exactly (0.25 needs 2).
  int get decimals => _decimalsFor(step);

  /// ECharts' value axis: interval is the raw range over [count] rounded to
  /// 1, 2, 3 or 5 times a power of ten, at least [minInterval]; bounds
  /// snap outward to the interval.
  static _NiceScale of(double lo, double hi, {int count = 5, double? minInterval}) {
    if (!lo.isFinite || !hi.isFinite) {
      lo = 0;
      hi = 1;
    }
    if (hi < lo) {
      final t = hi;
      hi = lo;
      lo = t;
    }
    if (hi == lo) {
      if (hi == 0) {
        hi = 1;
      } else {
        final pad = hi.abs() / 2;
        lo -= pad;
        hi += pad;
      }
    }
    var step = _niceNumber((hi - lo) / math.max(1, count));
    if (minInterval != null && minInterval > 0 && step < minInterval) step = minInterval;
    final decimals = _decimalsFor(step);
    double round(double v) => double.parse(v.toStringAsFixed(math.min(decimals + 2, 12)));
    final min = round((lo / step).floor() * step);
    final max = round((hi / step).ceil() * step);
    final ticks = <double>[];
    final n = ((max - min) / step).round();
    for (var i = 0; i <= n && i < 64; i++) {
      ticks.add(round(min + i * step));
    }
    return _NiceScale(min, max, step, ticks);
  }
}

double _niceNumber(double v) {
  if (v <= 0 || !v.isFinite) return 1;
  final exp = (math.log(v) / math.ln10).floor();
  final pow = math.pow(10, exp).toDouble();
  final f = v / pow;
  final nf = f < 1.5
      ? 1
      : f < 2.5
      ? 2
      : f < 4
      ? 3
      : f < 7
      ? 5
      : 10;
  return nf * pow;
}

int _decimalsFor(double step) {
  for (var d = 0; d < 10; d++) {
    final scaled = step * math.pow(10, d);
    if ((scaled - scaled.roundToDouble()).abs() < 1e-6 * math.max(1, scaled.abs())) return d;
  }
  return 10;
}

enum _TimeUnit { second, minute, hour, day, month, year }

@immutable
class _TimeTick {
  const _TimeTick(this.time, this.label, this.major);

  final DateTime time;
  final String label;

  /// A day, month or year boundary, drawn a step stronger like ECharts does.
  final bool major;
}

const _kTimeSteps = <(_TimeUnit, int)>[
  (_TimeUnit.second, 1), (_TimeUnit.second, 2), (_TimeUnit.second, 5), //
  (_TimeUnit.second, 10), (_TimeUnit.second, 15), (_TimeUnit.second, 30),
  (_TimeUnit.minute, 1), (_TimeUnit.minute, 2), (_TimeUnit.minute, 5),
  (_TimeUnit.minute, 10), (_TimeUnit.minute, 15), (_TimeUnit.minute, 30),
  (_TimeUnit.hour, 1), (_TimeUnit.hour, 2), (_TimeUnit.hour, 3), (_TimeUnit.hour, 6), (_TimeUnit.hour, 12),
  (_TimeUnit.day, 1), (_TimeUnit.day, 2), (_TimeUnit.day, 7), (_TimeUnit.day, 14),
  (_TimeUnit.month, 1), (_TimeUnit.month, 2), (_TimeUnit.month, 3), (_TimeUnit.month, 6),
  (_TimeUnit.year, 1), (_TimeUnit.year, 2), (_TimeUnit.year, 5), (_TimeUnit.year, 10),
  (_TimeUnit.year, 25), (_TimeUnit.year, 50), (_TimeUnit.year, 100),
];

double _unitMs(_TimeUnit unit) => switch (unit) {
  _TimeUnit.second => 1000,
  _TimeUnit.minute => 60000,
  _TimeUnit.hour => 3600000,
  _TimeUnit.day => 86400000,
  _TimeUnit.month => 30 * 86400000,
  _TimeUnit.year => 365 * 86400000,
};

/// Time axis ticks for [startMs]..[endMs], about [count] of them, aligned to
/// calendar boundaries in the data's own zone ([utc] or local), with labels
/// whose precision follows the step: seconds, `HH:mm`, `Mar 4`, `Mar`, `2026`.
List<_TimeTick> _timeTicks(double startMs, double endMs, int count, bool utc, KumoStrings strings) {
  if (!(endMs > startMs)) return const [];
  final approx = (endMs - startMs) / math.max(1, count);
  var choice = _kTimeSteps.last;
  for (final s in _kTimeSteps) {
    if (_unitMs(s.$1) * s.$2 >= approx) {
      choice = s;
      break;
    }
  }
  final (unit, step) = choice;
  DateTime make(int y, [int mo = 1, int d = 1, int h = 0, int mi = 0, int s = 0]) =>
      utc ? DateTime.utc(y, mo, d, h, mi, s) : DateTime(y, mo, d, h, mi, s);

  final start = DateTime.fromMillisecondsSinceEpoch(startMs.floor(), isUtc: utc);
  DateTime cur = switch (unit) {
    _TimeUnit.second => make(start.year, start.month, start.day, start.hour, start.minute, start.second ~/ step * step),
    _TimeUnit.minute => make(start.year, start.month, start.day, start.hour, start.minute ~/ step * step),
    _TimeUnit.hour => make(start.year, start.month, start.day, start.hour ~/ step * step),
    _TimeUnit.day => make(start.year, start.month, (start.day - 1) ~/ step * step + 1),
    _TimeUnit.month => make(start.year, (start.month - 1) ~/ step * step + 1),
    _TimeUnit.year => make(start.year ~/ step * step),
  };
  DateTime next(DateTime d) => switch (unit) {
    _TimeUnit.second => make(d.year, d.month, d.day, d.hour, d.minute, d.second + step),
    _TimeUnit.minute => make(d.year, d.month, d.day, d.hour, d.minute + step),
    _TimeUnit.hour => make(d.year, d.month, d.day, d.hour + step),
    _TimeUnit.day => () {
      final n = make(d.year, d.month, d.day + step);
      // Day steps restart on the 1st so ticks stay on the same days each month.
      return n.month != d.month ? make(d.year, d.month + 1) : n;
    }(),
    _TimeUnit.month => make(d.year, d.month + step),
    _TimeUnit.year => make(d.year + step),
  };

  String two(int v) => v.toString().padLeft(2, '0');
  final ticks = <_TimeTick>[];
  for (var guard = 0; guard < 400; guard++) {
    final ms = cur.millisecondsSinceEpoch;
    if (ms > endMs) break;
    if (ms >= startMs) {
      final midnight = cur.hour == 0 && cur.minute == 0 && cur.second == 0;
      final monthName = strings.monthNamesShort[cur.month - 1];
      final (label, major) = switch (unit) {
        _TimeUnit.second => ('${two(cur.hour)}:${two(cur.minute)}:${two(cur.second)}', false),
        _TimeUnit.minute ||
        _TimeUnit.hour => midnight ? ('$monthName ${cur.day}', true) : ('${two(cur.hour)}:${two(cur.minute)}', false),
        _TimeUnit.day =>
          cur.day == 1
              ? (cur.month == 1 ? ('${cur.year}', true) : (monthName, true))
              : ('$monthName ${cur.day}', false),
        _TimeUnit.month => cur.month == 1 ? ('${cur.year}', true) : (monthName, false),
        _TimeUnit.year => ('${cur.year}', false),
      };
      ticks.add(_TimeTick(cur, label, major));
    }
    final n = next(cur);
    if (!n.isAfter(cur)) break;
    cur = n;
  }
  return ticks;
}
