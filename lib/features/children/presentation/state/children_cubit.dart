import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/view_status.dart';
import '../../domain/entities/child.dart';
import '../../domain/usecases/children_usecases.dart';

class ChildrenState extends Equatable {
  const ChildrenState({
    this.status = ViewStatus.initial,
    this.children = const [],
    this.requests = const [],
    this.selectedId,
    this.failure,
  });

  final ViewStatus status;
  final List<Child> children;
  final List<LinkRequest> requests;

  /// Enfant affiché dans « Suivi » (partagé entre Notes, Présences, Paiements).
  final String? selectedId;
  final Failure? failure;

  Child? get selected => children.where((c) => c.id == selectedId).firstOrNull ?? children.firstOrNull;

  Child? byId(String id) => children.where((c) => c.id == id).firstOrNull;

  ChildrenState copyWith({
    ViewStatus? status,
    List<Child>? children,
    List<LinkRequest>? requests,
    String? selectedId,
    Failure? failure,
  }) => ChildrenState(
    status: status ?? this.status,
    children: children ?? this.children,
    requests: requests ?? this.requests,
    selectedId: selectedId ?? this.selectedId,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, children, requests, selectedId, failure];
}

/// Enfants du parent connecté. Fourni au niveau de l'espace Parent.
class ChildrenCubit extends Cubit<ChildrenState> {
  ChildrenCubit({
    required GetChildren getChildren,
    required GetLinkRequests getLinkRequests,
    required LinkChild linkChild,
    required UnlinkChild unlinkChild,
    required RequestCorrection requestCorrection,
  }) : _getChildren = getChildren,
       _getRequests = getLinkRequests,
       _link = linkChild,
       _unlink = unlinkChild,
       _correction = requestCorrection,
       super(const ChildrenState());

  final GetChildren _getChildren;
  final GetLinkRequests _getRequests;
  final LinkChild _link;
  final UnlinkChild _unlink;
  final RequestCorrection _correction;

  /// [silent] : actualisation en arrière-plan, sans repasser par l'état « chargement ».
  Future<void> load({bool silent = false}) async {
    if (!silent || state.status != ViewStatus.success) emit(state.copyWith(status: ViewStatus.loading));
    final children = await _getChildren(const NoParams());
    final requests = await _getRequests(const NoParams());
    if (isClosed) return;
    children.fold(
      (f) => silent && state.children.isNotEmpty ? null : emit(state.copyWith(status: ViewStatus.failure, failure: f)),
      (list) => emit(
        state.copyWith(
          status: ViewStatus.success,
          children: list,
          requests: requests.fold((_) => state.requests, (r) => r),
        ),
      ),
    );
  }

  void select(String childId) => emit(state.copyWith(selectedId: childId));

  /// Retourne un message d'erreur, ou `null` si la demande a été envoyée.
  Future<String?> link(String code) async {
    final result = await _link(code);
    return result.fold((f) => f.message, (request) {
      emit(state.copyWith(requests: [...state.requests, request]));
      return null;
    });
  }

  Future<String?> unlink(String childId) async {
    final result = await _unlink(childId);
    return result.fold((f) => f.message, (_) {
      emit(state.copyWith(children: state.children.where((c) => c.id != childId).toList()));
      return null;
    });
  }

  Future<String?> requestCorrection(String childId, String message) async {
    final result = await _correction((childId: childId, message: message));
    return result.fold((f) => f.message, (_) => null);
  }
}
