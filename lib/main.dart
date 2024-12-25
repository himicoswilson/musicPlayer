import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'services/navidrome_service.dart';
import 'pages/login_page.dart';
import 'pages/library_page.dart';

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
    
    return MultiProvider(
      providers: [
        Provider.value(value: navidromeService),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(navidromeService),
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Builder(
        builder: (context) {
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              Widget app = MaterialApp(
                title: '音乐播放器',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                ),
                home: auth.isLoading
                    ? const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : auth.isLoggedIn
                        ? const LibraryPage()
                        : const LoginPage(),
              );

              // 添加错误边界
              return MaterialApp(
                builder: (context, child) {
                  ErrorWidget.builder = (FlutterErrorDetails details) {
                    return Material(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '发生错误',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '请稍后重试',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LibraryPage(),
                                  ),
                                );
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    );
                  };
                  return child ?? const SizedBox.shrink();
                },
                home: app,
              );
            },
          );
        },
      ),
    );
  }
}
