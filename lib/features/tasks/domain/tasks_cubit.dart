import 'package:flutter_bloc/flutter_bloc.dart';

class TasksCubit extends Cubit<bool> {
  TasksCubit() : super(false);
  void completed(bool value) => emit(value);
}
