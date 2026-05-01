using UnityEngine;
using System.Linq;

public class FlutterNavigationBridge : MonoBehaviour
{
    public static FlutterNavigationBridge instance;

    private string _pendingRoom; // Номер аудитории из Flutter
    private bool _isReady = false; // Флаг успешной локализации

    private void Awake()
    {
        // Стандартный синглтон, чтобы Flutter мог найти объект
        if (instance == null) instance = this;
    }

    // Этот метод вызывает Flutter
    public void SetRouteFromFlutter(string roomName)
    {
        Debug.Log("Bridge: Flutter запросил маршрут до " + roomName);
        _pendingRoom = roomName;

        // Если AR уже локализован (например, повторный запрос), строим сразу
        TryExecuteAutoNavigation();
    }

    // Этот метод привязан в Инспекторе
    public void OnLocalizationSuccess()
    {
        Debug.Log("Bridge: Получен сигнал об успешной локализации.");
        _isReady = true;
        TryExecuteAutoNavigation();
    }

    private void TryExecuteAutoNavigation()
    {
        // Ждем, пока совпадут оба условия: есть цель и есть локализация
        if (string.IsNullOrEmpty(_pendingRoom) || !_isReady)
        {
            Debug.Log("Bridge: Ожидание готовности (Room: " + _pendingRoom + ", AR Ready: " + _isReady + ")");
            return;
        }

        // Проверка готовности систем навигации (синглтонов)
        if (NavigationController.instance == null || NavigationUIController.instance == null)
        {
            Debug.LogError("Bridge: Ошибка! На сцене нет NavigationController или NavigationUIController.");
            return;
        }

        // Получаем список всех точек из дополненного пространства
        POI[] allPois = NavigationController.instance.augmentedSpace.GetPOIs();

        // Поиск аудитории по имени или ID
        POI target = allPois.FirstOrDefault(p =>
            p.poiName.Trim().ToLower() == _pendingRoom.Trim().ToLower() ||
            p.identification.ToString() == _pendingRoom.Trim()
        );

        if (target != null)
        {
            Debug.Log("Bridge: Точка найдена. Запуск построения маршрута к " + target.poiName);

            // Имитируем нажатие кнопки в UI навигации
            NavigationUIController.instance.ClickedStartNavigation(target);

            // Очищаем запрос, чтобы не строить маршрут заново при фоновой перелокализации
            _pendingRoom = null;
        }
        else
        {
            Debug.LogError("Bridge: POI с именем/ID '" + _pendingRoom + "' не найден на карте.");
        }
    }
}