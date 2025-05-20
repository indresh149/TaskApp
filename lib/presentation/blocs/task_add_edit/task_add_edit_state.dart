part of 'task_add_edit_bloc.dart';

enum TaskAddEditStatus { initial, loading, success, failure, loaded }

class TaskAddEditState extends Equatable {
  final TaskAddEditStatus status;
  final TaskEntity? initialTask;
  final String title;
  final String description;
  final Priority priority;
  final TaskStatus taskStatus;
  final DateTime? dueDate;
  final List<String> tags;
  final String? errorMessage;
  final bool isEditing;

  const TaskAddEditState({
    this.status = TaskAddEditStatus.initial,
    this.initialTask,
    this.title = '',
    this.description = '',
    this.priority = Priority.medium,
    this.taskStatus = TaskStatus.todo,
    this.dueDate,
    this.tags = const [],
    this.errorMessage,
    this.isEditing = false,
  });

  factory TaskAddEditState.newTask() {
    return const TaskAddEditState(
      priority: Priority.medium,
      taskStatus: TaskStatus.todo,
      tags: [],
      isEditing: false,
      status: TaskAddEditStatus.loaded,
    );
  }

  TaskAddEditState copyWith({
    TaskAddEditStatus? status,
    TaskEntity? initialTask,
    String? title,
    String? description,
    Priority? priority,
    TaskStatus? taskStatus,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<String>? tags,
    String? errorMessage,
    bool? isEditing,
  }) {
    return TaskAddEditState(
      status: status ?? this.status,
      initialTask: initialTask ?? this.initialTask,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      taskStatus: taskStatus ?? this.taskStatus,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      tags: tags ?? this.tags,
      errorMessage: errorMessage ?? this.errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        initialTask,
        title,
        description,
        priority,
        taskStatus,
        dueDate,
        tags,
        errorMessage,
        isEditing,
      ];
}
