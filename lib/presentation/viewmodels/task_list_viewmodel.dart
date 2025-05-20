import 'package:flutter/material.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';

import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';
import 'dart:async';
import 'dart:developer' as developer;

enum TaskListViewState { initial, loading, loaded, error, empty }

class TaskListViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;

  TaskListViewModel({required TaskRepository taskRepository})
      : _taskRepository = taskRepository {
    // fetchTasks(); // Optionally fetch on init
  }

  List<TaskEntity> _tasks = [];
  List<TaskEntity> get tasks => _filteredTasks;

  List<TaskEntity> _filteredTasks = [];

  TaskListViewState _state = TaskListViewState.initial;
  TaskListViewState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _searchQuery = '';
  Timer? _debounce;

  TaskStatus? _filterStatus;
  Priority? _filterPriority;
  List<String>? _filterTags;

  Future<void> fetchTasks({bool forceRemote = false}) async {
    _setState(TaskListViewState.loading);

    if (forceRemote) {
      await syncTasks(showLoading: false);
    }

    final result = await _taskRepository.getAllTasks();
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(TaskListViewState.error);
        developer.log('Error fetching tasks: $_errorMessage',
            name: 'TaskListViewModel');
      },
      (taskList) {
        _tasks = taskList;
        _applyFiltersAndSort();
        if (_filteredTasks.isEmpty) {
          _setState(TaskListViewState.empty);
        } else {
          _setState(TaskListViewState.loaded);
        }
        developer.log('Tasks fetched successfully: ${_tasks.length} tasks',
            name: 'TaskListViewModel');
      },
    );
  }

  Future<void> deleteTask(String id) async {
    final originalTasks = List<TaskEntity>.from(_tasks);
    final originalFilteredTasks = List<TaskEntity>.from(_filteredTasks);
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    final filteredTaskIndex =
        _filteredTasks.indexWhere((task) => task.id == id);

    if (taskIndex != -1) _tasks.removeAt(taskIndex);
    if (filteredTaskIndex != -1) _filteredTasks.removeAt(filteredTaskIndex);

    _setState(
        _tasks.isEmpty ? TaskListViewState.empty : TaskListViewState.loaded);
    notifyListeners();

    final result = await _taskRepository.deleteTask(id);
    result.fold(
      (failure) {
        _errorMessage = failure.message;

        _tasks = originalTasks;
        _filteredTasks = originalFilteredTasks;
        _setState(_tasks.isEmpty
            ? TaskListViewState.empty
            : TaskListViewState.loaded);
        notifyListeners();

        developer.log('Error deleting task $id: $_errorMessage',
            name: 'TaskListViewModel');
        throw failure;
      },
      (_) {
        developer.log('Task $id deleted successfully.',
            name: 'TaskListViewModel');
      },
    );
  }

  void searchTasks(String query) {
    _searchQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applyFiltersAndSort();
      notifyListeners();
    });
  }

  void setFilterByStatus(TaskStatus? status) {
    _filterStatus = status;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFilterByPriority(Priority? priority) {
    _filterPriority = priority;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFilterByTags(List<String>? tags) {
    _filterTags = tags;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filterPriority = null;
    _filterTags = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    Iterable<TaskEntity> tempTasks = List.from(_tasks);

    // Search
    if (_searchQuery.isNotEmpty) {
      tempTasks = tempTasks.where((task) =>
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase()));
    }

    // Filter by Status
    if (_filterStatus != null) {
      tempTasks = tempTasks.where((task) => task.status == _filterStatus);
    }

    // Filter by Priority
    if (_filterPriority != null) {
      tempTasks = tempTasks.where((task) => task.priority == _filterPriority);
    }

    // Filter by Tags (assuming tags is List<String> and task.tags contains some of these)
    if (_filterTags != null && _filterTags!.isNotEmpty) {
      tempTasks = tempTasks.where((task) =>
          task.tags != null &&
          _filterTags!.any((filterTag) => task.tags!.contains(filterTag)));
    }

    // Sorting (Example: by createdDate descending)
    _filteredTasks = tempTasks.toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    // Add more sorting options here based on user selection

    if (_filteredTasks.isEmpty && _tasks.isNotEmpty) {
      _setState(TaskListViewState.empty);
    } else if (_filteredTasks.isEmpty && _tasks.isEmpty) {
      _setState(TaskListViewState.empty);
    } else {
      _setState(TaskListViewState.loaded);
    }
  }

  Future<void> syncTasks({bool showLoading = true}) async {
    if (showLoading) _setState(TaskListViewState.loading);

    final result = await _taskRepository.syncTasks();
    result.fold(
      (failure) {
        _errorMessage = "Sync failed: ${failure.message}";

        if (_state == TaskListViewState.loading && showLoading) {
          _setState(TaskListViewState.error);
        }
        developer.log(_errorMessage, name: 'TaskListViewModel');

        throw failure;
      },
      (_) {
        developer.log('Sync successful. Refetching tasks.',
            name: 'TaskListViewModel');
      },
    );

    await fetchTasks();
  }

  void _setState(TaskListViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
