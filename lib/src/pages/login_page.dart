import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme.dart';
import '../widgets/spog_widgets.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) {
      return;
    }
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _toast('Enter email and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Login failed.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AdminColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spogpaws Admin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Manrope',
                      color: AdminColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in with an admin/moderator account',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: AdminColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SpogTextField(
                    controller: _email,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  SpogTextField(
                    controller: _password,
                    obscureText: true,
                    hintText: 'Password',
                  ),
                  const SizedBox(height: 16),
                  SpogButton(
                    text: 'Sign In',
                    isLoading: _loading,
                    onTap: _loading ? null : _login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
