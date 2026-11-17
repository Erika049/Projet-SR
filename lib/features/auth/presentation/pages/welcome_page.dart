import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/auth_layout.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.header,
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                const AuthLogo(size: 148),
                const SizedBox(height: 22),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(AppConstants.tagline, style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 15),
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(color: AuthLogo.accent, borderRadius: BorderRadius.circular(3)),
                ),
                const Spacer(flex: 7),
                // const Text(
                //   'PARENTS · ENSEIGNANTS · ADMINISTRATION',
                //   style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                // ),
               // const SizedBox(height: 60),
                const Text('Pensé pour les écoles du Cameroun', style: TextStyle(color: Colors.white, fontSize: 16)),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => context.push(Routes.login),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Démarrer'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 22)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
