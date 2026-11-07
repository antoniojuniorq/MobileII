import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';
import 'showcase_page.dart';

void main() => runApp(const AceSampleApp());

/// Sample app do Design System: galeria viva de tokens e componentes.
class AceSampleApp extends StatefulWidget {
  const AceSampleApp({super.key});

  @override
  State<AceSampleApp> createState() => _AceSampleAppState();
}

class _AceSampleAppState extends State<AceSampleApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACE CONTROL Design System',
      debugShowCheckedModeBanner: false,
      theme: AceTheme.light,
      darkTheme: AceTheme.dark,
      themeMode: _mode,
      home: ShowcasePage(
        isDark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(
          () => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
        ),
      ),
    );
  }
}
