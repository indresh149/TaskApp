import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:uuid/uuid.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.createdDate,
    super.dueDate,
    super.priority,
    super.status,
    super.tags,
    super.isSynced,
  });

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdDate: entity.createdDate,
      dueDate: entity.dueDate,
      priority: entity.priority,
      status: entity.status,
      tags: entity.tags,
      isSynced: entity.isSynced,
    );
  }

  factory TaskModel.fromDbMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      createdDate: DateTime.parse(map['createdDate'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      priority: stringToPriority(map['priority'] as String),
      status: stringToTaskStatus(map['status'] as String),
      tags: map['tags'] != null ? (map['tags'] as String).split(',') : null,
      isSynced: map['isSynced'] == 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priorityToString(priority),
      'status': taskStatusToString(status),
      'tags': tags?.join(','),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] as String,
      description: json['description'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: stringToPriority(json['priority'] as String? ?? 'medium'),
      status: stringToTaskStatus(json['status'] as String? ?? 'todo'),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isSynced: json['isSynced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priorityToString(priority),
      'status': taskStatusToString(status),
      'tags': tags,
    };
  }

  @override
  TaskModel copyWith({
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
    return TaskModel(
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
