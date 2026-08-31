import 'package:flutter/material.dart';

import 'screens/startup_screen.dart';
import 'services/privacy_service.dart';
import 'theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PrivacyService.instance
      .initialize();

  runApp(
    const FamilyFinanceApp(),
  );
}


class FamilyFinanceApp
    extends StatelessWidget {
  const FamilyFinanceApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title:
          'Family Finance',

      debugShowCheckedModeBanner:
          false,

      theme:
          AppTheme.light,

      home:
          const StartupScreen(),
    );
  }
}