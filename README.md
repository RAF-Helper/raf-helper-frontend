# RAF Helper Frontend

Flutter приложение для чат-ассистента RAF на БГУ.

## Функции

- Авторизация через Firebase (только @bsu.by)
- Темный UI в стиле современных мессенджеров
- Быстрые действия (карточки для популярных сценариев)
- Чат с LLM агентами
- Загрузка файлов

## Стек

- Flutter 3.0+
- Provider для state management
- Dio для HTTP запросов
- Firebase Auth
- Google Fonts (Inter)

## Запуск

```bash
cd raf-helper-frontend
flutter pub get
flutter run
```

## Backend API

По умолчанию подключается к `http://localhost:8000/api`.

Измените в `lib/services/api_service.dart` если нужно.

## TODO

1. Интеграция с Firebase Auth (регистрация, логин, верификация email)
2. Подключение к backend API
3. Загрузка файлов
4. Выбор агента (QA, Events, Staff, Summarizer, etc.)
5. Настройки контекста чата (веб-поиск, документы)
6. История чатов
7. Push-уведомления

## UI Reference

UI основан на дизайне чат-ботов банков с темной темой, карточками быстрых действий и bubble-сообщениями.
