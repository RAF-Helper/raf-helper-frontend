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
              onUnitySceneLoaded: onUnitySceneLoaded, // Вынесли в отдельный метод
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  void onUnityCreated(UnityWidgetController controller) {
    setState(() {
      _unityWidgetController = controller;
    });
    print("FLUTTER: Контроллер Unity успешно создан.");
    
    // Безопасный дублирующий вызов: если сцена уже была в памяти, 
    // отправляем аудиторию сразу при создании контроллера
    if (widget.roomNumber != null) {
      print("FLUTTER: Обнаружена аудитория при старте: ${widget.roomNumber}");
      sendRouteToUnity(widget.roomNumber!);
    }
  }

  void onUnitySceneLoaded(SceneLoaded? scene) async {
    print("FLUTTER: Сцена Unity загрузилась. Имя: ${scene?.name}");
    
    // Небольшая искусственная задержка (микротаск), чтобы дать мосту связи "прогреться"
    await Future.delayed(const Duration(milliseconds: 300));

    if (widget.roomNumber != null) {
      sendRouteToUnity(widget.roomNumber!);
    }
  }

  void sendRouteToUnity(String roomNumber) {
    if (_unityWidgetController != null) {
      print("FLUTTER: Отправляю postMessage в Unity. Объект: FlutterBridge, Метод: SetRouteFromFlutter, Значение: $roomNumber");
      _unityWidgetController!.postMessage(
        'FlutterBridge',      // Убедись, что этот GameObject ЕСТЬ на сцене в Unity!
        'SetRouteFromFlutter', // Убедись, что этот метод есть в C# скрипте на этом объекте!
        roomNumber,           
      );
    } else {
      print("FLUTTER: Ошибка! Попытка отправить данные, но _unityWidgetController еще NULL.");
    }
  }
}