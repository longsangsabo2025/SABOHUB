import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/management_task.dart';

// =====================================================================
// TaskBoardFilterState — extracted from TaskBoard widget setState vars
// Keeps: search, statusFilter, priorityFilter, dateFilter, sortBy,
//        grouped, selectedIds
// Local-only UI state (quick create form) remains in the widget.
// =====================================================================

/// Date filter options (Todoist-style)
enum TaskDateFilter { today, thisWeek, overdue }

/// Sort options
enum TaskSortBy { smartAuto, deadlineAsc, priorityDesc, statusGroup, createdDesc }

class TaskBoardFilterState {
  final String search;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final TaskDateFilter? dateFilter;
  final TaskSortBy sortBy;
  final bool grouped;
  final Set<String> selectedIds;

  const TaskBoardFilterState({
    this.search = '',
    this.statusFilter,
    this.priorityFilter,
    this.dateFilter,
    this.sortBy = TaskSortBy.smartAuto,
    this.grouped = false,
    this.selectedIds = const {},
  });

  TaskBoardFilterState copyWith({
    String? search,
    TaskStatus? Function()? statusFilter,
    TaskPriority? Function()? priorityFilter,
    TaskDateFilter? Function()? dateFilter,
    TaskSortBy? sortBy,
    bool? grouped,
    Set<String>? selectedIds,
  }) {
    return TaskBoardFilterState(
      search: search ?? this.search,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      priorityFilter: priorityFilter != null ? priorityFilter() : this.priorityFilter,
      dateFilter: dateFilter != null ? dateFilter() : this.dateFilter,
      sortBy: sortBy ?? this.sortBy,
      grouped: grouped ?? this.grouped,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  bool get isSelectMode => selectedIds.isNotEmpty;

  bool get hasFilters =>
      search.isNotEmpty ||
      statusFilter != null ||
      priorityFilter != null ||
      dateFilter != null;
}

class TaskBoardFilterNotifier extends Notifier<TaskBoardFilterState> {
  @override
  TaskBoardFilterState build() => const TaskBoardFilterState();

  void setSearch(String value) => state = state.copyWith(search: value);

  void setStatusFilter(TaskStatus? value) =>
      state = state.copyWith(statusFilter: () => value);

  void toggleStatusFilter(TaskStatus? value) => state = state.copyWith(
        statusFilter: () => state.statusFilter == value ? null : value,
      );

  void setPriorityFilter(TaskPriority? value) =>
      state = state.copyWith(priorityFilter: () => value);

  void setDateFilter(TaskDateFilter? value) =>
      state = state.copyWith(dateFilter: () => value);

  void toggleDateFilter(TaskDateFilter value) => state = state.copyWith(
        dateFilter: () => state.dateFilter == value ? null : value,
      );

  void setSortBy(TaskSortBy value) => state = state.copyWith(sortBy: value);

  void toggleGrouped() => state = state.copyWith(grouped: !state.grouped);

  void toggleSelection(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(selectedIds: ids);
  }

  void addSelection(String id) {
    final ids = Set<String>.from(state.selectedIds)..add(id);
    state = state.copyWith(selectedIds: ids);
  }

  void clearSelection() => state = state.copyWith(selectedIds: {});

  void selectAll(List<String> ids) =>
      state = state.copyWith(selectedIds: ids.toSet());

  void clearFilters() => state = const TaskBoardFilterState();
}

final taskBoardFilterProvider =
    NotifierProvider<TaskBoardFilterNotifier, TaskBoardFilterState>(
  TaskBoardFilterNotifier.new,
);
