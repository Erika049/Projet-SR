import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/view_status.dart';
import '../../domain/entities/notifications.dart';
import '../../domain/usecases/notifications_usecases.dart';

class NotificationsCubit extends Cubit<DataState<NotificationFeed>> {
  NotificationsCubit(this._get, this._markRead) : super(const DataState());

  final GetNotifications _get;
  final MarkNotificationsRead _markRead;

  Future<void> load() async {
    emit(state.loading());
    final result = await _get(const NoParams());
    emit(result.fold(state.error, state.success));
    if (state.data?.fromCache == false) await _markRead(const NoParams());
  }
}

class PreferencesCubit extends Cubit<DataState<NotificationPreferences>> {
  PreferencesCubit(this._get, this._save) : super(const DataState());

  final GetNotificationPreferences _get;
  final SaveNotificationPreferences _save;

  Future<void> load(String childId) async {
    emit(state.loading());
    final result = await _get(childId);
    emit(result.fold(state.error, state.success));
  }

  /// Active/désactive un canal globalement.
  Future<String?> toggleChannel(NotificationChannel c) async {
    final p = state.data;
    if (p == null) return null;
    final channels = {...p.channels};
    channels.contains(c) ? channels.remove(c) : channels.add(c);
    final byType = {
      for (final e in p.byType.entries) e.key: channels.contains(c) ? e.value : ({...e.value}..remove(c)),
    };
    return _apply(p.copyWith(channels: channels, byType: byType));
  }

  /// Active/désactive un canal pour un type d'alerte.
  Future<String?> toggle(NotificationType type, NotificationChannel c) async {
    final p = state.data;
    if (p == null || !p.channels.contains(c)) return 'Activez d’abord le canal ${c.label}.';
    final current = {...?p.byType[type]};
    current.contains(c) ? current.remove(c) : current.add(c);
    return _apply(p.copyWith(byType: {...p.byType, type: current}));
  }

  Future<String?> _apply(NotificationPreferences updated) async {
    final result = await _save(updated);
    return result.fold((f) => f.message, (_) {
      emit(state.success(updated));
      return null;
    });
  }
}

class AnnouncementsCubit extends Cubit<DataState<List<Announcement>>> {
  AnnouncementsCubit(this._get) : super(const DataState());
  final GetAnnouncements _get;

  Future<void> load() async {
    emit(state.loading());
    final result = await _get(const NoParams());
    emit(result.fold(state.error, state.success));
  }
}
