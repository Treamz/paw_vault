// Verifies the app-wide fix for the keyboard staying open: tapping outside
// a text field must unfocus it (which closes the keyboard on device).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';

void main() {
  testWidgets('tapping outside a text field dismisses focus', (tester) async {
    await tester.pumpWidget(
      PawVaultApp(dependencies: AppDependencies.localFirst()),
    );
    await tester.pumpAndSettle();

    // Open the pet form and focus the name field.
    await tester.tap(find.text('Add pet'));
    await tester.pumpAndSettle();
    final nameField = find.widgetWithText(TextFormField, 'Name *');
    await tester.enterText(nameField, 'Rex');
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.descendant(of: nameField, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);

    // Tap on empty space below the form fields (the app bar title works too);
    // the app-level GestureDetector must unfocus the field.
    await tester.tapAt(tester.getCenter(find.byType(AppBar)));
    await tester.pump();

    expect(editable.focusNode.hasFocus, isFalse);
  });
}
