import 'package:flutter_bloc/flutter_bloc.dart';

enum PlanKind { task, event }

DateTime weekMonday(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);

class WeeklySelection {
  const WeeklySelection(this.monday, this.dayIndex, this.kind);
  final DateTime monday;
  final int dayIndex;
  final PlanKind kind;
  DateTime get day =>
      DateTime(monday.year, monday.month, monday.day + dayIndex);
  DateTime get end => DateTime(monday.year, monday.month, monday.day + 6);
}

class WeeklyPlannerCubit extends Cubit<WeeklySelection> {
  WeeklyPlannerCubit(DateTime now) : super(_initial(now));
  static final firstDay = DateTime(2000);
  static final lastDay = DateTime(2100, 12, 31);
  static DateTime _bound(DateTime day) => day.isBefore(firstDay)
      ? firstDay
      : day.isAfter(lastDay)
      ? lastDay
      : day;
  static WeeklySelection _initial(DateTime now) {
    final date = _bound(DateTime(now.year, now.month, now.day));
    final first = weekMonday(date);
    // Sunday planning starts on the following Monday; explicit date selection
    // below always opens the week containing the selected date.
    final monday = now.weekday == DateTime.sunday
        ? DateTime(first.year, first.month, first.day + 7)
        : first;
    final selected = _bound(monday);
    final start = weekMonday(selected);
    return WeeklySelection(start, selected.weekday - 1, PlanKind.task);
  }

  bool get canPrevious => state.monday.isAfter(weekMonday(firstDay));
  bool get canNext => state.monday.isBefore(weekMonday(lastDay));
  bool allowed(DateTime day) =>
      !day.isBefore(firstDay) && !day.isAfter(lastDay);
  void kind(PlanKind value) =>
      emit(WeeklySelection(state.monday, state.dayIndex, value));
  void selectDay(int index) {
    if (index < 0 || index > 6) throw ArgumentError.value(index);
    final day = DateTime(
      state.monday.year,
      state.monday.month,
      state.monday.day + index,
    );
    if (allowed(day)) emit(WeeklySelection(state.monday, index, state.kind));
  }

  void selectDate(DateTime value) {
    final day = _bound(DateTime(value.year, value.month, value.day));
    emit(WeeklySelection(weekMonday(day), day.weekday - 1, state.kind));
  }

  void move(int direction) {
    if (direction != -1 && direction != 1) throw ArgumentError.value(direction);
    if (direction == -1 && !canPrevious || direction == 1 && !canNext) return;
    selectDate(
      DateTime(state.day.year, state.day.month, state.day.day + 7 * direction),
    );
  }
}
