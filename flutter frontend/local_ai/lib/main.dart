import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'homepage.dart';
import 'providers/chat_provider.dart';
import 'providers/model_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterGemma.initialize();
  } catch (e) {
    debugPrint('Failed to initialize FlutterGemma: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ModelProvider>(
          create: (_) => ModelProvider(),
        ),
        ChangeNotifierProxyProvider<ModelProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, modelProvider, chatProvider) {
            return chatProvider!..updateModelProvider(modelProvider);
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Local AI Chat',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFF262626),
            surface: Color(0xFF0D0D0D),
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0D0D0D),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            contentTextStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
        ),
        home: const Homepage(),
      ),
    );
  }
}
