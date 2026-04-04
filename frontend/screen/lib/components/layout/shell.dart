import 'package:flutter/material.dart';

// TODO:
// [ ] Widget skeleton — Theme/Riverpod wiring only; CHIEF fills .rice (https://docs.flutter.dev/)
// [ ] Soft-code via --dart-define / String.fromEnvironment (https://riverpod.dev/docs/introduction/getting_started)
//
/// Full app scaffold — props compose header / nav / FAB without hardcoded content.
class RiceShell extends StatelessWidget {
  const RiceShell({
    required this.body, super.key,
    this.header,
    this.bottomNav,
    this.drawer,
    this.fab,
    this.backgroundColor,
  });

  final PreferredSizeWidget? header;
  final Widget? bottomNav;
  final Widget? drawer;
  final Widget? fab;
  final Widget body;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: backgroundColor,
      appBar: header,
      drawer: drawer,
      body: body,
      bottomNavigationBar: bottomNav,
      floatingActionButton: fab,
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
  }
}
