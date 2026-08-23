import 'package:flutter/material.dart';

import 'screens/login_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskManager',
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
