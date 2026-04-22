import 'package:flutter/material.dart';

class AdminState {
  // シングルトンパターンでどこからでもアクセス可能に
  static final AdminState _instance = AdminState._internal();
  factory AdminState() => _instance;
  AdminState._internal();

  // 管理者モードがONかどうかを保持する（初期値はOFF）
  final ValueNotifier<bool> isModeEnabled = ValueNotifier<bool>(false);

  void toggleMode() {
    isModeEnabled.value = !isModeEnabled.value;
  }
}
