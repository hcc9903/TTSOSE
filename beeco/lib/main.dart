import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'pages/main_page.dart';
import 'pages/login_page.dart';

export 'providers/app_providers.dart';
export 'providers/auth_provider.dart';
export 'theme/app_theme.dart';
export 'models/models.dart';
export 'data/dao.dart';
export 'data/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BeeCoApp(),
    ),
  );
}

class BeeCoApp extends ConsumerWidget {
  const BeeCoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final authStatus = ref.watch(authProvider);

    ThemeMode getFlutterThemeMode() {
      switch (themeMode) {
        case ThemeMode.light:
          return ThemeMode.light;
        case ThemeMode.dark:
          return ThemeMode.dark;
        case ThemeMode.system:
          return ThemeMode.system;
      }
    }

    // 根据认证状态决定显示哪个页面
    Widget homeWidget;
    switch (authStatus) {
      case AuthStatus.loading:
        homeWidget = const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
        break;
      case AuthStatus.authenticated:
        homeWidget = const MainPage();
        break;
      case AuthStatus.unauthenticated:
        homeWidget = const LoginPage();
        break;
    }

    return MaterialApp(
      title: 'BeeCo 记账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(Color(primaryColor)),
      darkTheme: AppTheme.darkTheme(Color(primaryColor)),
      themeMode: getFlutterThemeMode(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: homeWidget,
    );
  }
}
