import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import 'scenes/home/home_scene.dart';
import 'scenes/login/login_scene.dart';

class AceControlApp extends StatelessWidget {
  const AceControlApp({super.key, required this.core});

  final AceCore core;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACE CONTROL',
      debugShowCheckedModeBanner: false,
      theme: AceTheme.light,
      darkTheme: AceTheme.dark,
      themeMode: ThemeMode.system,
      home: SessionGate(core: core),
    );
  }
}

/// Decide a primeira tela: com auth code salvo vai direto para a Home,
/// sem ele mostra o Login.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.core});

  final AceCore core;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _hasSession = widget.core.auth.hasSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == true
            ? HomeScene(core: widget.core)
            : LoginScene(core: widget.core);
      },
    );
  }
}
