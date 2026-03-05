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
        if (e.message.contains("role")) {
          // missing column; insert minimal profile instead
          await Supabase.instance.client.from('profiles').insert({
            'user_id': user.id,
            'email': user.email,
          });
        } else if (e.code == '42501' ||
            e.message.toLowerCase().contains('row-level security')) {
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

      // Try to sign the user in immediately so we can redirect to home.
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // If sign-in succeeded, navigate to main/home.
        if (!mounted) return;
        // replace signup screen with home so it can't be returned to
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
        return;
      } catch (_) {
        // If immediate sign-in fails (e.g. confirmation required), fall back
        // to prompting the user to log in.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created. Please confirm and log in.'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
        return;
      }
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
