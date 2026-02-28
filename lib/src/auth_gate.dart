import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_repository.dart';
import 'models.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';
import 'theme.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, _) {
        final session = client.auth.currentSession;
        if (session == null) {
          return const AdminLoginPage();
        }
        return FutureBuilder<AdminProfile?>(
          future: _repo.fetchCurrentProfile(session.user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ErrorState(
                title: 'Could not load profile',
                subtitle: '${snapshot.error}',
              );
            }
            final profile = snapshot.data;
            if (profile == null) {
              return const _ErrorState(
                title: 'Profile not found',
                subtitle: 'Your account has no profile row. Contact owner.',
              );
            }
            final role = profile.role.toLowerCase();
            if (role != 'admin' && role != 'moderator') {
              return _ErrorState(
                title: 'Access denied',
                subtitle:
                    'Only admin/moderator can use this panel. Current role: ${profile.role}',
              );
            }
            return AdminDashboard(profile: profile);
          },
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AdminColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                    child: const Text('Sign out'),
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
