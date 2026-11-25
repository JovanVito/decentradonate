import 'package:decentradonate/features/access/domain/email_otp.dart';

import 'dart:async';

import 'package:decentradonate/features/access/data/supabase_access_repository.dart';
import 'package:decentradonate/features/access/domain/access_repository.dart';
import 'package:decentradonate/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({required this.isOrganizer, super.key});

  final bool isOrganizer;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  String? _error;
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  Future<void> _send({bool resend = false}) async {
    if (_busy || _seconds > 0) return;
    if (!resend && !(_form.currentState?.validate() ?? false)) return;
    final repository = ref.read(accessRepositoryProvider);
    if (repository == null) return;
    final strings = AppLocalizations.of(context)!;
    final email = _sentTo ?? _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.sendCode(email, allowSignup: !widget.isOrganizer);
      if (!mounted) return;
      setState(() {
        _sentTo = email;
        _code.clear();
        _startCooldown();
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = strings.sendCodeError;
        _startCooldown();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final email = _sentTo;
    final repository = ref.read(accessRepositoryProvider);
    if (_busy ||
        email == null ||
        repository == null ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final strings = AppLocalizations.of(context)!;
    final role = widget.isOrganizer ? AccountRole.organizer : AccountRole.donor;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.verifyCode(email, _code.text);
      try {
        if (await repository.currentRole() == role) {
          if (mounted) {
            context.go(
              widget.isOrganizer ? '/akun/penyelenggara' : '/akun/donatur',
            );
          }
          return;
        }
      } on Exception {
        await repository.signOut();
        if (mounted) setState(() => _error = strings.accessError);
        return;
      }
      await repository.signOut();
      if (mounted) setState(() => _error = strings.roleDenied);
    } on Exception {
      if (mounted) setState(() => _error = strings.verifyCodeError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final available = ref.watch(accessRepositoryProvider) != null;
    final sentTo = _sentTo;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOrganizer ? strings.organizerTitle : strings.donorTitle,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!available)
                      Text(strings.otpUnavailable)
                    else ...[
                      Text(
                        sentTo == null
                            ? strings.enterEmail
                            : strings.codeSent(sentTo),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      if (sentTo == null)
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_busy,
                          decoration: InputDecoration(
                            labelText: strings.emailLabel,
                          ),
                          validator: (value) => EmailOtp.validEmail(value)
                              ? null
                              : strings.invalidEmail,
                        )
                      else
                        TextFormField(
                          key: const ValueKey('email-otp'),
                          controller: _code,
                          autofocus: true,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: strings.codeLabel,
                          ),
                          validator: (value) => EmailOtp.validCode(value)
                              ? null
                              : strings.invalidCode,
                        ),
                      const SizedBox(height: 12),
                      if (_error case final error?)
                        Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              error,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: _busy || (sentTo == null && _seconds > 0)
                            ? null
                            : sentTo == null
                            ? _send
                            : _verify,
                        child: Text(
                          _busy
                              ? strings.processing
                              : sentTo == null
                              ? (_seconds > 0
                                    ? strings.retryAfter(_seconds)
                                    : strings.sendCode)
                              : strings.verifyCode,
                        ),
                      ),
                      if (sentTo != null)
                        TextButton(
                          onPressed: _busy || _seconds > 0
                              ? null
                              : () => _send(resend: true),
                          child: Text(
                            _seconds > 0
                                ? strings.retryAfter(_seconds)
                                : strings.resendCode,
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _busy ? null : () => context.go('/'),
                      child: Text(strings.returnToAccess),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
