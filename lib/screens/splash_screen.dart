import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/login_screen.dart';
import 'main_navigation.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Show loading while waiting for auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = Supabase.instance.client.auth.currentSession;

          if (session == null) {
            // No session - go to login
            return const LoginScreen();
          }

          // Check user role and navigate accordingly
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null && (user.email ?? '').toLowerCase() == 'admin@magiilmart.com') {
            // Admin user
            return const AdminDashboardScreen();
          } else {
            // Regular customer
            return const MainNavigation();
          }
        },
      ),
    );
  }
}
