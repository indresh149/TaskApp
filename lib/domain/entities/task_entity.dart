
import 'package:equatable/equatable.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdDate;
  final DateTime? dueDate; 
  final Priority priority;
  final TaskStatus status;
  final List<String>? tags; 
  final bool isSynced; 

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdDate,
    this.dueDate,
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    this.tags,
    this.isSynced = false, 
  });

  @override
  List<Object?> get props => [id, title, description, createdDate, dueDate, priority, status, tags, isSynced];

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdDate,
    DateTime? dueDate,
    bool clearDueDate = false, 
    Priority? priority,
    TaskStatus? status,
    List<String>? tags,
    bool? isSynced,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}