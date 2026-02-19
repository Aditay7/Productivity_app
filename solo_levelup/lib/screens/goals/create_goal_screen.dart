import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal.dart';
import '../../providers/goal_provider.dart';
import '../../app/theme.dart';

/// Create/Edit Goal Screen (simplified version)
class CreateGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;

  const CreateGoalScreen({super.key, this.goal});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;
  
  GoalType _type = GoalType.monthly;
  String _statType = 'strength';
  GoalUnit _unit = GoalUnit.quests;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descriptionController = TextEditingController(text: widget.goal?.description ?? '');
    _targetController = TextEditingController(
      text: widget.goal?.targetValue.toString() ?? '10',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Create Goal' : 'Edit Goal'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'Complete 50 quests this month',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Goal Period'),
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statType,
                decoration: const InputDecoration(labelText: 'Stat Type'),
                items: ['strength', 'intelligence', 'discipline', 'wealth', 'charisma']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _statType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      decoration: const InputDecoration(labelText: 'Target Value'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(v!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<GoalUnit>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: GoalUnit.values.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text(u.displayName),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  widget.goal == null ? 'Create Goal' : 'Update Goal',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final endDate = _type == GoalType.monthly
        ? DateTime(now.year, now.month + 1, 0)
        : DateTime(now.year + 1, 12, 31);

    final goal = Goal(
      id: widget.goal?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      statType: _statType,
      targetValue: int.parse(_targetController.text),
      currentValue: widget.goal?.currentValue ?? 0,
      unit: _unit,
      startDate: widget.goal?.startDate ?? now,
      endDate: endDate,
      createdAt: widget.goal?.createdAt ?? now,
    );

    if (widget.goal == null) {
      ref.read(goalProvider.notifier).createGoal(goal);
    } else {
      ref.read(goalProvider.notifier).updateGoal(goal);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }
}
