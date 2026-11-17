import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Statut de chargement commun aux états des écrans.
enum ViewStatus {
  initial,
  loading,
  success,
  failure;

  bool get isLoading => this == loading;
}

/// État générique d'un écran qui charge une donnée [T].
class DataState<T> extends Equatable {
  const DataState({this.status = ViewStatus.initial, this.data, this.failure});

  final ViewStatus status;
  final T? data;
  final Failure? failure;

  DataState<T> loading() => DataState(status: ViewStatus.loading, data: data);
  DataState<T> success(T value) => DataState(status: ViewStatus.success, data: value);
  DataState<T> error(Failure f) => DataState(status: ViewStatus.failure, data: data, failure: f);

  @override
  List<Object?> get props => [status, data, failure];
}

/// État générique d'un formulaire envoyé au serveur.
class SubmitState extends Equatable {
  const SubmitState({this.status = ViewStatus.initial, this.error});

  final ViewStatus status;
  final String? error;

  bool get isSubmitting => status == ViewStatus.loading;
  bool get isDone => status == ViewStatus.success;

  @override
  List<Object?> get props => [status, error];
}
