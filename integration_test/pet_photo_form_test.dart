// Drives the real app (local-first dependencies, real router) through the
// pet form photo flow: pick a photo from camera/gallery, remove it, save the
// pet, and verify the photo is uploaded and its URL stored on the pet. The
// platform image picker is faked so the flow runs without native UI.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';

import 'support/fakes.dart';

// 1x1 transparent PNG, decodable by Image.memory.
final _pngBytes = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
]);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pet form picks, removes, and uploads a profile photo',
      (tester) async {
    final picker = _FakePetPhotoPicker(_pngBytes);
    final storage = _RecordingStorageRepository();
    final pets = _MemoryPetRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: FakeAuthRepository(),
      storageRepository: storage,
      petRepository: pets,
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: base.documentExtractionAiRepository,
      documentSourcePicker: base.documentSourcePicker,
      petPhotoPicker: picker,
      eventPhotoPicker: base.eventPhotoPicker,
      reminderNotificationScheduler: base.reminderNotificationScheduler,
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    // Open the pet form from the list.
    await tester.tap(find.text('Add pet'));
    await tester.pumpAndSettle();
    expect(find.text('Add Pet'), findsWidgets);

    // The URL input is gone; picker controls are present instead.
    expect(find.text('Photo URL'), findsNothing);
    expect(find.text('Photo'), findsOneWidget);
    final cameraButton = find.text('Camera');
    final galleryButton = find.text('Gallery');
    expect(cameraButton, findsOneWidget);
    expect(galleryButton, findsOneWidget);
    expect(find.text('Remove'), findsNothing);

    // Take a photo with the camera: preview + Remove appear.
    await tester.ensureVisible(cameraButton);
    await tester.tap(cameraButton);
    await tester.pumpAndSettle();
    expect(picker.lastSource, PetPhotoSource.camera);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    // Remove it: back to the placeholder.
    await tester.ensureVisible(find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Remove'), findsNothing);

    // Pick from the gallery instead.
    await tester.ensureVisible(galleryButton);
    await tester.tap(galleryButton);
    await tester.pumpAndSettle();
    expect(picker.lastSource, PetPhotoSource.gallery);
    expect(find.byType(Image), findsOneWidget);

    // Name the pet, then dismiss the keyboard so the save button is
    // reachable.
    final nameField = find.widgetWithText(TextFormField, 'Name *');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Rex');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Save: the photo is uploaded and its URL stored on the pet.
    final saveButton = find.widgetWithText(FilledButton, 'Add Pet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final savedPet = pets.lastSaved;
    expect(savedPet, isNotNull);
    expect(savedPet!.name, 'Rex');
    expect(storage.uploadCallCount, 1);
    expect(
      storage.uploadedPath,
      'users/user-1/pets/${savedPet.id.value}/photos/profile.jpg',
    );
    expect(storage.uploadedContentType, 'image/jpeg');
    expect(
      savedPet.photoUrl,
      Uri.parse('https://example.com/${storage.uploadedPath}'),
    );

    // Back on the pet list, the new pet is visible.
    expect(find.text('Rex'), findsOneWidget);
  });
}

class _FakePetPhotoPicker implements PetPhotoPicker {
  _FakePetPhotoPicker(this.bytes);

  final Uint8List bytes;
  PetPhotoSource? lastSource;

  @override
  Future<PickedPetPhoto?> pick(PetPhotoSource source) async {
    lastSource = source;
    return PickedPetPhoto(bytes: bytes, contentType: 'image/jpeg');
  }
}

class _RecordingStorageRepository implements StorageRepository {
  int uploadCallCount = 0;
  String? uploadedPath;
  String? uploadedContentType;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    uploadedContentType = contentType;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://example.com/$path'),
    );
  }
}

class _MemoryPetRepository implements PetRepository {
  final _pets = <Pet>[];
  final _controller = StreamController<List<Pet>>.broadcast();

  Pet? get lastSaved => _pets.isEmpty ? null : _pets.last;

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet;
      }
    }
    return null;
  }

  @override
  Future<void> savePet(Pet pet) async {
    _pets.removeWhere((existing) => existing.id == pet.id);
    _pets.add(pet);
    _controller.add(List.of(_pets));
  }

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    _pets.removeWhere((existing) => existing.id == petId);
    _controller.add(List.of(_pets));
  }

  @override
  Stream<List<Pet>> watchPets(EntityId userId) async* {
    yield List.of(_pets);
    yield* _controller.stream;
  }
}
