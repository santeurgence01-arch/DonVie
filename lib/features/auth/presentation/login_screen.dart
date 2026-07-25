import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/app_text_field.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/features/auth/application/auth_providers.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(loginControllerProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(loginControllerProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? AppSpacing.screenPaddingMobile
                    : AppSpacing.screenPaddingWeb,
                vertical: AppSpacing.sectionGap,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isMobile ? 48 : 24),
                    const _LogoHeader(),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Text(
                      'Connexion Administrateur',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accédez à l\'espace de gestion de votre structure',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppTextField(
                      label: 'Adresse e-mail',
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      semanticsLabel: 'Adresse e-mail',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'adresse e-mail est requise.';
                        }
                        if (!_emailRegex.hasMatch(value.trim())) {
                          return 'Adresse e-mail invalide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    AppTextField(
                      label: 'Mot de passe',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      semanticsLabel: 'Mot de passe',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis.';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO(forgot-password): flux de réinitialisation
                          // du mot de passe — hors scope de cette passe.
                        },
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (loginState.errorType != null) ...[
                      _LoginErrorBanner(
                        errorType: loginState.errorType!,
                        onRetry: _submit,
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                    ],
                    PrimaryButton(
                      label: 'Se connecter',
                      isLoading: loginState.isLoading,
                      onPressed: _submit,
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

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DonVie',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.errorType, required this.onRetry});

  final LoginErrorType errorType;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNetwork = errorType == LoginErrorType.network;
    final message = switch (errorType) {
      LoginErrorType.invalidCredentials =>
        'Adresse e-mail ou mot de passe incorrect.',
      LoginErrorType.network =>
        'Impossible de se connecter. Vérifiez votre connexion internet.',
      LoginErrorType.tooManyRequests =>
        'Trop de tentatives. Réessayez dans quelques minutes.',
      LoginErrorType.unknown => 'Une erreur est survenue. Réessayez.',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: AppColors.danger),
                ),
                if (isNetwork) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
