import 'package:flutter/material.dart';

import '../../../../core/config/strings_it.dart';
import '../../../../shared/widgets/percentage_input_field.dart';

/// Member allocation step widget (Step 3 of wizard).
/// Feature: 001-group-budget-wizard, Task: T035
class MemberAllocationStep extends StatefulWidget {
  const MemberAllocationStep({
    super.key,
    required this.members,
    required this.memberAllocations,
    required this.onAllocationsChanged,
  });

  final List<Map<String, dynamic>> members;
  final Map<String, double> memberAllocations;
  final Function(Map<String, double>) onAllocationsChanged;

  @override
  State<MemberAllocationStep> createState() => _MemberAllocationStepState();
}

class _MemberAllocationStepState extends State<MemberAllocationStep> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final member in widget.members) {
      final userId = member['user_id'] as String;
      final existingAllocation = widget.memberAllocations[userId];
      final controller = TextEditingController(
        text: existingAllocation?.toStringAsFixed(2) ?? '',
      );
      _controllers[userId] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _calculateTotal() {
    return _controllers.entries.fold(0.0, (sum, entry) {
      final value = double.tryParse(entry.value.text) ?? 0;
      return sum + value;
    });
  }

  bool _isValid() {
    final total = _calculateTotal();
    return (total - 100.0).abs() <= 0.01;
  }

  void _splitEqually() {
    final memberCount = widget.members.length;
    if (memberCount == 0) return;

    final basePercentage = 100.0 / memberCount;
    final allocations = <String, double>{};
    double sum = 0;

    for (int i = 0; i < memberCount; i++) {
      final userId = widget.members[i]['user_id'] as String;
      if (i < memberCount - 1) {
        final percentage = double.parse(basePercentage.toStringAsFixed(2));
        allocations[userId] = percentage;
        sum += percentage;
        _controllers[userId]!.text = percentage.toStringAsFixed(2);
      } else {
        // Last member gets remainder
        final remainder = double.parse((100.0 - sum).toStringAsFixed(2));
        allocations[userId] = remainder;
        _controllers[userId]!.text = remainder.toStringAsFixed(2);
      }
    }

    setState(() {
      widget.onAllocationsChanged(allocations);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    final isValid = _isValid();
    final remaining = 100.0 - total;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Dividi Equamente" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                StringsIt.distributePercentages,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: _splitEqually,
                icon: const Icon(Icons.pie_chart),
                label: const Text(StringsIt.splitEqually),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total and validation
          Card(
            color: isValid
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${StringsIt.total}:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          Text(
                            '${total.toStringAsFixed(2)}%',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isValid ? Icons.check_circle : Icons.warning,
                            color: isValid ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isValid && total != 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      StringsIt.percentageMustBe100,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (remaining != 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${StringsIt.remaining}: ${remaining.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Member allocation inputs
          Expanded(
            child: ListView.builder(
              itemCount: widget.members.length,
              itemBuilder: (context, index) {
                final member = widget.members[index];
                final userId = member['user_id'] as String;
                final displayName = member['display_name'] as String;
                final controller = _controllers[userId]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            PercentageInputField(
                              controller: controller,
                              onChanged: (_) {
                                setState(() {
                                  final allocations = <String, double>{};
                                  for (final entry in _controllers.entries) {
                                    final value =
                                        double.tryParse(entry.value.text);
                                    if (value != null && value > 0) {
                                      allocations[entry.key] = value;
                                    }
                                  }
                                  widget.onAllocationsChanged(allocations);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
