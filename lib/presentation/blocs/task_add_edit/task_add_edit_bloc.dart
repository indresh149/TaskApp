import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

part 'task_add_edit_event.dart';
part 'task_add_edit_state.dart';

class TaskAddEditBloc extends Bloc<TaskAddEditEvent, TaskAddEditState> {
  final TaskRepository _taskRepository;
  final String? _editingTaskId; // If null, it's a new task

  TaskAddEditBloc({
    required TaskRepository taskRepository,
    String? editingTaskId, // Passed if editing an existing task
  })  : _taskRepository = taskRepository,
        _editingTaskId = editingTaskId,
        super(editingTaskId == null
                ? TaskAddEditState.newTask() // Initial state for new task
                : const TaskAddEditState(
                    status: TaskAddEditStatus.initial,
                    isEditing: true) // Initial for editing
            ) {
    on<LoadTaskForEditing>(_onLoadTaskForEditing);
    on<InitializeNewTask>(_onInitializeNewTask);
    on<TitleChanged>((event, emit) => emit(state.copyWith(title: event.title)));
    on<DescriptionChanged>(
        (event, emit) => emit(state.copyWith(description: event.description)));
    on<PriorityChanged>(
        (event, emit) => emit(state.copyWith(priority: event.priority)));
    on<StatusChanged>(
        (event, emit) => emit(state.copyWith(taskStatus: event.status)));
    on<DueDateChanged>((event, emit) => emit(state.copyWith(
        dueDate: event.dueDate,
        clearDueDate: event.dueDate == null && state.dueDate != null)));
    on<TagAdded>(_onTagAdded);
    on<TagRemoved>(_onTagRemoved);
    on<SaveTaskRequested>(_onSaveTaskRequested);

    // If editing, dispatch an event to load the task data.
    if (_editingTaskId != null) {
      add(LoadTaskForEditing(_editingTaskId!));
    }
  }

  Future<void> _onLoadTaskForEditing(
      LoadTaskForEditing event, Emitter<TaskAddEditState> emit) async {
    emit(state.copyWith(status: TaskAddEditStatus.loading));
    final result = await _taskRepository.getTaskById(event.taskId);
    result.fold(
      (failure) {
        emit(state.copyWith(
            status: TaskAddEditStatus.failure, errorMessage: failure.message));
      },
      (task) {
        if (task != null) {
          emit(state.copyWith(
            status: TaskAddEditStatus.loaded,
            initialTask: task,
            title: task.title,
            description: task.description,
            priority: task.priority,
            taskStatus: task.status,
            dueDate: task.dueDate,
            tags: List<String>.from(task.tags ?? []),
            isEditing: true,
          ));
        } else {
          emit(state.copyWith(
              status: TaskAddEditStatus.failure,
              errorMessage: 'Task not found.'));
        }
      },
    );
  }

  void _onInitializeNewTask(
      InitializeNewTask event, Emitter<TaskAddEditState> emit) {
    emit(TaskAddEditState.newTask());
  }

  void _onTagAdded(TagAdded event, Emitter<TaskAddEditState> emit) {
    if (event.tag.isNotEmpty && !state.tags.contains(event.tag)) {
      final updatedTags = List<String>.from(state.tags)..add(event.tag);
      emit(state.copyWith(tags: updatedTags));
    }
  }

  void _onTagRemoved(TagRemoved event, Emitter<TaskAddEditState> emit) {
    final updatedTags = List<String>.from(state.tags)..remove(event.tag);
    emit(state.copyWith(tags: updatedTags));
  }

  Future<void> _onSaveTaskRequested(
      SaveTaskRequested event, Emitter<TaskAddEditState> emit) async {
    emit(state.copyWith(status: TaskAddEditStatus.loading));

    if (state.title.isEmpty) {
      emit(state.copyWith(
          status: TaskAddEditStatus.failure,
          errorMessage: 'Title cannot be empty.'));
      return;
    }

    final taskToSave = TaskEntity(
      id: state.isEditing ? state.initialTask!.id : const Uuid().v4(),
      title: state.title,
      description: state.description,
      createdDate:
          state.isEditing ? state.initialTask!.createdDate : DateTime.now(),
      dueDate: state.dueDate,
      priority: state.priority,
      status: state.taskStatus,
      tags: state.tags,
      isSynced: false,
    );

    final result = state.isEditing
        ? await _taskRepository.updateTask(taskToSave)
        : await _taskRepository.addTask(taskToSave);

    result.fold(
      (failure) {
        emit(state.copyWith(
            status: TaskAddEditStatus.failure, errorMessage: failure.message));
        developer.log('Error saving task: ${failure.message}',
            name: 'TaskAddEditBloc');
      },
      (_) {
        emit(state.copyWith(status: TaskAddEditStatus.success));
        developer.log('Task saved successfully: ${taskToSave.id}',
            name: 'TaskAddEditBloc');
      },
    );
  }
}
