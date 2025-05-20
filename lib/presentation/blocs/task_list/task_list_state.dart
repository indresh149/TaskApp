
part of 'task_list_bloc.dart';

abstract class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => [];
}

class TaskListInitial extends TaskListState {}

class TaskListLoading extends TaskListState {}

class TaskListLoaded extends TaskListState {
  final List<TaskEntity> tasks;
  final List<TaskEntity> filteredTasks;
  final String? searchQuery;
  final TaskStatus? filterStatus;
  final Priority? filterPriority;
  
  const TaskListLoaded({
    required this.tasks,
    required this.filteredTasks,
    this.searchQuery,
    this.filterStatus,
    this.filterPriority,
    
  });

  @override
  List<Object?> get props => [tasks, filteredTasks, searchQuery, filterStatus, filterPriority];

  TaskListLoaded copyWith({
    List<TaskEntity>? tasks,
    List<TaskEntity>? filteredTasks,
    String? searchQuery,
    bool clearSearchQuery = false,
    TaskStatus? filterStatus,
    bool clearFilterStatus = false,
    Priority? filterPriority,
    bool clearFilterPriority = false,
  }) {
    return TaskListLoaded(
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      filterStatus: clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterPriority: clearFilterPriority ? null : (filterPriority ?? this.filterPriority),
    );
  }
}

class TaskListEmpty extends TaskListState {
    final String message;
    const TaskListEmpty({this.message = AppStrings.noTasksFound});

    @override
    List<Object> get props => [message];
}

class TaskListError extends TaskListState {
  final String message;
  const TaskListError(this.message);

  @override
  List<Object> get props => [message];
}


class TaskListSyncing extends TaskListState {}
class TaskListSyncSuccess extends TaskListLoaded { 
  final String message;
  const TaskListSyncSuccess({
    required super.tasks,
    required super.filteredTasks,
    super.searchQuery,
    super.filterStatus,
    super.filterPriority,
    required this.message
  });
   @override
  List<Object?> get props => [...super.props, message];
}
class TaskListSyncFailure extends TaskListState {
  final String message;
  const TaskListSyncFailure(this.message);
   @override
  List<Object> get props => [message];
}


class TaskDeletionSuccess extends TaskListState {
  final String message;
  const TaskDeletionSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class TaskDeletionFailure extends TaskListState {
  final String message;
  final String taskId; 
  const TaskDeletionFailure(this.message, this.taskId);
  @override
  List<Object> get props => [message, taskId];
}