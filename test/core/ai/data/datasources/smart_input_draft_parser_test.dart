import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/ai/data/datasources/flutter_fire_ai_logic_data_source.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

void main() {
  group('FlutterFireAiLogicDataSource.parseSmartInputDraft', () {
    test('parses a complete JSON reply into a review draft', () {
      const reply = '''
```json
{
  "intent": "addVaccination",
  "extractedData": {"vaccine": "rabies", "date": "2026-07-27"},
  "suggestedActions": ["createTimelineEvent", "createReminder"],
  "confidence": 0.92
}
```''';

      final draft = FlutterFireAiLogicDataSource.parseSmartInputDraft(
        reply,
        originalText: 'Bella got her rabies shot today',
      );

      expect(draft.originalText, 'Bella got her rabies shot today');
      expect(draft.requiresConfirmation, isTrue);
      expect(draft.detectedIntent, SmartMessageIntent.addVaccination);
      expect(draft.extractedData['vaccine'], 'rabies');
      expect(draft.suggestedActions, hasLength(2));
      expect(
        draft.suggestedActions.first.type,
        SmartSuggestedActionType.createTimelineEvent,
      );
      expect(draft.confidence, 0.92);
      expect(draft.status, SmartInputDraftStatus.awaitingReview);
    });

    test('flags low confidence replies for extra review', () {
      const reply = '{"intent": "addNote", "confidence": 0.3}';

      final draft = FlutterFireAiLogicDataSource.parseSmartInputDraft(
        reply,
        originalText: 'something vague',
      );

      expect(draft.status, SmartInputDraftStatus.lowConfidenceReview);
      expect(draft.detectedIntent, SmartMessageIntent.addNote);
    });

    test('accepts snake_case intent and action names', () {
      const reply = '''
{"intent": "add_vaccination",
 "suggestedActions": ["create_timeline_event", "create-reminder"],
 "confidence": 0.9}''';

      final draft = FlutterFireAiLogicDataSource.parseSmartInputDraft(
        reply,
        originalText: 'note',
      );

      expect(draft.detectedIntent, SmartMessageIntent.addVaccination);
      expect(
        draft.suggestedActions.map((a) => a.type),
        [
          SmartSuggestedActionType.createTimelineEvent,
          SmartSuggestedActionType.createReminder,
        ],
      );
    });

    test('maps unknown intents and actions to unknown', () {
      const reply = '''
{"intent": "orderPizza", "suggestedActions": ["launchRocket"],
 "confidence": 0.9}''';

      final draft = FlutterFireAiLogicDataSource.parseSmartInputDraft(
        reply,
        originalText: 'note',
      );

      expect(draft.detectedIntent, SmartMessageIntent.unknown);
      expect(
        draft.suggestedActions.single.type,
        SmartSuggestedActionType.unknown,
      );
    });

    test('falls back to the original text when the reply is unparseable', () {
      final draft = FlutterFireAiLogicDataSource.parseSmartInputDraft(
        'not json at all',
        originalText: 'my note',
      );

      expect(draft.originalText, 'my note');
      expect(draft.requiresConfirmation, isTrue);
      expect(draft.detectedIntent, SmartMessageIntent.unknown);
      expect(draft.extractedData, isEmpty);
      expect(draft.status, SmartInputDraftStatus.lowConfidenceReview);
    });

    test('falls back when the reply is empty', () {
      final draft = FlutterFireAiLogicDataSource.parseSmartInputDraft(
        null,
        originalText: 'my note',
      );

      expect(draft.status, SmartInputDraftStatus.lowConfidenceReview);
      expect(draft.requiresConfirmation, isTrue);
    });
  });
}
