import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/presentation/cubit/documents_cubit.dart';

void main() {
  group('DocumentsCubit', () {
    test('loads the current user and emits watched documents', () async {
      final document = _document();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final documentRepository =
          _FakeDocumentRepository(watchedDocuments: [document]);
      final cubit = DocumentsCubit(
        documentRepository: documentRepository,
        authRepository: authRepository,
      );
      final states = <DocumentsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(documentRepository.initializeCallCount, 1);
      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, isZero);
      expect(documentRepository.watchedUserId, const EntityId('user-1'));
      expect(documentRepository.watchedPetId, const EntityId('pet-1'));
      expect(states.first.status, DocumentsStatus.loading);
      expect(states.last.status, DocumentsStatus.ready);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.documents, [document]);

      await subscription.cancel();
      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anonymous-user', isAnonymous: true),
      );
      final documentRepository = _FakeDocumentRepository();
      final cubit = DocumentsCubit(
        documentRepository: documentRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(
        documentRepository.watchedUserId,
        const EntityId('anonymous-user'),
      );
      expect(documentRepository.watchedPetId, const EntityId('pet-1'));
      expect(cubit.state.status, DocumentsStatus.ready);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final authRepository = _FakeAuthRepository();
      final documentRepository =
          _FakeDocumentRepository(throwsOnInitialize: true);
      final cubit = DocumentsCubit(
        documentRepository: documentRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');

      expect(cubit.state.status, DocumentsStatus.failure);
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });

    test('emits empty list when no documents exist', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final documentRepository = _FakeDocumentRepository(watchedDocuments: []);
      final cubit = DocumentsCubit(
        documentRepository: documentRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, DocumentsStatus.ready);
      expect(cubit.state.documents, isEmpty);

      await cubit.close();
    });

    test('emits failure when stream emits error', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final documentRepository = _FakeDocumentRepository(throwsOnWatch: true);
      final cubit = DocumentsCubit(
        documentRepository: documentRepository,
        authRepository: authRepository,
      );
      final states = <DocumentsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, DocumentsStatus.failure);
      expect(states.last.errorMessage, contains('watch failed'));

      await subscription.cancel();
      await cubit.close();
    });

    test('sorts documents newest-first by issue date', () async {
      // A freshly scanned document (createdAt = now) with an old issue date
      // must slot in by its issue date, not jump to the top.
      final scannedOld = _document(
        id: 'doc-scanned',
        issueDate: const DateOnly(year: 2024, month: 3, day: 1),
        createdAt: DateTime.utc(2026, 8, 15),
      );
      final recent = _document(
        id: 'doc-recent',
        issueDate: const DateOnly(year: 2026, month: 5, day: 10),
        createdAt: DateTime.utc(2026, 5, 10),
      );
      final undatedNew = _document(
        id: 'doc-undated',
        createdAt: DateTime.utc(2026, 7),
      );
      final cubit = _readyCubit([scannedOld, recent, undatedNew]);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.documents.map((d) => d.id.value).toList(),
        ['doc-undated', 'doc-recent', 'doc-scanned'],
      );

      await cubit.close();
    });

    test('filters documents by type', () async {
      final passport = _document(id: 'doc-1', type: PetDocumentType.passport);
      final insurance = _document(id: 'doc-2', type: PetDocumentType.insurance);
      final receipt = _document(id: 'doc-3', type: PetDocumentType.receipt);
      final cubit = _readyCubit([passport, insurance, receipt]);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.filteredDocuments.length, 3);

      cubit.setTypeFilter(PetDocumentType.insurance);

      expect(cubit.state.filteredDocuments, [insurance]);

      await cubit.close();
    });

    test('filters documents expiring on or before a cutoff', () async {
      final expiringSoon = _document(
        id: 'doc-1',
        expiryDate: const DateOnly(year: 2026, month: 6, day: 20),
      );
      final expiringLater = _document(
        id: 'doc-2',
        expiryDate: const DateOnly(year: 2026, month: 9, day: 1),
      );
      final noExpiry = _document(id: 'doc-3');
      final cubit = _readyCubit([expiringSoon, expiringLater, noExpiry]);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      cubit.setExpiringBeforeFilter(DateTime(2026, 7));

      expect(cubit.state.filteredDocuments, [expiringSoon]);

      await cubit.close();
    });

    test('includes a document expiring exactly on the cutoff date', () async {
      final onCutoff = _document(
        id: 'doc-1',
        expiryDate: const DateOnly(year: 2026, month: 7, day: 1),
      );
      final cubit = _readyCubit([onCutoff]);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      cubit.setExpiringBeforeFilter(DateTime(2026, 7));

      expect(cubit.state.filteredDocuments, [onCutoff]);

      await cubit.close();
    });

    test('combines type and expiry filters', () async {
      final match = _document(
        id: 'doc-1',
        type: PetDocumentType.insurance,
        expiryDate: const DateOnly(year: 2026, month: 6, day: 20),
      );
      final wrongType = _document(
        id: 'doc-2',
        type: PetDocumentType.passport,
        expiryDate: const DateOnly(year: 2026, month: 6, day: 20),
      );
      final wrongDate = _document(
        id: 'doc-3',
        type: PetDocumentType.insurance,
        expiryDate: const DateOnly(year: 2026, month: 12, day: 1),
      );
      final cubit = _readyCubit([match, wrongType, wrongDate]);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      cubit.setTypeFilter(PetDocumentType.insurance);
      cubit.setExpiringBeforeFilter(DateTime(2026, 7));

      expect(cubit.state.filteredDocuments, [match]);

      await cubit.close();
    });

    test('clears all filters', () async {
      final passport = _document(id: 'doc-1', type: PetDocumentType.passport);
      final insurance = _document(id: 'doc-2', type: PetDocumentType.insurance);
      final cubit = _readyCubit([passport, insurance]);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      cubit.setTypeFilter(PetDocumentType.passport);
      cubit.setExpiringBeforeFilter(DateTime(2026, 7));

      expect(cubit.state.filterType, PetDocumentType.passport);
      expect(cubit.state.expiringBefore, isNotNull);

      cubit.clearFilters();

      expect(cubit.state.filterType, isNull);
      expect(cubit.state.expiringBefore, isNull);
      expect(cubit.state.filteredDocuments.length, 2);

      await cubit.close();
    });

    test('preserves filters when watched documents update', () async {
      final passport = _document(id: 'doc-1', type: PetDocumentType.passport);
      final insurance = _document(id: 'doc-2', type: PetDocumentType.insurance);
      final repository = _FakeDocumentRepository(
        documentsStream: Stream<List<PetDocument>>.fromIterable([
          [passport],
          [passport, insurance],
        ]),
      );
      final cubit = DocumentsCubit(
        documentRepository: repository,
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
      );

      await cubit.load('pet-1');
      cubit.setTypeFilter(PetDocumentType.passport);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.documents.length, 2);
      expect(cubit.state.filterType, PetDocumentType.passport);
      expect(cubit.state.filteredDocuments, [passport]);

      await cubit.close();
    });
  });
}

DocumentsCubit _readyCubit(List<PetDocument> documents) {
  return DocumentsCubit(
    documentRepository: _FakeDocumentRepository(watchedDocuments: documents),
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
  );
}

PetDocument _document({
  String id = 'document-1',
  PetDocumentType type = PetDocumentType.vaccinationCertificate,
  DateOnly? issueDate,
  DateOnly? expiryDate,
  DateTime? createdAt,
}) {
  return PetDocument(
    id: EntityId(id),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Vaccination certificate',
    type: type,
    fileUrl: Uri.parse('https://example.com/doc.pdf'),
    storagePath: 'users/user-1/pets/pet-1/documents/$id.pdf',
    issueDate: issueDate,
    expiryDate: expiryDate,
    createdAt: createdAt == null ? null : UtcDateTime(createdAt),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.currentUserValue,
    this.signedInUser = const AppUser(id: 'signed-in-user', isAnonymous: true),
  });

  final AppUser? currentUserValue;
  final AppUser signedInUser;

  int currentUserCallCount = 0;
  int signInAnonymouslyCallCount = 0;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCallCount++;
    return currentUserValue;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(currentUserValue);
  }
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository({
    this.watchedDocuments = const [],
    this.documentsStream,
    this.throwsOnInitialize = false,
    this.throwsOnWatch = false,
  });

  final List<PetDocument> watchedDocuments;
  final Stream<List<PetDocument>>? documentsStream;
  final bool throwsOnInitialize;
  final bool throwsOnWatch;

  int initializeCallCount = 0;
  EntityId? watchedUserId;
  EntityId? watchedPetId;

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    return null;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    if (throwsOnWatch) {
      return Stream<List<PetDocument>>.error(StateError('watch failed'));
    }
    return documentsStream ?? Stream<List<PetDocument>>.value(watchedDocuments);
  }
}
