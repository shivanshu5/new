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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.verifyPhone(
        phoneNumber: phoneNumber,
        codeSent: (String verificationId, int? _) {
          state = state.copyWith(isLoading: false, verificationId: verificationId);
          Navigator.pushNamed(context, AppRoutes.otp, arguments: verificationId);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            isLoading: false,
            error: e.message ?? 'Failed to send OTP',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error. Please try again.');
    }
  }

  Future<void> verifyOtpAndLogin(String verificationId, String smsCode, BuildContext context) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _authService.signInWithPhoneOtp(verificationId, smsCode);
      if (cred.user != null) {
        await _authRepository.saveUserRecordIfNew(cred.user!);
        await _navigateAfterLogin(cred.user!.uid, context);
      }
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Invalid OTP. Please check and retry.');
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred?.user != null) {
        await _authRepository.saveUserRecordIfNew(cred!.user!);
        await _navigateAfterLogin(cred.user!.uid, context);
      } else {
        // User cancelled sign in
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Google sign in failed. Please try again.');
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _authService.signInWithApple();
      if (cred?.user != null) {
        await _authRepository.saveUserRecordIfNew(cred!.user!);
        await _navigateAfterLogin(cred.user!.uid, context);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Apple sign in failed. Please try again.');
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
