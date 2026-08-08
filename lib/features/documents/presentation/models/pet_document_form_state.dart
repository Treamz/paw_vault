import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

class PetDocumentFormState {
  const PetDocumentFormState({
    this.type,
    this.title = '',
    this.issueDate,
    this.expiryDate,
    this.notes,
  });

  factory PetDocumentFormState.fromDocument(PetDocument document) {
    return PetDocumentFormState(
      type: document.type,
      title: document.title,
      issueDate: document.issueDate?.toUtcDateTime(),
      expiryDate: document.expiryDate?.toUtcDateTime(),
      notes: document.notes,
    );
  }

  final PetDocumentType? type;
  final String title;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;

  PetDocumentFormState copyWith({
    PetDocumentType? type,
    String? title,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
  }) {
    return PetDocumentFormState(
      type: type ?? this.type,
      title: title ?? this.title,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
    );
  }

  PetDocumentFormValidation validate() {
    final errors = <String, String>{};

    if (type == null) {
      errors['type'] = 'Document type is required';
    }

    if (title.trim().isEmpty) {
      errors['title'] = 'Document title is required';
    } else if (title.trim().length > 200) {
      errors['title'] = 'Document title must be 200 characters or less';
    }

    if (issueDate == null) {
      errors['issueDate'] = 'Issue date is required';
    }

    if (issueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);

      if (issueDate!.isAfter(today)) {
        errors['issueDate'] = 'Issue date cannot be in the future';
      } else if (issueDate!.isBefore(hundredYearsAgo)) {
        errors['issueDate'] =
            'Issue date cannot be more than 100 years in the past';
      }
    }

    if (expiryDate != null && issueDate != null) {
      if (expiryDate!.isBefore(issueDate!)) {
        errors['expiryDate'] = 'Expiry date cannot be before the issue date';
      }
    }

    if (notes != null && notes!.trim().length > 5000) {
      errors['notes'] = 'Notes must be 5000 characters or less';
    }

    return PetDocumentFormValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  PetDocument toDocument({
    required EntityId id,
    required EntityId userId,
    required EntityId petId,
    Uri? fileUrl,
    String? storagePath,
    EntityId? linkedEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final validation = validate();
    if (!validation.isValid) {
      throw PetDocumentFormValidationException(validation);
    }

    return PetDocument(
      id: id,
      userId: userId,
      petId: petId,
      title: title.trim(),
      type: type!,
      fileUrl: fileUrl,
      storagePath: storagePath,
      issueDate: issueDate != null ? DateOnly.fromDateTime(issueDate!) : null,
      expiryDate:
          expiryDate != null ? DateOnly.fromDateTime(expiryDate!) : null,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      linkedEventId: linkedEventId,
      createdAt: createdAt != null ? UtcDateTime(createdAt) : null,
      updatedAt: updatedAt != null ? UtcDateTime(updatedAt) : null,
    );
  }
}

class PetDocumentFormValidation {
  const PetDocumentFormValidation({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final Map<String, String> errors;

  String? errorFor(String field) => errors[field];
}

class PetDocumentFormValidationException implements Exception {
  PetDocumentFormValidationException(this.validation);

  final PetDocumentFormValidation validation;

  @override
  String toString() =>
      'PetDocumentFormValidationException: ${validation.errors}';
}
