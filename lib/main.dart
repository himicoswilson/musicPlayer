import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'services/navidrome_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navidromeService = NavidromeService();
    final settingsProvider = SettingsProvider()..loadSettings();
    
    return MultiProvider(
      providers: [
        Provider.value(value: navidromeService),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(navidromeService),
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '音乐播放器',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: settings.primaryColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              navigationBarTheme: NavigationBarThemeData(
                labelBehavior: settings.showNavigationLabels
                    ? NavigationDestinationLabelBehavior.alwaysShow
                    : NavigationDestinationLabelBehavior.onlyShowSelected,
                height: settings.navigationBarHeight,
                surfaceTintColor: Colors.transparent,
                backgroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.black.withOpacity(0.1),
                indicatorColor: settings.primaryColor.withOpacity(0.2),
                iconTheme: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return IconThemeData(color: settings.primaryColor);
                  }
                  return null;
                }),
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return TextStyle(color: settings.primaryColor);
                  }
                  return null;
                }),
              ),
              listTileTheme: ListTileThemeData(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                minVerticalPadding: 0,
                visualDensity: VisualDensity.compact,
              ),
              dividerTheme: DividerThemeData(
                color: Colors.grey[200],
                thickness: 1,
                space: 1,
              ),
            ),
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return auth.isLoggedIn ? const HomePage() : const LoginPage();
              },
            ),
          );
        },
      ),
    );
  }
}
