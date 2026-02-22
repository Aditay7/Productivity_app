import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal.dart';
import '../../providers/goal_provider.dart';
import '../../app/theme.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

/// Create/Edit Goal Screen - Dynamic & Flexible V2
class CreateGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;

  const CreateGoalScreen({super.key, this.goal});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;

  // Dynamic State
  GoalType _type = GoalType.monthly;
  String _statType = 'strength';
  GoalUnit _unit = GoalUnit.quests;

  // Custom Dates
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Milestones
  List<Milestone> _milestones = [];

  // Animation for expanding custom date pickers
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.goal?.description ?? '',
    );
    _targetController = TextEditingController(
      text: widget.goal?.targetValue.toString() ?? '10',
    );

    if (widget.goal != null) {
      _type = widget.goal!.type;
      _statType = widget.goal!.statType;
      _unit = widget.goal!.unit;
      _milestones = List.from(widget.goal!.milestones);
      if (_type == GoalType.custom) {
        _customStartDate = widget.goal!.startDate;
        _customEndDate = widget.goal!.endDate;
        _animController.value = 1.0;
      }
    }

    _targetController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  // Calculate End Date
  DateTime get _calculatedEndDate {
    final start = _customStartDate ?? DateTime.now();
    if (_type == GoalType.monthly) {
      return DateTime(start.year, start.month + 1, 0);
    } else if (_type == GoalType.yearly) {
      return DateTime(
        start.year + 1,
        12,
        31,
      ); // Wait, this ends *next* year. Standard yearly ends Dec 31 of *current* year usually.
      // Let's make it end of current year if starting now, or 365 days. Let's stick to simple end of current year.
    }
    return _customEndDate ?? start.add(const Duration(days: 30));
  }

  // Smart Pace Calculation
  String get _dailyPace {
    final target = int.tryParse(_targetController.text) ?? 0;
    if (target <= 0) return '0.0';

    final start = _customStartDate ?? DateTime.now();
    final end = _type == GoalType.yearly
        ? DateTime(start.year, 12, 31)
        : _calculatedEndDate;

    final days = end.difference(start).inDays;
    if (days <= 0) return target.toStringAsFixed(1);

    return (target / days).toStringAsFixed(1);
  }

  Color get _statColor {
    switch (_statType.toLowerCase()) {
      case 'strength':
        return Colors.redAccent;
      case 'intelligence':
        return Colors.blueAccent;
      case 'discipline':
        return Colors.greenAccent;
      case 'wealth':
        return Colors.amberAccent;
      case 'charisma':
        return Colors.purpleAccent;
      default:
        return AppTheme.primaryPurple;
    }
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    if (_type == GoalType.custom &&
        (_customEndDate == null || _customStartDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select both start and end dates for Custom goal.',
          ),
        ),
      );
      return;
    }

    final start = _customStartDate ?? DateTime.now();
    final endDate = _type == GoalType.yearly
        ? DateTime(start.year, 12, 31)
        : _calculatedEndDate;

    final goal = Goal(
      id: widget.goal?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      statType: _statType,
      targetValue: int.parse(_targetController.text),
      currentValue: widget.goal?.currentValue ?? 0,
      unit: _unit,
      startDate: start,
      endDate: endDate,
      milestones: _milestones,
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
    );

    if (widget.goal == null) {
      ref.read(goalProvider.notifier).createGoal(goal);
    } else {
      ref.read(goalProvider.notifier).updateGoal(goal);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        title: Text(
          widget.goal == null ? 'Forge Goal' : 'Reforge Goal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: _statColor),
            onPressed: _saveGoal,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Dynamic Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statColor.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  // 1. Core Info
                  _buildPremiumTextField(
                    controller: _titleController,
                    label: 'Name your Ambition...',
                    hintText: 'e.g., Become a Master Coder',
                    icon: Icons.title,
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? 'A name is required to forge this contract.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    controller: _descriptionController,
                    label: 'What drives this ambition? (Optional)',
                    hintText: 'Add extra motivation...',
                    icon: Icons.notes,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // 2. Stat Selection (Visual)
                  const Text(
                    'CHOOSE STAT CATEGORY',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          {
                            'id': 'strength',
                            'icon': Icons.fitness_center,
                            'color': Colors.redAccent,
                            'name': 'Strength',
                          },
                          {
                            'id': 'intelligence',
                            'icon': Icons.psychology,
                            'color': Colors.blueAccent,
                            'name': 'Intelligence',
                          },
                          {
                            'id': 'discipline',
                            'icon': Icons.self_improvement,
                            'color': Colors.greenAccent,
                            'name': 'Discipline',
                          },
                          {
                            'id': 'wealth',
                            'icon': Icons.attach_money,
                            'color': Colors.amberAccent,
                            'name': 'Wealth',
                          },
                          {
                            'id': 'charisma',
                            'icon': Icons.speaker_notes,
                            'color': Colors.purpleAccent,
                            'name': 'Charisma',
                          },
                          {
                            'id': 'total',
                            'icon': Icons.star,
                            'color': AppTheme.gold,
                            'name': 'Overall',
                          },
                        ].map((stat) {
                          final isSelected = _statType == stat['id'];
                          final statColor = stat['color'] as Color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _statType = stat['id'] as String;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? statColor.withOpacity(0.15)
                                    : AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? statColor.withOpacity(0.8)
                                      : Colors.white12,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    stat['icon'] as IconData,
                                    size: 16,
                                    color: isSelected
                                        ? statColor
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    stat['name'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? statColor.withOpacity(0.9)
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 3. Timeframe & Pacing
                  const Text(
                    'TIMEFRAME & TARGET',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildTimeframeSelector(),

                        // Custom Date Pickers (Animated Expansion)
                        SizeTransition(
                          sizeFactor: CurvedAnimation(
                            parent: _animController,
                            curve: Curves.easeOutCubic,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDateButton(
                                    'Start Date',
                                    _customStartDate ?? DateTime.now(),
                                    true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateButton(
                                    'End Date',
                                    _customEndDate ?? DateTime.now(),
                                    false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Divider(
                          color: Colors.white.withOpacity(0.1),
                          height: 32,
                        ),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildPremiumTextField(
                                controller: _targetController,
                                label: 'Target Amount',
                                hintText: 'Enter target',
                                icon: Icons.track_changes,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v?.trim().isEmpty ?? true)
                                    return 'Required';
                                  if (int.tryParse(v!) == null ||
                                      int.parse(v) <= 0)
                                    return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<GoalUnit>(
                                isExpanded: true,
                                initialValue: _unit,
                                dropdownColor: const Color(0xFF1E1A35),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  labelText: 'Unit',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryPurple,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.2),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                items: GoalUnit.values.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u.displayName.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _unit = v!),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _statColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _statColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    color: _statColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Required Pace:',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$_dailyPace ${_unit.displayName}/day',
                                style: TextStyle(
                                  color: _statColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Milestone Builder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MILESTONES',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _milestones.add(
                              Milestone(value: 0, label: 'New Checkpoint'),
                            );
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Node'),
                        style: TextButton.styleFrom(
                          foregroundColor: _statColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_milestones.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          "No milestones set.\nAdding milestones unlocks mini-achievements!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_milestones.length, (index) {
                      final m = _milestones[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statColor.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: _statColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: m.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Milestone',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  _milestones[index] = Milestone(
                                    value: m.value,
                                    label: val,
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 16,
                              color: Colors.white.withOpacity(0.1),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: m.value > 0
                                    ? m.value.toString()
                                    : '',
                                style: TextStyle(
                                  color: _statColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Target',
                                  hintStyle: TextStyle(
                                    color: _statColor.withOpacity(0.3),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  prefixText: '#',
                                  prefixStyle: TextStyle(
                                    color: _statColor.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                onChanged: (val) {
                                  _milestones[index] = Milestone(
                                    value: int.tryParse(val) ?? 0,
                                    label: m.label,
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white30,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _milestones.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 100), // padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _saveGoal,
            backgroundColor: _statColor,
            elevation: 8,
            label: Text(
              widget.goal == null ? 'SEAL CONTRACT' : 'UPDATE CONTRACT',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            icon: const Icon(Icons.verified, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 13,
        ),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppTheme.primaryPurple,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      ),
      validator: validator,
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: GoalType.values.map((type) {
          final isSelected = _type == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _type = type;
                  if (type == GoalType.custom) {
                    _animController.forward();
                  } else {
                    _animController.reverse();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _statColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _statColor.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    type.displayName.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? _statColor : Colors.white54,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: isStart
              ? DateTime.now().subtract(const Duration(days: 365))
              : (_customStartDate ?? DateTime.now()),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: _statColor,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1A1630),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _customStartDate = picked;
              if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
                _customEndDate = picked.add(const Duration(days: 1));
              }
            } else {
              _customEndDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, color: _statColor, size: 14),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
