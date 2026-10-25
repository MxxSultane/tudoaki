import 'package:flutter_bloc/flutter_bloc.dart';

class AgendaSelection {
  const AgendaSelection(this.day, [this.mode = 'Dia']);
  final DateTime day;
  final String mode;
}

class AgendaCubit extends Cubit<AgendaSelection> {
  AgendaCubit(DateTime today)
    : super(AgendaSelection(DateTime(today.year, today.month, today.day)));
  void select(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final first = DateTime(2000), last = DateTime(2100, 12, 31);
    emit(
      AgendaSelection(
        date.isBefore(first)
            ? first
            : date.isAfter(last)
            ? last
            : date,
        state.mode,
      ),
    );
  }

  void mode(String value) => emit(AgendaSelection(state.day, value));
  void move(int direction) {
    final day = state.day;
    select(
      state.mode == 'Mês'
          ? DateTime(day.year, day.month + direction, 1)
          : DateTime(
              day.year,
              day.month,
              day.day + direction * (state.mode == 'Semana' ? 7 : 1),
            ),
    );
  }
}
