import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/cart_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REQUIRED for Flutter Web (prevents auto logout)
  await Supabase.initialize(
    url: 'https://ealevibdxysypygbxquc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhbGV2aWJkeHlzeXB5Z2J4cXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzNTQ5MzUsImV4cCI6MjA4NDkzMDkzNX0.ibBJhGXsrwv0U8RtvgvPPnkGrgyibzPuZVC-7H8EgzU',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // 🔥 VERY IMPORTANT
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MagiilMartApp(),
    ),
  );
}

class MagiilMartApp extends StatelessWidget {
  const MagiilMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Magiil Mart',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),

      // ✅ Reacts to auth state changes properly
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session =
              Supabase.instance.client.auth.currentSession;

          if (session == null) {
            return const LoginScreen();
          } else {
            return const MainNavigation();
          }
        },
      ),
    );
  }
}
