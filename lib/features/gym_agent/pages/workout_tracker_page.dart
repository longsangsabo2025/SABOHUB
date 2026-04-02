import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_plan.dart';
import '../models/gym_session.dart';
import '../services/gym_repository.dart';

// ── State ──────────────────────────────────────────────────────

class _SetEntry {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  bool isDone;

  _SetEntry({String weight = '', String reps = ''})
      : weightCtrl = TextEditingController(text: weight),
        repsCtrl = TextEditingController(text: reps),
        isDone = false;

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

class _ExerciseState {
  final PlannedExercise exercise;
  final List<_SetEntry> sets;
  bool isExpanded;

  _ExerciseState(this.exercise)
      : sets = List.generate(
          exercise.sets,
          (_) => _SetEntry(
            weight: exercise.weight?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '',
            reps: exercise.reps.replaceAll(RegExp(r'[^0-9]'), ''),
          ),
        ),
        isExpanded = false;
}

// ── WorkoutTrackerPage ─────────────────────────────────────────

class WorkoutTrackerPage extends ConsumerStatefulWidget {
  final PlannedWorkout workout;

  const WorkoutTrackerPage({super.key, required this.workout});

  @override
  ConsumerState<WorkoutTrackerPage> createState() => _WorkoutTrackerPageState();
}

class _WorkoutTrackerPageState extends ConsumerState<WorkoutTrackerPage> {
  static const _gymColor = Color(0xFF10B981);

  late final List<_ExerciseState> _exercises;
  late final DateTime _startTime;
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  bool _isSaving = false;
  int _currentExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _exercises = widget.workout.exercises
        .map((e) => _ExerciseState(e))
        .toList();

    if (_exercises.isNotEmpty) _exercises[0].isExpanded = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startTime));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final e in _exercises) {
      for (final s in e.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  String get _elapsedText {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  int get _completedSets => _exercises.fold(
      0, (sum, e) => sum + e.sets.where((s) => s.isDone).length);

  int get _totalSets =>
      _exercises.fold(0, (sum, e) => sum + e.sets.length);

  double get _progressPercent =>
      _totalSets > 0 ? _completedSets / _totalSets : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmExit,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.workout.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '⏱ $_elapsedText',
              style: const TextStyle(fontSize: 12, color: _gymColor),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Hoàn thành'),
              style: FilledButton.styleFrom(
                backgroundColor: _gymColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _isSaving ? null : _finishWorkout,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _progressPercent,
            backgroundColor: Colors.grey.shade200,
            color: _gymColor,
            minHeight: 6,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _gymColor.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(Icons.fitness_center, '$_completedSets/$_totalSets', 'sets xong'),
                _statChip(Icons.list_alt, '${_exercises.length}', 'bài tập'),
                _statChip(Icons.timer_outlined, '~${widget.workout.estimatedMinutes}\'', 'dự kiến'),
              ],
            ),
          ),
          // Exercise list
          Expanded(
            child: _exercises.isEmpty
                ? const Center(child: Text('Không có bài tập nào'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: _exercises.length,
                    itemBuilder: (ctx, i) => _ExerciseCard(
                      key: ValueKey(i),
                      state: _exercises[i],
                      index: i,
                      gymColor: _gymColor,
                      isCurrent: i == _currentExerciseIndex,
                      onExpand: () => setState(() {
                        _currentExerciseIndex = i;
                        _exercises[i].isExpanded = !_exercises[i].isExpanded;
                      }),
                      onSetDone: (setIdx) => setState(() {
                        _exercises[i].sets[setIdx].isDone =
                            !_exercises[i].sets[setIdx].isDone;
                        // auto-advance to next exercise when all sets done
                        if (_exercises[i].sets.every((s) => s.isDone)) {
                          if (i + 1 < _exercises.length) {
                            _exercises[i].isExpanded = false;
                            _currentExerciseIndex = i + 1;
                            _exercises[i + 1].isExpanded = true;
                          }
                        }
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _gymColor),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bỏ buổi tập?'),
        content: const Text('Dữ liệu chưa được lưu sẽ bị mất.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tiếp tục tập')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit tracker
            },
            child: const Text('Bỏ buổi tập'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout() async {
    // Show finish dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FinishDialog(),
    );
    if (result == null) return; // cancelled

    setState(() => _isSaving = true);

    try {
      final repo = GymRepository.instance;
      final sessionId = await repo.createSession(
        _buildGymSession(),
      );

      await repo.completeSession(
        sessionId,
        endedAt: DateTime.now(),
        moodRating: result['mood'] as int?,
        energyLevel: result['energy'] as int?,
        notes: result['notes'] as String?,
      );

      // Log each exercise + sets
      for (int i = 0; i < _exercises.length; i++) {
        final ex = _exercises[i];
        final doneSets = ex.sets.where((s) => s.isDone).toList();
        if (doneSets.isEmpty) continue;

        final exerciseLogId = await repo.addExerciseLog(
          sessionId: sessionId,
          exerciseId: ex.exercise.name.toLowerCase().replaceAll(' ', '_'),
          exerciseName: ex.exercise.name,
          sortOrder: i,
        );

        for (int j = 0; j < doneSets.length; j++) {
          final s = doneSets[j];
          final weight = double.tryParse(s.weightCtrl.text.trim());
          final reps = int.tryParse(s.repsCtrl.text.trim()) ?? 0;
          if (reps > 0) {
            await repo.addSetLog(
              exerciseLogId: exerciseLogId,
              setNumber: j + 1,
              reps: reps,
              weight: weight,
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // return success to caller
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Buổi tập hoàn thành! $_elapsedText • $_completedSets sets'),
            backgroundColor: _gymColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi lưu buổi tập: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  GymSession _buildGymSession() {
    return GymSession(
      id: '',
      userId: '',
      workoutName: widget.workout.name,
      startedAt: _startTime,
    );
  }
}

// ── Exercise Card ─────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final _ExerciseState state;
  final int index;
  final Color gymColor;
  final bool isCurrent;
  final VoidCallback onExpand;
  final ValueChanged<int> onSetDone;

  const _ExerciseCard({
    required super.key,
    required this.state,
    required this.index,
    required this.gymColor,
    required this.isCurrent,
    required this.onExpand,
    required this.onSetDone,
  });

  bool get _allDone => state.sets.every((s) => s.isDone);
  int get _doneSets => state.sets.where((s) => s.isDone).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isCurrent ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _allDone
              ? gymColor.withValues(alpha: 0.5)
              : isCurrent
                  ? gymColor.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onExpand,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _allDone
                          ? gymColor
                          : gymColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _allDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: gymColor),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.exercise.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration:
                                _allDone ? TextDecoration.lineThrough : null,
                            color:
                                _allDone ? Colors.grey[500] : null,
                          ),
                        ),
                        Text(
                          '${state.exercise.sets} sets × ${state.exercise.reps} reps'
                          '${state.exercise.weight != null ? ' • ${state.exercise.weight}' : ''}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (_doneSets > 0 && !_allDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: gymColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_doneSets/${state.sets.length}',
                        style: TextStyle(
                            fontSize: 11,
                            color: gymColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    state.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),

          // Expanded set rows
          if (state.isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('Set',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600])),
                  ),
                  Expanded(
                    child: Text('Kg',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600])),
                  ),
                  Expanded(
                    child: Text('Reps',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600])),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            ...state.sets.asMap().entries.map((entry) => _SetRow(
                  setIndex: entry.key,
                  entry: entry.value,
                  gymColor: gymColor,
                  isDark: isDark,
                  onDone: () => onSetDone(entry.key),
                )),
            if (state.exercise.notes != null &&
                state.exercise.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.exercise.notes!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setIndex;
  final _SetEntry entry;
  final Color gymColor;
  final bool isDark;
  final VoidCallback onDone;

  const _SetRow({
    required this.setIndex,
    required this.entry,
    required this.gymColor,
    required this.isDark,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          // Set number
          Container(
            width: 36,
            height: 32,
            alignment: Alignment.center,
            child: Text(
              '${setIndex + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry.isDone ? gymColor : Colors.grey[600],
              ),
            ),
          ),
          // Weight input
          Expanded(
            child: _InputField(
              controller: entry.weightCtrl,
              hint: 'kg',
              isDone: entry.isDone,
              gymColor: gymColor,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          // Reps input
          Expanded(
            child: _InputField(
              controller: entry.repsCtrl,
              hint: 'reps',
              isDone: entry.isDone,
              gymColor: gymColor,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          // Done checkbox
          GestureDetector(
            onTap: onDone,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.isDone
                    ? gymColor
                    : gymColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: entry.isDone
                      ? gymColor
                      : gymColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: entry.isDone ? Colors.white : gymColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDone;
  final Color gymColor;
  final bool isDark;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.isDone,
    required this.gymColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        enabled: !isDone,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDone ? Colors.grey[400] : null,
          decoration: isDone ? TextDecoration.lineThrough : null,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          filled: true,
          fillColor: isDone
              ? Colors.grey.shade100
              : gymColor.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: gymColor.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: gymColor.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: gymColor, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}

// ── Finish Dialog ─────────────────────────────────────────────

class _FinishDialog extends StatefulWidget {
  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog> {
  static const _gymColor = Color(0xFF10B981);
  int _mood = 3;
  int _energy = 3;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 Hoàn thành buổi tập!'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tâm trạng hôm nay?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _RatingRow(
              value: _mood,
              labels: const ['😞', '😐', '🙂', '😊', '🤩'],
              onChanged: (v) => setState(() => _mood = v),
              color: _gymColor,
            ),
            const SizedBox(height: 16),
            const Text('Mức năng lượng?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _RatingRow(
              value: _energy,
              labels: const ['🪫', '😴', '⚡', '🔥', '💥'],
              onChanged: (v) => setState(() => _energy = v),
              color: _gymColor,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Ghi chú (tuỳ chọn)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _gymColor),
          onPressed: () => Navigator.pop(context, {
            'mood': _mood,
            'energy': _energy,
            'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          }),
          child: const Text('Lưu buổi tập'),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final int value;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final Color color;

  const _RatingRow({
    required this.value,
    required this.labels,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: labels.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final isSelected = value == i;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: color) : null,
            ),
            child: Text(entry.value, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    );
  }
}
