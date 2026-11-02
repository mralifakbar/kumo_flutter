import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';
import 'package:kumo_flutter/kumo_icon_catalog.dart';

import '../settings_scope.dart';

/// Searchable grid of every Phosphor icon, in regular or fill weight.
class IconsPage extends StatefulWidget {
  const IconsPage({super.key});

  @override
  State<IconsPage> createState() => _IconsPageState();
}

class _IconsPageState extends State<IconsPage> {
  final _focus = FocusNode();
  String _query = '';
  bool _fill = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final results = kumoIconCatalog.where((e) => e.matches(_query)).toList();
    final gutter = context.kumoIsNarrow ? KumoSpace.s4 : KumoSpace.s8;
    return Scaffold(
      backgroundColor: kumo.colors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: kumo.colors.hairline)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter - KumoSpace.s2,
                  KumoSpace.s1,
                  gutter - KumoSpace.s2,
                  KumoSpace.s1,
                ),
                child: Row(
                  children: [
                    KumoButton(
                      icon: KumoIcons.arrowLeft,
                      shape: KumoButtonShape.square,
                      variant: KumoButtonVariant.ghost,
                      semanticLabel: 'Back',
                      onPress: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const ThemeModeButton(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                KumoSpace.s6,
                gutter,
                KumoSpace.s3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KumoSpace.s3,
                children: [
                  const KumoText(
                    'Icons',
                    variant: KumoTextVariant.heading,
                    size: KumoTextSize.lg,
                    headingLevel: 1,
                  ),
                  Row(
                    spacing: KumoSpace.s2,
                    children: [
                      Expanded(
                        child: KumoFieldBox(
                          focused: _focus.hasFocus,
                          leading: const KumoIcon(KumoIcons.magnifyingGlass),
                          child: KumoEditable(
                            focusNode: _focus,
                            placeholder: 'Search 1,530 icons',
                            semanticLabel: 'Search icons',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                      ),
                      KumoButton(
                        label: _fill ? 'Fill' : 'Regular',
                        icon: _fill ? KumoIcons.circleFill : KumoIcons.circle,
                        semanticLabel: 'Weight: ${_fill ? 'fill' : 'regular'}',
                        onPress: () => setState(() => _fill = !_fill),
                      ),
                    ],
                  ),
                  KumoText(
                    results.isEmpty
                        ? 'No icons match "$_query". Try a broader word like "arrow" or "cloud".'
                        : '${results.length} icons',
                    variant: KumoTextVariant.secondary,
                    size: KumoTextSize.sm,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  0,
                  gutter,
                  MediaQuery.paddingOf(context).bottom + KumoSpace.s8,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 104,
                  mainAxisExtent: 88,
                  crossAxisSpacing: KumoSpace.s2,
                  mainAxisSpacing: KumoSpace.s2,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final e = results[i];
                  return KumoTooltip(
                    content: e.name,
                    child: Semantics(
                      label: e.name,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: kumo.colors.base,
                          borderRadius: BorderRadius.circular(KumoRadius.lg),
                          border: KumoRing.border(kumo.colors.hairline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: KumoSpace.s2,
                          children: [
                            KumoIcon(
                              _fill && e.fill != null ? e.fill! : e.regular,
                              size: 24,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KumoSpace.s1,
                              ),
                              child: Text(
                                e.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: kumo.text(
                                  size: KumoTextSize.xs,
                                  color: KumoColor.textSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
