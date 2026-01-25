import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation.dart';

import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
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
      home: const MainNavigation(),

    );
  }
}
