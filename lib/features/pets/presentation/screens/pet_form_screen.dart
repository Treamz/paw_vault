import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/pets/application/pet_photo_upload_service.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_measurement.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_form_state.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_measurement_labels.dart';

@RoutePage()
class PetFormScreen extends StatelessWidget {
  const PetFormScreen({
    @QueryParam('petId') this.petId,
    super.key,
  });

  final String? petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = PetProfileCubit(
          petRepository: context.read<PetRepository>(),
          authRepository: context.read<AuthRepository>(),
          photoUploadService: PetPhotoUploadService(
            storageRepository: context.read<StorageRepository>(),
          ),
          weightEntryRepository: context.read<WeightEntryRepository>(),
          analytics: context.read<AnalyticsService>(),
        );
        if (petId != null) {
          cubit.load(petId!);
        }
        return cubit;
      },
      child: _PetFormView(isEditMode: petId != null),
    );
  }
}

class _PetFormView extends StatefulWidget {
  const _PetFormView({required this.isEditMode});

  final bool isEditMode;

  @override
  State<_PetFormView> createState() => _PetFormViewState();
}

class _PetFormViewState extends State<_PetFormView> {
  final _formKey = GlobalKey<FormState>();
  late PetFormState _formState;
  PetFormValidation? _validation;

  /// Whether the user has hit save; distinguishes a save-triggered `ready`
  /// state from the initial edit-mode load, which also emits `ready`.
  bool _saveRequested = false;

  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  PetGender? _selectedGender;
  PetWeightUnit _selectedWeightUnit = PetWeightUnit.kilogram;
  DateTime? _selectedBirthDate;
  String? _photoUrl;
  PickedPetPhoto? _pickedPhoto;

  final List<PetMeasurementInput> _measurements = [];
  final List<TextEditingController> _measurementControllers = [];
  final List<int> _measurementRowIds = [];
  int _nextMeasurementRowId = 0;

  @override
  void initState() {
    super.initState();
    _formState = const PetFormState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    for (final controller in _measurementControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMeasurementRow() {
    setState(() {
      _measurements.add(const PetMeasurementInput());
      _measurementControllers.add(TextEditingController());
      _measurementRowIds.add(_nextMeasurementRowId++);
      _updateFormState();
    });
  }

  void _removeMeasurementRow(int index) {
    setState(() {
      _measurements.removeAt(index);
      _measurementControllers.removeAt(index).dispose();
      _measurementRowIds.removeAt(index);
      _updateFormState();
    });
  }

  void _setMeasurements(List<PetMeasurementInput> measurements) {
    for (final controller in _measurementControllers) {
      controller.dispose();
    }
    _measurementControllers.clear();
    _measurements
      ..clear()
      ..addAll(measurements);
    _measurementRowIds.clear();
    for (final measurement in measurements) {
      _measurementControllers.add(
        TextEditingController(text: measurement.value),
      );
      _measurementRowIds.add(_nextMeasurementRowId++);
    }
  }

  Set<PetMeasurementType> _usedMeasurementTypes({int? exceptIndex}) {
    return {
      for (var i = 0; i < _measurements.length; i++)
        if (i != exceptIndex && _measurements[i].type != null)
          _measurements[i].type!,
    };
  }

  void _loadPetData(Pet pet) {
    setState(() {
      _formState = PetFormState.fromPet(pet);
      _nameController.text = pet.name;
      _speciesController.text = pet.species ?? '';
      _breedController.text = pet.breed ?? '';
      _weightController.text = pet.weight?.value.toString() ?? '';
      _microchipController.text = pet.microchipNumber ?? '';
      _setMeasurements(_formState.measurements);
      _photoUrl = pet.photoUrl?.toString();
      _pickedPhoto = null;
      _notesController.text = pet.notes ?? '';
      _allergiesController.text = pet.allergies.join(', ');
      _conditionsController.text = pet.chronicConditions.join(', ');
      _selectedGender = pet.gender;
      _selectedWeightUnit = pet.weight?.unit ?? PetWeightUnit.kilogram;
      _selectedBirthDate = pet.birthDate?.toUtcDateTime();
    });
  }

  void _updateFormState() {
    final allergies = _allergiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final conditions = _conditionsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _formState = PetFormState(
        name: _nameController.text,
        species:
            _speciesController.text.isEmpty ? null : _speciesController.text,
        breed: _breedController.text.isEmpty ? null : _breedController.text,
        birthDate: _selectedBirthDate != null
            ? DateOnly.fromDateTime(_selectedBirthDate!)
            : null,
        gender: _selectedGender,
        weightValue: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
        weightUnit: _selectedWeightUnit,
        microchipNumber: _microchipController.text.isEmpty
            ? null
            : _microchipController.text,
        measurements: List.of(_measurements),
        photoUrl: _photoUrl,
        pickedPhoto: _pickedPhoto,
        allergies: allergies,
        chronicConditions: conditions,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      _validation = _formState.validate();
    });
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _updateFormState();
      });
    }
  }

  Future<void> _pickPhoto(PetPhotoSource source) async {
    final picker = context.read<PetPhotoPicker>();
    try {
      final photo = await picker.pick(source);
      if (photo == null || !mounted) {
        return;
      }
      setState(() {
        _pickedPhoto = photo;
        _updateFormState();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick a photo')),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _pickedPhoto = null;
      _photoUrl = null;
      _updateFormState();
    });
  }

  void _savePet() {
    _updateFormState();

    if (_validation?.isValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }

    _saveRequested = true;
    final cubit = context.read<PetProfileCubit>();
    if (widget.isEditMode) {
      cubit.updatePet(_formState);
    } else {
      cubit.createPet(_formState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PetProfileCubit, PetProfileState>(
      listener: (context, state) {
        if (state.status == PetProfileStatus.ready &&
            widget.isEditMode &&
            !_saveRequested &&
            state.pet != null &&
            _nameController.text.isEmpty) {
          _loadPetData(state.pet!);
        }

        if (state.status == PetProfileStatus.ready && _saveRequested) {
          _saveRequested = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet saved successfully')),
          );
          context.router.back();
        }

        if (state.status == PetProfileStatus.failure) {
          _saveRequested = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to save pet'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditMode ? 'Edit Pet' : 'Add Pet'),
        ),
        body: BlocBuilder<PetProfileCubit, PetProfileState>(
          builder: (context, state) {
            if (widget.isEditMode && state.status == PetProfileStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isSaving = state.status == PetProfileStatus.saving;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name *',
                        errorText: _validation?.errorFor('name'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _speciesController,
                      decoration: InputDecoration(
                        labelText: 'Species',
                        errorText: _validation?.errorFor('species'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _breedController,
                      decoration: InputDecoration(
                        labelText: 'Breed',
                        errorText: _validation?.errorFor('breed'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PetGender>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: PetGender.values
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(
                                gender.name[0].toUpperCase() +
                                    gender.name.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedGender = value;
                                _updateFormState();
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Birth Date'),
                      subtitle: Text(
                        _selectedBirthDate != null
                            ? DateOnly.fromDateTime(_selectedBirthDate!)
                                .toString()
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: isSaving ? null : _selectBirthDate,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_validation?.errorFor('birthDate') != null) ...[
                      Text(
                        _validation!.errorFor('birthDate')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: 'Weight',
                              errorText: _validation?.errorFor('weight'),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            enabled: !isSaving,
                            onChanged: (_) => _updateFormState(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<PetWeightUnit>(
                            initialValue: _selectedWeightUnit,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Unit'),
                            items: PetWeightUnit.values
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit.name),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedWeightUnit =
                                          value ?? PetWeightUnit.kilogram;
                                      _updateFormState();
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Body Measurements',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_validation?.errorFor('measurements') != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _validation!.errorFor('measurements')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    for (var i = 0; i < _measurements.length; i++)
                      KeyedSubtree(
                        key: ValueKey('measurement-${_measurementRowIds[i]}'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child:
                                    DropdownButtonFormField<PetMeasurementType>(
                                  initialValue: _measurements[i].type,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Measurement',
                                  ),
                                  items: [
                                    for (final type
                                        in PetMeasurementType.values)
                                      if (type == _measurements[i].type ||
                                          !_usedMeasurementTypes(
                                            exceptIndex: i,
                                          ).contains(type))
                                        DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type.label,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                  ],
                                  onChanged: isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _measurements[i] = _measurements[i]
                                                .copyWith(type: value);
                                            _updateFormState();
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _measurementControllers[i],
                                  decoration: const InputDecoration(
                                    labelText: 'Value',
                                    suffixText: 'cm',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  enabled: !isSaving,
                                  onChanged: (value) {
                                    _measurements[i] =
                                        _measurements[i].copyWith(value: value);
                                    _updateFormState();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove measurement',
                                onPressed: isSaving
                                    ? null
                                    : () => _removeMeasurementRow(i),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isSaving ||
                                _measurements.length >=
                                    PetMeasurementType.values.length
                            ? null
                            : _addMeasurementRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add measurement'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _microchipController,
                      decoration: InputDecoration(
                        labelText: 'Microchip Number',
                        errorText: _validation?.errorFor('microchipNumber'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    _PhotoPickerField(
                      photoUrl: _photoUrl,
                      pickedPhoto: _pickedPhoto,
                      enabled: !isSaving,
                      onPick: _pickPhoto,
                      onRemove: _removePhoto,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies',
                        hintText: 'Comma-separated (e.g., Chicken, Beef)',
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Chronic Conditions',
                        hintText: 'Comma-separated',
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        errorText: _validation?.errorFor('notes'),
                      ),
                      maxLines: 4,
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving ? null : _savePet,
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEditMode ? 'Save Changes' : 'Add Pet',
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isSaving ? null : () => context.router.back(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PhotoPickerField extends StatelessWidget {
  const _PhotoPickerField({
    required this.photoUrl,
    required this.pickedPhoto,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String? photoUrl;
  final PickedPetPhoto? pickedPhoto;
  final bool enabled;
  final ValueChanged<PetPhotoSource> onPick;
  final VoidCallback onRemove;

  Uri? get _networkUrl {
    final url = photoUrl;
    if (url == null) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }
    return uri;
  }

  bool get _hasPhoto => pickedPhoto != null || photoUrl != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildPreview(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photo', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        enabled ? () => onPick(PetPhotoSource.camera) : null,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        enabled ? () => onPick(PetPhotoSource.gallery) : null,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  if (_hasPhoto)
                    TextButton(
                      onPressed: enabled ? onRemove : null,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final picked = pickedPhoto;
    final networkUrl = _networkUrl;

    Widget? image;
    if (picked != null) {
      image = Image.memory(
        picked.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (networkUrl != null) {
      image = Image.network(
        networkUrl.toString(),
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => _placeholder(context),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 72,
        height: 72,
        child: image ?? _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.pets,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
