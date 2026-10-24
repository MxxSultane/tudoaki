import 'package:flutter_riverpod/flutter_riverpod.dart';

final financeClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
