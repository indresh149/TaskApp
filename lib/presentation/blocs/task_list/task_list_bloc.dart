import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notesapp/core/constants/app_strings.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';

import 'dart:developer' as developer;
import 'package:stream_transform/stream_transform.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

EventTransformer<E> debounceSequential<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).asyncExpand(mapper);
}

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final TaskRepository _taskRepository;

  List<TaskEntity> _allTasks = [];
  String? _currentSearchQuery;
  TaskStatus? _currentFilterStatus;
  Priority? _currentFilterPriority;

  TaskListBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(TaskListInitial()) {
    on<FetchTasks>(_onFetchTasks);
    on<DeleteTask>(_onDeleteTask);
    on<SearchTasks>(_onSearchTasks,
        transformer: debounceSequential(const Duration(milliseconds: 500)));
    on<FilterTasksByStatus>(_onFilterTasksByStatus);
    on<FilterTasksByPriority>(_onFilterTasksByPriority);
    on<ClearTaskFilters>(_onClearTaskFilters);
    on<SyncTasks>(_onSyncTasks);
  }

  Future<void> _onFetchTasks(
      FetchTasks event, Emitter<TaskListState> emit) async {
    emit(TaskListLoading());
    if (event.forceRemote) {
      final syncResult = await _taskRepository.syncTasks();
      syncResult.fold(
          (failure) => developer.log(
              'Silent sync before fetch failed: ${failure.message}',
              name: 'TaskListBloc'),
          (_) => developer.log('Silent sync before fetch successful.',
              name: 'TaskListBloc'));
    }
    final result = await _taskRepository.getAllTasks();
    result.fold(
      (failure) {
        developer.log('Error fetching tasks: ${failure.message}',
            name: 'TaskListBloc');
        emit(TaskListError(failure.message));
      },
      (tasks) {
        _allTasks = tasks;
        _applyFiltersAndEmit(emit);
      },
    );
  }

  Future<void> _onDeleteTask(
      DeleteTask event, Emitter<TaskListState> emit) async {
    final currentState = state;
    if (currentState is TaskListLoaded) {
      final optimisticTasks = List<TaskEntity>.from(currentState.tasks)
        ..removeWhere((task) => task.id == event.taskId);
      final optimisticFilteredTasks =
          List<TaskEntity>.from(currentState.filteredTasks)
            ..removeWhere((task) => task.id == event.taskId);

      emit(currentState.copyWith(
        tasks: optimisticTasks,
        filteredTasks: optimisticFilteredTasks,
      ));
    }

    final result = await _taskRepository.deleteTask(event.taskId);
    result.fold(
      (failure) {
        developer.log('Error deleting task ${event.taskId}: ${failure.message}',
            name: 'TaskListBloc');
        emit(TaskDeletionFailure(failure.message,
            event.taskId)); // Specific state for deletion failure

        add(const FetchTasks());
      },
      (_) {
        developer.log('Task ${event.taskId} deleted successfully.',
            name: 'TaskListBloc');

        _allTasks.removeWhere((task) => task.id == event.taskId);
        _applyFiltersAndEmit(emit);
      },
    );
  }

  void _onSearchTasks(SearchTasks event, Emitter<TaskListState> emit) {
    _currentSearchQuery = event.query;
    _applyFiltersAndEmit(emit);
  }

  void _onFilterTasksByStatus(
      FilterTasksByStatus event, Emitter<TaskListState> emit) {
    _currentFilterStatus = event.status;
    _applyFiltersAndEmit(emit);
  }

  void _onFilterTasksByPriority(
      FilterTasksByPriority event, Emitter<TaskListState> emit) {
    _currentFilterPriority = event.priority;
    _applyFiltersAndEmit(emit);
  }

  void _onClearTaskFilters(
      ClearTaskFilters event, Emitter<TaskListState> emit) {
    _currentSearchQuery = null;
    _currentFilterStatus = null;
    _currentFilterPriority = null;
    // _currentFilterTags = null;
    _applyFiltersAndEmit(emit);
  }

  Future<void> _onSyncTasks(
      SyncTasks event, Emitter<TaskListState> emit) async {
    emit(TaskListSyncing());
    final result = await _taskRepository.syncTasks();
    result.fold(
      (failure) {
        developer.log('Sync failed: ${failure.message}', name: 'TaskListBloc');
        emit(TaskListSyncFailure(failure.message));

        add(const FetchTasks());
      },
      (_) {
        developer.log('Sync successful. Refetching tasks.',
            name: 'TaskListBloc');

        add(const FetchTasks(forceRemote: true));
      },
    );
  }

  void _applyFiltersAndEmit(Emitter<TaskListState> emit) {
    Iterable<TaskEntity> filtered = List.from(_allTasks);

    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      filtered = filtered.where((task) =>
          task.title
              .toLowerCase()
              .contains(_currentSearchQuery!.toLowerCase()) ||
          task.description
              .toLowerCase()
              .contains(_currentSearchQuery!.toLowerCase()));
    }

    if (_currentFilterStatus != null) {
      filtered = filtered.where((task) => task.status == _currentFilterStatus);
    }

    if (_currentFilterPriority != null) {
      filtered =
          filtered.where((task) => task.priority == _currentFilterPriority);
    }

    final List<TaskEntity> finalFilteredList = filtered.toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    if (finalFilteredList.isEmpty) {
      String emptyMessage = AppStrings.noTasksFound;
      if (_allTasks.isNotEmpty) {
        emptyMessage = "No tasks match your current filters.";
      }
      emit(TaskListEmpty(message: emptyMessage));
    } else {
      emit(TaskListLoaded(
        tasks: _allTasks,
        filteredTasks: finalFilteredList,
        searchQuery: _currentSearchQuery,
        filterStatus: _currentFilterStatus,
        filterPriority: _currentFilterPriority,
      ));
    }
  }
}
