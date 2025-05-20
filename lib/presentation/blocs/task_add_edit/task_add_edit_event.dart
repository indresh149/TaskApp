part of 'task_add_edit_bloc.dart';

abstract class TaskAddEditEvent extends Equatable {
  const TaskAddEditEvent();

  @override
  List<Object?> get props => [];
}

class LoadTaskForEditing extends TaskAddEditEvent {
  final String taskId;
  const LoadTaskForEditing(this.taskId);

  @override
  List<Object> get props => [taskId];
}

class InitializeNewTask extends TaskAddEditEvent {}

class TitleChanged extends TaskAddEditEvent {
  final String title;
  const TitleChanged(this.title);

  @override
  List<Object> get props => [title];
}

class DescriptionChanged extends TaskAddEditEvent {
  final String description;
  const DescriptionChanged(this.description);

  @override
  List<Object> get props => [description];
}

class PriorityChanged extends TaskAddEditEvent {
  final Priority priority;
  const PriorityChanged(this.priority);

  @override
  List<Object> get props => [priority];
}

class StatusChanged extends TaskAddEditEvent {
  final TaskStatus status;
  const StatusChanged(this.status);

  @override
  List<Object> get props => [status];
}

class DueDateChanged extends TaskAddEditEvent {
  final DateTime? dueDate;
  const DueDateChanged(this.dueDate);

  @override
  List<Object?> get props => [dueDate];
}

class TagAdded extends TaskAddEditEvent {
  final String tag;
  const TagAdded(this.tag);

  @override
  List<Object> get props => [tag];
}

class TagRemoved extends TaskAddEditEvent {
  final String tag;
  const TagRemoved(this.tag);

  @override
  List<Object> get props => [tag];
}

class SaveTaskRequested extends TaskAddEditEvent {}
