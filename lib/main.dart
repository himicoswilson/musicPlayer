import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/local_library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/cache_provider.dart';
import 'services/navidrome_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  final success = await authProvider.tryAutoLogin();
  final navidromeService = NavidromeService();
  final settingsProvider = SettingsProvider()..loadSettings();
  
  runApp(
    DevicePreview(
      enabled: true,
      tools: const [
        ...DevicePreview.defaultTools,
      ],
      builder: (context) => MultiProvider(
        providers: [
          Provider.value(value: navidromeService),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider(
            create: (context) => PlayerProvider(context.read<SettingsProvider>()),
          ),
          ChangeNotifierProvider(
            create: (context) => LocalLibraryProvider(
              context.read<PlayerProvider>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => LibraryProvider(navidromeService),
          ),
          ChangeNotifierProvider(create: (_) => PlaylistProvider()),
          ChangeNotifierProvider(
            create: (_) => CacheProvider(navidromeService),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Music Player',
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
  }
}
