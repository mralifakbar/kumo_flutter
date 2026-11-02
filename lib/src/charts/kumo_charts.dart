/// Kumo charts drawn with `CustomPainter`: the chart palette, legend items,
/// the timeseries chart, sparklines, Sankey diagrams and a choropleth map.
///
/// Kumo's React charts wrap Apache ECharts. This port has no chart
/// dependency; the parts of the library share private scale, tooltip and
/// skeleton helpers, so they live in one library split into part files.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../display/kumo_skeleton_line.dart';
import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../typography/kumo_text.dart';
import '../utils/kumo_color_utils.dart';

part 'chart_scale.dart';
part 'chart_shared.dart';
part 'kumo_chart_colors.dart';
part 'kumo_chart_legend.dart';
part 'kumo_map_chart.dart';
part 'kumo_sankey_chart.dart';
part 'kumo_sparkline.dart';
part 'kumo_timeseries_chart.dart';
