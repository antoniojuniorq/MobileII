import 'package:ace_core/ace_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AceControlApp(core: AceCore.create()));
}
