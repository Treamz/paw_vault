import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_form_state.dart';

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

  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  PetGender? _selectedGender;
  PetWeightUnit _selectedWeightUnit = PetWeightUnit.kilogram;
  DateTime? _selectedBirthDate;

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
    _photoUrlController.dispose();
    _notesController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _loadPetData(Pet pet) {
    setState(() {
      _formState = PetFormState.fromPet(pet);
      _nameController.text = pet.name;
      _speciesController.text = pet.species ?? '';
      _breedController.text = pet.breed ?? '';
      _weightController.text = pet.weight?.value.toString() ?? '';
      _microchipController.text = pet.microchipNumber ?? '';
      _photoUrlController.text = pet.photoUrl?.toString() ?? '';
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
        photoUrl:
            _photoUrlController.text.isEmpty ? null : _photoUrlController.text,
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

  void _savePet() {
    _updateFormState();

    if (_validation?.isValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }

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
        if (state.status == PetProfileStatus.ready && widget.isEditMode) {
          if (state.pet != null && _nameController.text.isEmpty) {
            _loadPetData(state.pet!);
          }
          if (!widget.isEditMode && state.pet != null) {
            context.router.back();
          }
        }

        if (state.status == PetProfileStatus.ready && !widget.isEditMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet saved successfully')),
          );
          context.router.back();
        }

        if (state.status == PetProfileStatus.failure) {
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
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: InputDecoration(
                        labelText: 'Photo URL',
                        errorText: _validation?.errorFor('photoUrl'),
                      ),
                      enabled: !isSaving,
                      onChanged: (_) => _updateFormState(),
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
