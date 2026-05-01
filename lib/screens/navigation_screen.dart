import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class NavigationScreen extends StatefulWidget {
  final String? roomNumber;

  const NavigationScreen({super.key, this.roomNumber});

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
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: UnityWidget(
              onUnityCreated: onUnityCreated,
              onUnitySceneLoaded: (scene) {
                if (widget.roomNumber != null) {
                  sendRouteToUnity(widget.roomNumber!);
                }
              },
              useAndroidViewSurface: true,
            ),
          ),
          Positioned(
            top: 20,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 15, color: Colors.black)], 
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Вызывается, когда виджет Unity создан
  void onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  void sendRouteToUnity(String roomNumber) {
    if (_unityWidgetController != null) {
      _unityWidgetController!.postMessage(
        'FlutterBridge',      // Имя объекта в Unity
        'SetRouteFromFlutter', // Имя метода в C# скрипте
        roomNumber,           // Значение (номер аудитории)
      );
    }
  }
}