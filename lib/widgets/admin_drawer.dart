import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/splash_screen.dart';

/// A reusable drawer used throughout the admin section of the app.
///
/// The original implementation lived in `AdminDashboardScreen` but was
/// duplicated when navigating to analytics.  Pulling it into a separate
/// widget means we can include it on every admin page (
/// dashboard/analytics/orders etc.) without affecting any existing
/// behaviour.  The menu items simply close the drawer and push the
/// appropriate screen (or pop back to the dashboard when already there).
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF5A2E4A),
            ),
            child: Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Products'),
            onTap: () {
              Navigator.of(context).pop();
              // always go back to dashboard (clearing any analytics/orders
              // pages on top).  this keeps behaviour predictable and
              // avoids multiple copies of the same screen on the stack.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Orders'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
