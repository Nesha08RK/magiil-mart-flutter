import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Supabase init (PKCE required for Web)
  await Supabase.initialize(
    url: 'https://ealevibdxysypygbxquc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhbGV2aWJkeHlzeXB5Z2J4cXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzNTQ5MzUsImV4cCI6MjA4NDkzMDkzNX0.ibBJhGXsrwv0U8RtvgvPPnkGrgyibzPuZVC-7H8EgzU',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // ✅ Initialize cart with persistence
  final cartProvider = CartProvider();
  await cartProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(create: (_) => cartProvider),
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

      // 🎨 PLUM LUXURY THEME
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Professional white

        colorScheme: const ColorScheme(
          brightness: Brightness.light,

          primary: Color(0xFF5A2E4A), // Rich Plum
          onPrimary: Colors.white,

          secondary: Color(0xFFA0789A), // Dusty Mauve
          onSecondary: Colors.white,

          tertiary: Color(0xFFC9A347), // Gold
          onTertiary: Colors.black,

          surface: Colors.white,
          onSurface: Color(0xFF2C2C2C),

          background: Colors.white,
          onBackground: Color(0xFF2C2C2C),

          error: Colors.redAccent,
          onError: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF5A2E4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF5A2E4A),
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF5A2E4A),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A2E4A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ✅ FIXED: CardThemeData (NOT CardTheme)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ),

      // 🔐 SPLASH SCREEN AS ENTRY POINT
      home: const SplashScreen(),
    );
  }
}
