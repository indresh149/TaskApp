// lib/presentation/viewmodels/task_add_edit_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

enum TaskAddEditState { initial, loading, success, error }

class TaskAddEditViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;
  final String? _taskId; // Null if adding new task

  TaskAddEditViewModel({required TaskRepository taskRepository, String? taskId})
      : _taskRepository = taskRepository,
        _taskId = taskId {
    if (isEditing) {
      _loadTaskData();
    } else {
      // Set defaults for new task
      _createdDate = DateTime.now();
      _priority = Priority.medium;
      _status = TaskStatus.todo;
    }
  }

  bool get isEditing => _taskId != null;

  String _title = '';
  String _description = '';
  DateTime? _dueDate;
  late Priority _priority;
  late TaskStatus _status;
  late DateTime _createdDate;
  List<String> _tags = [];

  String get title => _title;
  String get description => _description;
  DateTime? get dueDate => _dueDate;
  Priority get priority => _priority;
  TaskStatus get status => _status;
  DateTime get createdDate => _createdDate;
  List<String> get tags => _tags;

  TaskAddEditState _state = TaskAddEditState.initial;
  TaskAddEditState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> _loadTaskData() async {
    if (!isEditing || _taskId == null) return;
    _setState(TaskAddEditState.loading);
    final result = await _taskRepository.getTaskById(_taskId);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(TaskAddEditState.error);
      },
      (task) {
        if (task != null) {
          _title = task.title;
          _description = task.description;
          _createdDate = task.createdDate;
          _dueDate = task.dueDate;
          _priority = task.priority;
          _status = task.status;
          _tags = List<String>.from(task.tags ?? []);
          _setState(TaskAddEditState.initial);
        } else {
          _errorMessage = 'Task not found.';
          _setState(TaskAddEditState.error);
        }
      },
    );
  }

  void updateTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void updateDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void updateDueDate(DateTime? value) {
    _dueDate = value;
    notifyListeners();
  }

  void updatePriority(Priority value) {
    _priority = value;
    notifyListeners();
  }

  void updateStatus(TaskStatus value) {
    _status = value;
    notifyListeners();
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      _tags.add(tag);
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  Future<bool> saveTask() async {
    _setState(TaskAddEditState.loading);

    final taskToSave = TaskEntity(
      id: _taskId ?? const Uuid().v4(),
      title: _title,
      description: _description,
      createdDate: isEditing ? _createdDate : DateTime.now(),
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      tags: _tags,
      isSynced: false,
    );

    final result = isEditing
        ? await _taskRepository.updateTask(taskToSave)
        : await _taskRepository.addTask(taskToSave);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(TaskAddEditState.error);
        developer.log('Error saving task: $_errorMessage',
            name: 'TaskAddEditViewModel');
        return false;
      },
      (_) {
        _setState(TaskAddEditState.success);
        developer.log('Task saved successfully: ${taskToSave.id}',
            name: 'TaskAddEditViewModel');
        return true;
      },
    );
  }

  void _setState(TaskAddEditState newState) {
    _state = newState;
    notifyListeners();
  }
}
