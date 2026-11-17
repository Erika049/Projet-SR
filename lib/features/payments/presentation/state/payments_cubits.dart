import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/view_status.dart';
import '../../domain/entities/payments.dart';
import '../../domain/usecases/payments_usecases.dart';

/// Onglet « Paiements » du parent (CU-PAR-10).
class FinancialSituationCubit extends Cubit<DataState<FinancialSituation>> {
  FinancialSituationCubit(this._get) : super(const DataState());
  final GetFinancialSituation _get;
  String? _childId;

  Future<void> load(String childId) async {
    _childId = childId;
    emit(const DataState(status: ViewStatus.loading));
    final result = await _get(childId);
    emit(result.fold(state.error, state.success));
  }

  Future<void> reload() async {
    if (_childId != null) await load(_childId!);
  }
}

/// « Reçus et historique » (CU-PAR-12).
class PaymentHistoryCubit extends Cubit<DataState<List<PaymentRecord>>> {
  PaymentHistoryCubit(this._get, this._download) : super(const DataState());
  final GetPaymentHistory _get;
  final DownloadReceipt _download;

  Future<void> load(String childId) async {
    emit(const DataState(status: ViewStatus.loading));
    final result = await _get(childId);
    emit(result.fold(state.error, state.success));
  }

  Future<String> download(PaymentRecord p) async {
    final result = await _download(p);
    return result.fold((f) => f.message, (file) => 'Reçu téléchargé : $file');
  }
}

/// « Déclarer un paiement » (CU-PAR-11).
class DeclarePaymentCubit extends Cubit<SubmitState> {
  DeclarePaymentCubit(this._declare) : super(const SubmitState());
  final DeclarePayment _declare;

  Future<void> submit(DeclarePaymentParams params) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _declare(params);
    emit(result.fold(
      (f) => SubmitState(status: ViewStatus.failure, error: f.message),
      (_) => const SubmitState(status: ViewStatus.success),
    ));
  }
}
