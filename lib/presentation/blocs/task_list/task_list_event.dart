// lib/presentation/blocs/task_list/task_list_event.dart
part of 'task_list_bloc.dart';

abstract class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

class FetchTasks extends TaskListEvent {
  final bool forceRemote;
  const FetchTasks({this.forceRemote = false});

  @override
  List<Object?> get props => [forceRemote];
}

class DeleteTask extends TaskListEvent {
  final String taskId;
  const DeleteTask(this.taskId);

  @override
  List<Object> get props => [taskId];
}

class SearchTasks extends TaskListEvent {
  final String query;
  const SearchTasks(this.query);

  @override
  List<Object> get props => [query];
}

class FilterTasksByStatus extends TaskListEvent {
  final TaskStatus? status;
  const FilterTasksByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class FilterTasksByPriority extends TaskListEvent {
  final Priority? priority;
  const FilterTasksByPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

class ClearTaskFilters extends TaskListEvent {}

class SyncTasks extends TaskListEvent {}
