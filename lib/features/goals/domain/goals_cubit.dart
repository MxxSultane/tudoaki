import 'package:flutter_bloc/flutter_bloc.dart';

class GoalsCubit extends Cubit<bool> {
  GoalsCubit() : super(false);
  void completed(bool value) => emit(value);
}
