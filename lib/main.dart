import 'package:flutter/material.dart';
import 'design_system/design_system.dart';
import 'showcase/showcase_page.dart';

void main() => runApp(const AceControlApp());

class AceControlApp extends StatefulWidget {
  const AceControlApp({super.key});

  @override
  State<AceControlApp> createState() => _AceControlAppState();
}

class _AceControlAppState extends State<AceControlApp> {
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
