import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/establishment.dart';
import '../../domain/usecases/auth_usecases.dart';

enum SessionStatus { unknown, unauthenticated, choosingEstablishment, authenticated, expired }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.user, this.establishment});

  final SessionStatus status;
  final AppUser? user;
  final Establishment? establishment;

  @override
  List<Object?> get props => [status, user, establishment];
}

/// Session globale : qui est connecté, avec quel rôle, dans quel établissement.
/// Le routeur s'appuie sur cet état pour rediriger.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required RestoreSession restoreSession,
    required GetEstablishments getEstablishments,
    required GetSelectedEstablishment getSelectedEstablishment,
    required SelectEstablishment selectEstablishment,
    required Logout logout,
  }) : _restore = restoreSession,
       _getEstablishments = getEstablishments,
       _getSelected = getSelectedEstablishment,
       _select = selectEstablishment,
       _logout = logout,
       super(const SessionState());

  final RestoreSession _restore;
  final GetEstablishments _getEstablishments;
  final GetSelectedEstablishment _getSelected;
  final SelectEstablishment _select;
  final Logout _logout;

  Future<void> restore() async {
    final result = await _restore(const NoParams());
    final user = result.fold((_) => null, (u) => u);
    if (user == null) return emit(const SessionState(status: SessionStatus.unauthenticated));
    await signedIn(user);
  }

  /// Appelé après une connexion ou une vérification OTP réussie.
  Future<void> signedIn(AppUser user) async {
    if (user.isParent) {
      return emit(SessionState(status: SessionStatus.authenticated, user: user));
    }
    final saved = await _getSelected();
    if (saved != null) {
      return emit(SessionState(status: SessionStatus.authenticated, user: user, establishment: saved));
    }
    final result = await _getEstablishments(const NoParams());
    final list = result.fold((_) => const <Establishment>[], (l) => l);
    if (list.length == 1) return chooseEstablishment(list.first, user: user);
    emit(SessionState(status: SessionStatus.choosingEstablishment, user: user));
  }

  Future<void> chooseEstablishment(Establishment e, {AppUser? user}) async {
    await _select(e);
    emit(SessionState(status: SessionStatus.authenticated, user: user ?? state.user, establishment: e));
  }

  /// Permet à l'enseignant de changer d'établissement depuis son profil.
  void switchEstablishment() => emit(SessionState(status: SessionStatus.choosingEstablishment, user: state.user));

  /// Le serveur a refusé le jeton : écran « Session expirée ».
  void expire() => emit(SessionState(status: SessionStatus.expired, user: state.user));

  Future<void> logout() async {
    await _logout();
    emit(const SessionState(status: SessionStatus.unauthenticated));
  }
}
