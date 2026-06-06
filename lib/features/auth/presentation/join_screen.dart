import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../data/auth_repository.dart';

class JoinScreen extends ConsumerStatefulWidget {
  final String inviteCode;
  const JoinScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  _Status _status = _Status.joining;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    final authAsync = ref.read(authStateProvider);
    final isLoggedIn = authAsync.value?.session != null;

    if (!isLoggedIn) {
      // Not logged in — send to login, preserving the invite code
      context.go('/login?invite=${widget.inviteCode}');
      return;
    }

    final profile = await ref.read(currentProfileProvider.future);
    if (profile?.householdId != null) {
      // Already in a household — just go home
      if (mounted) context.go('/home');
      return;
    }

    try {
      final user = ref.read(authRepositoryProvider).currentUser!;
      await ref.read(authRepositoryProvider).joinHousehold(widget.inviteCode, user.id);
      ref.invalidate(currentProfileProvider);
      // redirect will fire automatically to /home once profile reloads
    } catch (e) {
      if (mounted) setState(() { _status = _Status.error; _error = friendlyError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_status == _Status.joining) ...[
                  const CircularProgressIndicator(color: AppColors.black),
                  const SizedBox(height: 20),
                  Text(S.joiningHousehold, style: AppTextStyles.titleMedium),
                ] else ...[
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(_error ?? S.somethingWrong,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() { _status = _Status.joining; _error = null; });
                      _join();
                    },
                    child: Text(S.retry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Status { joining, error }
