import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyStatusState {
  final bool isFinanceClosed;
  final bool isHealthSaved;
  final bool isMindSaved;
  final bool isWorkSaved;

  DailyStatusState({
    this.isFinanceClosed = false,
    this.isHealthSaved = false,
    this.isMindSaved = false,
    this.isWorkSaved = false,
  });

  DailyStatusState copyWith({
    bool? isFinanceClosed,
    bool? isHealthSaved,
    bool? isMindSaved,
    bool? isWorkSaved,
  }) {
    return DailyStatusState(
      isFinanceClosed: isFinanceClosed ?? this.isFinanceClosed,
      isHealthSaved: isHealthSaved ?? this.isHealthSaved,
      isMindSaved: isMindSaved ?? this.isMindSaved,
      isWorkSaved: isWorkSaved ?? this.isWorkSaved,
    );
  }
}

class DailyStatusNotifier extends Notifier<DailyStatusState> {
  @override
  DailyStatusState build() {
    return DailyStatusState();
  }

  void setFinanceClosed(bool value) {
    state = state.copyWith(isFinanceClosed: value);
  }

  void setHealthSaved(bool value) {
    state = state.copyWith(isHealthSaved: value);
  }

  void setMindSaved(bool value) {
    state = state.copyWith(isMindSaved: value);
  }

  void setWorkSaved(bool value) {
    state = state.copyWith(isWorkSaved: value);
  }
}

final dailyStatusProvider =
    NotifierProvider<DailyStatusNotifier, DailyStatusState>(
      DailyStatusNotifier.new,
    );
