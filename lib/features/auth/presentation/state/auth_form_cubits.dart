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

  /// `ok` : compte créé. `user` : session déjà ouverte par le serveur ;
  /// `null` : il faut encore vérifier le code SMS.
  Future<({bool ok, AppUser? user})> submit(RegisterParams params) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _register(params);
    return result.fold(
      (f) {
        emit(SubmitState(status: ViewStatus.failure, error: f.message));
        return (ok: false, user: null);
      },
      (user) {
        emit(const SubmitState(status: ViewStatus.success));
        return (ok: true, user: user);
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

/// Minuteur « Renvoyer le code dans 00:45 » commun aux écrans de code SMS.
mixin ResendCountdown on Cubit<OtpState> {
  Timer? _timer;

  void startCountdown() {
    _timer?.cancel();
    emit(OtpState(submit: state.submit, secondsLeft: AppConstants.otpResendDelay.inSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.secondsLeft - 1;
      emit(OtpState(submit: state.submit, secondsLeft: left < 0 ? 0 : left));
      if (left <= 0) t.cancel();
    });
  }

  void emitSubmit(SubmitState submit) => emit(OtpState(submit: submit, secondsLeft: state.secondsLeft));

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

/// Écran « Vérification » (étape 2) avec minuteur de renvoi du code.
class OtpCubit extends Cubit<OtpState> with ResendCountdown {
  OtpCubit(this._verify, this._resend, this.phone) : super(const OtpState()) {
    startCountdown();
  }

  final VerifyOtp _verify;
  final ResendOtp _resend;
  final String phone;

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
    startCountdown();
  }
}

/// Mot de passe oublié — étape 1 : numéro de téléphone.
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

/// Mot de passe oublié — étape 2 : code SMS, avec renvoi possible.
class ResetCodeCubit extends Cubit<OtpState> with ResendCountdown {
  ResetCodeCubit(this._verify, this._request, this.phone) : super(const OtpState()) {
    startCountdown();
  }

  final VerifyResetCode _verify;
  final RequestPasswordReset _request;
  final String phone;

  /// Retourne le jeton de réinitialisation, ou `null` si le code est refusé.
  Future<String?> verify(String code) async {
    emitSubmit(const SubmitState(status: ViewStatus.loading));
    final result = await _verify((phone: phone, code: code));
    return result.fold(
      (f) {
        emitSubmit(SubmitState(status: ViewStatus.failure, error: f.message));
        return null;
      },
      (token) {
        emitSubmit(const SubmitState(status: ViewStatus.success));
        return token;
      },
    );
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    await _request(phone);
    startCountdown();
  }
}

/// Mot de passe oublié — étape 3 : nouveau mot de passe.
class NewPasswordCubit extends Cubit<SubmitState> {
  NewPasswordCubit(this._reset) : super(const SubmitState());
  final ResetPassword _reset;

  Future<void> submit(ResetPasswordParams params) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _reset(params);
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
