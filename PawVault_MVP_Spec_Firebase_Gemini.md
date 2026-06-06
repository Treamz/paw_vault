# ТЗ: MVP приложения “Архив питомца” / PawVault

## 1. Цель продукта

Создать мобильное приложение для владельцев питомцев, где можно хранить всю важную информацию о здоровье, документах и уходе за животным в одном месте.

Основная ценность: пользователь быстро находит историю питомца, не забывает важные даты, может показать ветеринару структурированную информацию и быстро добавлять новые данные через скан документа или обычное текстовое сообщение.

## 2. Платформа и стек

- Flutter
- iOS / Android
- Feature-based architecture
- Bloc/Cubit
- AutoRoute
- Backend: Firebase
- Authentication: Firebase Auth
- Database: Cloud Firestore
- Files: Firebase Storage
- AI: Firebase AI Logic / Gemini
- Offline support: Firestore offline persistence
- Язык интерфейса: английский
- Поддержка светлой и тёмной темы

## 3. Основные сущности

### Pet

- id
- userId
- name
- species
- breed
- birthDate
- gender
- weight
- microchipNumber
- photoUrl
- allergies
- chronicConditions
- notes
- createdAt
- updatedAt

### PetEvent

- id
- userId
- petId
- type
- title
- description
- date
- nextReminderDate
- attachments
- source
- createdAt
- updatedAt

Типы событий:

- vaccination
- vetVisit
- medication
- labTest
- surgery
- symptom
- grooming
- food
- allergy
- documentAdded
- other

Возможные значения `source`:

- manual
- smartText
- documentScan
- imported

### Document

- id
- userId
- petId
- title
- type
- fileUrl
- storagePath
- extractedText
- extractedData
- issueDate
- expiryDate
- notes
- linkedEventId
- createdAt
- updatedAt

Типы документов:

- passport
- vaccinationCertificate
- insurance
- labResult
- prescription
- receipt
- vetReport
- other

### Reminder

- id
- userId
- petId
- title
- description
- dateTime
- repeatType
- relatedEventId
- isCompleted
- createdAt
- updatedAt

### SmartMessage

Пользовательское текстовое сообщение, которое приложение анализирует через Gemini и превращает в структурированные данные.

Примеры:

- “My corgi is allergic to chicken”
- “Bella had a rabies vaccine today, next one in a year”
- “Give Max 1 tablet of NexGard every month”
- “Charlie vomited twice yesterday after eating beef”

Поля:

- id
- userId
- petId
- originalText
- detectedIntent
- extractedData
- suggestedActions
- confidence
- status
- createdAt

Возможные detectedIntent:

- addAllergy
- addMedication
- addVaccination
- addSymptom
- addVetVisit
- addReminder
- addNote
- unknown

## 4. Firebase Backend

### 4.1 Firebase Services

Для MVP использовать Firebase как основной backend.

Обязательные сервисы:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase AI Logic / Gemini
- Firebase Security Rules

Опционально позже:

- Firebase App Check
- Cloud Functions
- Firebase Cloud Messaging
- Firebase Analytics
- Crashlytics

### 4.2 Authentication

MVP auth options:

- Anonymous Auth для быстрого старта
- Apple Sign In для iOS
- Google Sign In опционально

Рекомендованный MVP-подход:

1. При первом запуске создавать anonymous user.
2. Все данные привязывать к `uid`.
3. Позже дать пользователю возможность привязать Apple/Google аккаунт.
4. Не блокировать использование приложения обязательной регистрацией.

### 4.3 Firestore Data Structure

Рекомендуемая структура:

```text
users/{userId}
  pets/{petId}
    events/{eventId}
    documents/{documentId}
    reminders/{reminderId}
    smartMessages/{messageId}
```

Для MVP предпочтительнее nested structure под `users/{userId}`, потому что проще писать security rules.

### 4.4 Firebase Storage Structure

Файлы хранить так:

```text
users/{userId}/pets/{petId}/documents/{documentId}/original.pdf
users/{userId}/pets/{petId}/documents/{documentId}/scan.jpg
users/{userId}/pets/{petId}/photos/profile.jpg
users/{userId}/pets/{petId}/exports/vet_summary.pdf
```

### 4.5 Security Rules

Правила:

- пользователь может читать и писать только свои данные;
- доступ к данным питомцев только по `request.auth.uid`;
- файлы в Storage доступны только владельцу;
- public sharing не входит в MVP.

### 4.6 Offline Mode

Firestore offline persistence использовать как базовый offline layer.

Поведение:

- данные должны быть доступны после перезапуска приложения;
- если нет интернета, пользователь может просматривать ранее загруженные данные;
- новые изменения синхронизируются после восстановления сети.

### 4.7 Repository Layer

UI и Cubit не должны напрямую работать с Firebase SDK.

Нужны abstraction layers:

- AuthRepository
- PetRepository
- EventRepository
- DocumentRepository
- ReminderRepository
- StorageRepository
- AiRepository
- SmartInputRepository

Firebase-specific код должен находиться в `data/datasources`.

## 5. Firebase AI Logic / Gemini

### 5.1 Цель AI-слоя

AI-слой нужен не для медицинских диагнозов, а для структурирования информации, которую пользователь сам добавляет в приложение.

Gemini должен помогать:

- распознавать текстовые сообщения пользователя;
- извлекать данные из документов;
- предлагать, куда сохранить информацию;
- создавать draft-действия перед подтверждением пользователя.

### 5.2 Smart Text Input через Gemini

Пользователь пишет обычную фразу, а Gemini возвращает структурированный JSON.

#### Allergy

Input:

```text
My corgi is allergic to chicken
```

Expected JSON:

```json
{
  "intent": "addAllergy",
  "confidence": 0.95,
  "data": {
    "allergy": "chicken"
  },
  "suggestedActions": [
    {
      "type": "updatePetAllergies",
      "value": "chicken"
    },
    {
      "type": "createTimelineEvent",
      "eventType": "allergy",
      "title": "Allergy added: chicken"
    }
  ]
}
```

#### Medication

Input:

```text
Give Bella 1 tablet of NexGard every month
```

Expected JSON:

```json
{
  "intent": "addMedication",
  "confidence": 0.92,
  "data": {
    "medicationName": "NexGard",
    "dosage": "1 tablet",
    "frequency": "monthly"
  },
  "suggestedActions": [
    {
      "type": "createTimelineEvent",
      "eventType": "medication"
    },
    {
      "type": "createReminder",
      "repeatType": "monthly"
    }
  ]
}
```

#### Vaccination

Input:

```text
Archie got rabies vaccine today, next one in a year
```

Expected JSON:

```json
{
  "intent": "addVaccination",
  "confidence": 0.9,
  "data": {
    "vaccineName": "rabies",
    "date": "today",
    "nextReminderOffset": "1 year"
  },
  "suggestedActions": [
    {
      "type": "createTimelineEvent",
      "eventType": "vaccination"
    },
    {
      "type": "createReminder"
    }
  ]
}
```

#### Symptom

Input:

```text
Charlie vomited twice yesterday after eating beef
```

Expected JSON:

```json
{
  "intent": "addSymptom",
  "confidence": 0.88,
  "data": {
    "symptom": "vomiting",
    "count": "twice",
    "possibleTrigger": "beef",
    "date": "yesterday"
  },
  "suggestedActions": [
    {
      "type": "createTimelineEvent",
      "eventType": "symptom"
    }
  ]
}
```

### 5.3 Document Scan через Gemini

Пользователь сканирует документ, приложение загружает файл в Firebase Storage, извлекает текст/OCR и отправляет текст или изображение в Gemini для анализа.

Gemini должен определить:

- document type;
- pet name, если указан;
- даты;
- vaccine name;
- medication name;
- dosage;
- clinic name;
- veterinarian name;
- expiry date;
- next visit date;
- recommended reminder;
- suggested timeline event.

Примеры автоматического распределения:

- vaccination certificate → Documents + PetEvent vaccination + Reminder for next vaccine
- lab result → Documents + PetEvent labTest
- prescription → Documents + PetEvent medication + Reminder
- insurance document → Documents + Reminder before expiry date
- vet report → Documents + PetEvent vetVisit

### 5.4 AI Confirmation-first UX

Все AI-действия должны проходить через подтверждение:

1. Пользователь вводит текст или сканирует документ.
2. Приложение показывает, что Gemini понял.
3. Пользователь может исправить поля.
4. Пользователь нажимает Confirm.
5. Только после этого данные сохраняются в Firestore.

Важно:

- Gemini не должен напрямую писать в Firestore;
- AI возвращает только draft/suggestion;
- сохранение выполняет приложение после подтверждения пользователя;
- если confidence низкий, показывать “We’re not sure, please review”.

### 5.5 AI Safety

Приложение не должно:

- ставить диагноз;
- назначать лечение;
- отменять назначение врача;
- говорить, что симптом безопасен;
- заменять консультацию ветеринара.

Gemini prompt должен явно запрещать медицинские рекомендации и требовать только структурировать данные.

## 6. Основные экраны

### Onboarding

1. All your pet’s health history in one place
2. Never forget vaccines, medication or vet visits
3. Scan documents and let the app organize them
4. Add updates by simply typing what happened
5. Export a clean summary for your vet

### Pet List Screen

- список питомцев
- фото
- возраст
- ближайшее напоминание
- кнопка добавления

### Pet Profile Screen

- карточка питомца
- allergies
- chronic conditions
- timeline
- документы
- напоминания
- экспорт PDF
- smart input field

Быстрые действия:

- Add event
- Scan document
- Add document
- Add reminder
- Write update
- Export summary

### Timeline

- история событий
- фильтрация
- поиск
- CRUD операций
- события, созданные вручную
- события, созданные из скана документа
- события, созданные из smart message

### Documents

- хранение PDF и фото в Firebase Storage
- metadata документов в Firestore
- сканирование документов через камеру
- OCR / извлечение текста
- Gemini-анализ документа
- автоматическое определение типа документа
- автоматическое заполнение полей
- срок действия
- напоминания

### Reminders

- локальные уведомления
- повторяющиеся события
- данные напоминаний в Firestore

### Smart Input Screen / Bottom Sheet

Экран или bottom sheet для быстрого добавления информации обычным текстом.

После ввода приложение должно:

1. Отправить текст в AiRepository.
2. Получить structured JSON от Gemini.
3. Показать preview изменений.
4. Попросить подтверждение.
5. После подтверждения сохранить данные в нужное место.

### Vet Summary Export

Генерация PDF:

- данные питомца
- allergies
- chronic conditions
- прививки
- лекарства
- визиты
- симптомы
- документы

PDF можно сохранять локально и/или загружать в Firebase Storage.

## 7. MVP

Обязательно:

- Firebase setup
- anonymous Firebase Auth
- Firestore data sync
- Firebase Storage upload для документов и фото питомца
- создание питомца
- редактирование питомца
- allergies в профиле питомца
- timeline
- документы
- сканирование документа через камеру
- ручное добавление документа
- smart text input через Gemini
- обработка хотя бы 4 intent-ов:
  - allergy
  - medication
  - vaccination
  - symptom
- preview перед сохранением AI-результата
- напоминания
- локальные уведомления
- экспорт PDF
- Firestore offline persistence

Не входит:

- обязательная email/password регистрация
- семейный доступ
- подписки
- чат с ветеринаром
- автоматический медицинский диагноз
- рекомендации лечения без врача
- публичный sharing link

## 8. Premium-функции

- несколько питомцев
- семейный доступ
- расширенный AI-анализ документов
- автоматическое извлечение дат из PDF
- неограниченное количество сканов
- статистика веса
- графики здоровья
- шаринг ветеринару
- advanced vet summary
- smart health insights
- Cloud Functions для серверной AI-обработки
- App Check
- FCM reminders между устройствами

## 9. Безопасность и ограничения

Приложение не должно позиционироваться как замена ветеринару.

AI-функции должны:

- только структурировать информацию;
- не ставить диагноз;
- не назначать лечение;
- не отменять назначение врача;
- показывать disclaimer для медицинских данных.

Пример текста:

> PawVault helps you organize your pet’s health information. It does not provide medical diagnosis or treatment advice. Always consult a veterinarian for medical decisions.

## 10. Названия

- PawVault
- VetReady
- Pet Archive
- Pet Passport
- PawRecord
