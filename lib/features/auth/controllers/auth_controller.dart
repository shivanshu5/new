import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final String? verificationId;

  const AuthState({this.isLoading = false, this.error, this.verificationId});

  AuthState copyWith({bool? isLoading, String? error, String? verificationId, bool clearError = false}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.read(authServiceProvider),
    ref.read(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final AuthRepository _authRepository;

  AuthController(this._authService, this._authRepository) : super(const AuthState());

  Future<void> requestPhoneOtp(String phoneNumber, BuildContext context) async {
    // TEMPORARY BYPASS FOR TESTING
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (r) => false);
    }
  }

  Future<void> verifyOtpAndLogin(String verificationId, String smsCode, BuildContext context) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (r) => false);
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (r) => false);
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (r) => false);
    }
  }

  /// Smart post-login navigation: skip onboarding if already completed
  Future<void> _navigateAfterLogin(String uid, BuildContext context) async {
    final onboarded = await _authRepository.hasCompletedOnboarding(uid);
    if (!context.mounted) return;
    if (onboarded) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (r) => false);
    }
  }
}
