# RAF Helper — Flutter (frontend)

Клиент для чат-ассистента студентов БГУ: авторизация Firebase, сессии чатов и вызовы backend API (FastAPI).

## Что уже сделано

| Область | Статус |
|--------|--------|
| **Firebase Auth** | Регистрация, вход, отправка письма верификации, экран «Подтвердите email», повторная отправка, проверка после клика по ссылке |
| **Связка с backend** | После верификации: `getIdToken()` → `Authorization: Bearer` → `POST /auth/sync` (пользователь в PostgreSQL) |
| **Чаты** | Список чатов (боковая панель), создание, удаление, загрузка истории `GET /chats/{id}/messages` |
| **Сообщения** | `POST /chats/{id}/messages` с телом `message`, опционально `agent`, `summarization_mode` |
| **Быстрые сценарии** | Шесть карточек (QA, Events, Staff, Summarizer, Abstract, Presentation) — запрос уходит с выбранным `agent`, чтобы обойти незавершённый авто-роутинг на backend |

## Что ещё не в UI / в планах

| Область | Статус |
|--------|--------|
| **Загрузка файлов** | В `ApiService` есть `uploadFile`, кнопка «скрепка» в чате не подключена |
| **Контекст чата** | Backend умеет `is_web_search_enabled` и привязку файлов к чату; в приложении нет переключателя веб-поиска и экрана выбора документов |
| **Режимы саммари** | Всегда `default`; нет выбора brief / deep_dive |
| **Свободный текст без агента** | Если на backend не реализован оркестратор-роутер, ответ может быть с ошибкой — используйте quick actions или явный выбор агента (когда появится в UI) |
| **Push-уведомления** | Не реализованы |

## Стек

- Flutter 3.x, Dart 3.x
- `provider` — состояние
- `dio` — HTTP
- `firebase_core`, `firebase_auth` — вход и токены
- `google_fonts` — Inter

## Настройка Firebase

1. В [Firebase Console](https://console.firebase.google.com) включите **Authentication → Email/Password**.
2. Добавьте **Web**-приложение и скопируйте конфиг в [`lib/firebase_options.dart`](lib/firebase_options.dart) (или выполните `flutterfire configure`).

Без заполненного `firebase_options.dart` приложение не стартует.

## Настройка API

По умолчанию базовый URL: **`http://localhost:8000`** (без префикса `/api`).

Изменить: конструктор `ApiService` в [`lib/services/api_service.dart`](lib/services/api_service.dart) или передать свой `ApiService(baseUrl: 'https://your-api.example.com')` при инициализации `AuthService`.

На стенде укажите HTTPS-адрес бэкенда и добавьте этот origin в `ALLOWED_ORIGINS` на сервере.

## Запуск

```bash
cd raf-helper-frontend
flutter pub get
flutter run -d chrome
# или: flutter run -d windows
```

## Связанный репозиторий

Backend: отдельный проект FastAPI (`raf-helper-backend`) — эндпоинты `/auth/*`, `/chats/*`, `/files/*` и др.
