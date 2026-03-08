import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_navigation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> signup() async {
    setState(() => loading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Signup failed');
      }

      // ✅ INSERT PROFILE WITH DEFAULT ROLE = customer
      // The database may not always have a `role` column, which can
      // cause the `PostgrestException` seen during signup.  We catch the
      // specific error and retry without the column so the sign‑up flow
      // remains functional even if the schema is out of date.
      try {
        await Supabase.instance.client.from('profiles').insert({
          // use user_id column (schema requires not null) – database will
          // generate its own primary key value for `id`
          'user_id': user.id,
          'email': user.email,
          'role': 'customer', // 👈 DEFAULT ROLE
        });
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains("role")) {
          // missing column; insert minimal profile instead
          await Supabase.instance.client.from('profiles').insert({
            'user_id': user.id,
            'email': user.email,
          });
        } else if (msg.contains('duplicate key') ||
            msg.contains('profiles_user_id_key')) {
          // already have a profile row for this user – ignore silently
        } else if (e.code == '42501' || msg.contains('row-level security')) {
          // blocked by a row-level security policy.  The proper fix is to
          // create a policy allowing anonymous insert of profile rows or
          // perform this action via a trusted server key.  Here we swallow
          // the error so the UI continues; notify user so support can
          // investigate if profiles are expected to exist.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Unable to create profile (security policy). Please contact support.'),
            ));
          }
        } else {
          rethrow;
        }
      }

      if (!mounted) return;

      // we attempt to sign the user in so that the session is available
      // immediately, but even if this call throws (email confirm required,
      // network hiccup, RLS policy, etc.) we still navigate to the home
      // screen. the splash/stream logic will route the user correctly based
      // on the actual auth state.
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } catch (err) {
        // sign-in failed, perhaps email confirmation is required; the
        // user will still be routed to the home screen but we surface
        // a message so they understand why some features may not work
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Account created (login pending). Please confirm your email or log in again.'),
            duration: Duration(seconds: 3),
          ));
        }
      }

      if (!mounted) return;
      // replace signup screen with home so it can't be returned to
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : signup,
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
