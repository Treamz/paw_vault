import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/presentation/widgets/state_views.dart';
import 'package:paw_vault/core/utils/parse_decimal.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/pets/presentation/cubit/weight_history_cubit.dart';

enum _Period {
  threeMonths('3M', Duration(days: 91)),
  year('1Y', Duration(days: 365)),
  all('All', null);

  const _Period(this.label, this.window);

  final String label;
  final Duration? window;
}

@RoutePage()
class WeightHistoryScreen extends StatelessWidget {
  const WeightHistoryScreen({
    @PathParam('petId') required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WeightHistoryCubit(
        weightEntryRepository: context.read<WeightEntryRepository>(),
        petRepository: context.read<PetRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..load(petId),
      child: const _WeightHistoryView(),
    );
  }
}

class _WeightHistoryView extends StatefulWidget {
  const _WeightHistoryView();

  @override
  State<_WeightHistoryView> createState() => _WeightHistoryViewState();
}

class _WeightHistoryViewState extends State<_WeightHistoryView> {
  _Period _period = _Period.all;

  List<WeightEntry> _filtered(List<WeightEntry> entries) {
    final window = _period.window;
    if (window == null) {
      return entries;
    }
    final cutoff = DateOnly.fromDateTime(DateTime.now().subtract(window));
    return [
      for (final entry in entries)
        if (entry.date.compareTo(cutoff) >= 0) entry,
    ];
  }

  Future<void> _addEntry(BuildContext context) async {
    final cubit = context.read<WeightHistoryCubit>();
    final result = await showDialog<
        ({
          double value,
          PetWeightUnit unit,
          DateOnly date,
        })>(
      context: context,
      builder: (_) => _AddWeightDialog(
        initialUnit: cubit.state.displayUnit,
      ),
    );
    if (result != null) {
      await cubit.addEntry(
        value: result.value,
        unit: result.unit,
        date: result.date,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weight History')),
      body: SafeArea(
        child: BlocConsumer<WeightHistoryCubit, WeightHistoryState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            return switch (state.status) {
              WeightHistoryStatus.initial ||
              WeightHistoryStatus.loading =>
                const LoadingView(),
              WeightHistoryStatus.failure => ErrorStateView(
                  title: 'Could not load weight history',
                  message: state.errorMessage,
                ),
              WeightHistoryStatus.ready => _buildContent(context, state),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context),
        icon: const Icon(Icons.add),
        label: const Text('Add weight'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeightHistoryState state) {
    final entries = _filtered(state.entries);
    final unit = state.displayUnit;

    if (state.entries.isEmpty) {
      return const EmptyStateView(
        icon: Icons.monitor_weight_outlined,
        title: 'No weight entries yet',
        message: 'Add a weight to start tracking changes over time. '
            'Saving a weight on the pet form also adds an entry here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
            child: SizedBox(
              height: 220,
              child: entries.isEmpty
                  ? const Center(child: Text('No entries in this period'))
                  : _WeightChart(entries: entries, unit: unit),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<_Period>(
          segments: [
            for (final period in _Period.values)
              ButtonSegment(value: period, label: Text(period.label)),
          ],
          selected: {_period},
          onSelectionChanged: (selection) =>
              setState(() => _period = selection.first),
        ),
        const SizedBox(height: 16),
        for (final entry in entries.reversed)
          Card(
            child: ListTile(
              key: ValueKey('weight-entry-${entry.id.value}'),
              title: Text(
                '${_formatValue(entry.valueIn(unit))} ${_unitLabel(unit)}',
              ),
              subtitle: Text(
                DateFormat.yMMMd().format(entry.date.toUtcDateTime()),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete entry',
                onPressed: () =>
                    context.read<WeightHistoryCubit>().deleteEntry(entry),
              ),
            ),
          ),
        const SizedBox(height: 72),
      ],
    );
  }
}

String _formatValue(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toString();
}

String _unitLabel(PetWeightUnit unit) {
  return switch (unit) {
    PetWeightUnit.kilogram => 'kg',
    PetWeightUnit.pound => 'lb',
  };
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries, required this.unit});

  final List<WeightEntry> entries;
  final PetWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = [
      for (final entry in entries)
        FlSpot(
          entry.date.toUtcDateTime().millisecondsSinceEpoch.toDouble(),
          entry.valueIn(unit),
        ),
    ];

    final values = [for (final spot in spots) spot.y];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = ((maxValue - minValue) * 0.2).clamp(0.5, double.infinity);

    return Column(
      children: [
        Expanded(
          child: _buildChart(
            context,
            colorScheme,
            spots,
            minValue,
            maxValue,
            padding,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          // Match the chart's reserved left-axis width.
          padding: const EdgeInsets.only(left: 40),
          child: _DateAxisRow(entries: entries),
        ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context,
    ColorScheme colorScheme,
    List<FlSpot> spots,
    double minValue,
    double maxValue,
    double padding,
  ) {
    return LineChart(
      LineChartData(
        minY: minValue - padding,
        maxY: maxValue + padding,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                _formatValue(value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          // Dates are rendered as a fixed min/mid/max row below the chart;
          // interval-generated ticks overlap at the right edge.
          bottomTitles: const AxisTitles(),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => [
              for (final spot in touchedSpots)
                LineTooltipItem(
                  '${_formatValue(spot.y)} ${_unitLabel(unit)}\n'
                  '${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}',
                  TextStyle(color: colorScheme.onInverseSurface),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: colorScheme.primary,
                strokeColor: colorScheme.surface,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns its controllers so they outlive the dialog's exit animation.
class _AddWeightDialog extends StatefulWidget {
  const _AddWeightDialog({required this.initialUnit});

  final PetWeightUnit initialUnit;

  @override
  State<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<_AddWeightDialog> {
  final _valueController = TextEditingController();
  late PetWeightUnit _unit = widget.initialUnit;
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    final value = parseDecimal(_valueController.text);
    if (value == null || value <= 0 || value > 10000) {
      setState(() => _error = 'Enter a valid weight');
      return;
    }
    Navigator.of(context).pop(
      (value: value, unit: _unit, date: DateOnly.fromDateTime(_date)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Weight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _valueController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    errorText: _error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PetWeightUnit>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    for (final unit in PetWeightUnit.values)
                      DropdownMenuItem(
                        value: unit,
                        child: Text(_unitLabel(unit)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _unit = value ?? widget.initialUnit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Deterministic first / middle / last date labels for the chart's x-axis.
class _DateAxisRow extends StatelessWidget {
  const _DateAxisRow({required this.entries});

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final format = DateFormat.MMMd();
    final first = entries.first.date.toUtcDateTime();
    final last = entries.last.date.toUtcDateTime();
    final labels = <String>[
      format.format(first),
      if (entries.length > 2)
        format.format(
          DateTime.fromMillisecondsSinceEpoch(
            (first.millisecondsSinceEpoch + last.millisecondsSinceEpoch) ~/ 2,
          ),
        ),
      if (entries.length > 1) format.format(last),
    ];

    return Row(
      mainAxisAlignment: labels.length == 1
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [for (final label in labels) Text(label, style: style)],
    );
  }
}
