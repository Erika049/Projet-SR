import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/view_status.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/establishment.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Écran « Connexion ».
class LoginCubit extends Cubit<SubmitState> {
  LoginCubit(this._login) : super(const SubmitState());
  final Login _login;

  /// Retourne l'utilisateur connecté, ou `null` en cas d'échec.
  Future<AppUser?> submit(String identifier, String password) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _login((identifier: identifier, password: password));
    return result.fold(
      (f) {
        emit(SubmitState(status: ViewStatus.failure, error: f.message));
        return null;
      },
      (user) {
        emit(const SubmitState(status: ViewStatus.success));
        return user;
      },
    );
  }
}

/// Écran « Créer un compte » (étape 1).
class RegisterCubit extends Cubit<SubmitState> {
  RegisterCubit(this._register) : super(const SubmitState());
  final RegisterParent _register;

  Future<bool> submit(RegisterParams params) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _register(params);
    return result.fold(
      (f) {
        emit(SubmitState(status: ViewStatus.failure, error: f.message));
        return false;
      },
      (_) {
        emit(const SubmitState(status: ViewStatus.success));
        return true;
      },
    );
  }
}

class OtpState extends Equatable {
  const OtpState({this.submit = const SubmitState(), this.secondsLeft = 0});

  final SubmitState submit;
  final int secondsLeft;

  bool get canResend => secondsLeft == 0;

  @override
  List<Object?> get props => [submit, secondsLeft];
}

/// Écran « Vérification » (étape 2) avec minuteur de renvoi du code.
class OtpCubit extends Cubit<OtpState> {
  OtpCubit(this._verify, this._resend, this.phone) : super(const OtpState()) {
    _startTimer();
  }

  final VerifyOtp _verify;
  final ResendOtp _resend;
  final String phone;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    emit(OtpState(submit: state.submit, secondsLeft: AppConstants.otpResendDelay.inSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.secondsLeft - 1;
      emit(OtpState(submit: state.submit, secondsLeft: left < 0 ? 0 : left));
      if (left <= 0) t.cancel();
    });
  }

  Future<AppUser?> verify(String code) async {
    emit(
      OtpState(
        submit: const SubmitState(status: ViewStatus.loading),
        secondsLeft: state.secondsLeft,
      ),
    );
    final result = await _verify((phone: phone, code: code));
    return result.fold((f) {
      emit(
        OtpState(
          submit: SubmitState(status: ViewStatus.failure, error: f.message),
          secondsLeft: state.secondsLeft,
        ),
      );
      return null;
    }, (user) => user);
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    await _resend(phone);
    _startTimer();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

/// Écran « Mot de passe oublié ».
class ForgotPasswordCubit extends Cubit<SubmitState> {
  ForgotPasswordCubit(this._request) : super(const SubmitState());
  final RequestPasswordReset _request;

  Future<void> submit(String identifier) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _request(identifier);
    emit(
      result.fold(
        (f) => SubmitState(status: ViewStatus.failure, error: f.message),
        (_) => const SubmitState(status: ViewStatus.success),
      ),
    );
  }
}

/// Écran « Choisir un établissement ».
class EstablishmentsCubit extends Cubit<DataState<List<Establishment>>> {
  EstablishmentsCubit(this._get) : super(const DataState());
  final GetEstablishments _get;

  Future<void> load() async {
    emit(state.loading());
    final result = await _get(const NoParams());
    emit(result.fold(state.error, state.success));
  }
}
