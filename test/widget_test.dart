import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';

void main() {
  testWidgets('PawVault shell renders pet list', (WidgetTester tester) async {
    await tester.pumpWidget(
      PawVaultApp(
        dependencies: AppDependencies.localFirst(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PawVault'), findsWidgets);
    expect(find.text('No pets yet'), findsOneWidget);
  });
}
