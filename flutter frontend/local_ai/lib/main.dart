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
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0EA5E9),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF020617),
        ),
        home: const Homepage(),
      ),
    );
  }
}
