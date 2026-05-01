import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  UnityWidgetController? _unityWidgetController;

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, 
        child: UnityWidget(
          onUnityCreated: onUnityCreated,
          onUnityMessage: onUnityMessage,
          onUnitySceneLoaded: onUnitySceneLoaded,
          // fullscreen: true, // В некоторых версиях плагина можно включить этот флаг
          useAndroidViewSurface: true, // Рекомендуется для стабильности на Android
        ),
      ),
    );
  }

  // Вызывается, когда виджет Unity создан
  void onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  // Здесь ты можешь принимать сообщения из Unity (например, результаты лабы)
  void onUnityMessage(message) {
    print('Сообщение от Unity: ${message.toString()}');
  }

  // Вызывается, когда сцена внутри Unity полностью загружена
  void onUnitySceneLoaded(SceneLoaded? scene) {
    print('Сцена загружена: ${scene?.name}');
  }
}