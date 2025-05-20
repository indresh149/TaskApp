import 'package:notesapp/core/errors/failure.dart';
import 'package:notesapp/core/network/network_info.dart';
import 'package:notesapp/data/datasources/local/task_local_data_source.dart';
import 'package:notesapp/data/datasources/remote/task_remote_data_source.dart';
import 'package:notesapp/data/models/task_model.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';

import 'package:either_dart/either.dart' hide FutureEither;

import 'dart:developer' as developer;
import 'dart:io';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  Future<String?> _getAuthToken() async {
    return null;
  }

  @override
  FutureEither<void> addTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task).copyWith(isSynced: false);
    try {
      await localDataSource.addTask(taskModel);
      developer.log('Task added locally: ${taskModel.id}',
          name: 'TaskRepositoryImpl');

      if (await networkInfo.isConnected) {
        try {
          final String? token = await _getAuthToken();
          final remoteTask = await remoteDataSource.addTask(taskModel, token);
          await localDataSource.updateTask(remoteTask.copyWith(isSynced: true));
          developer.log('Task synced with remote after add: ${remoteTask.id}',
              name: 'TaskRepositoryImpl');
        } on ServerFailure catch (e) {
          developer.log(
              'ServerFailure during remote addTask: ${e.message}. Task remains local, unsynced.',
              name: 'TaskRepositoryImpl');
        } on SocketException catch (e) {
          developer.log(
              'Network error during remote addTask: $e. Task remains local, unsynced.',
              name: 'TaskRepositoryImpl');
        } catch (e) {
          developer.log(
              'Unknown error during remote addTask: $e. Task remains local, unsynced.',
              name: 'TaskRepositoryImpl');
        }
      } else {
        developer.log(
            'No network. Task ${taskModel.id} added locally, unsynced.',
            name: 'TaskRepositoryImpl');
      }
      return Right(null);
    } catch (e) {
      developer.log('CacheFailure during local addTask: ${e.toString()}',
          name: 'TaskRepositoryImpl');
      return Left(CacheFailure('Failed to add task locally: ${e.toString()}'));
    }
  }

  @override
  FutureEither<void> deleteTask(String id) async {
    try {
      await localDataSource.deleteTask(id);
      developer.log('Task deleted locally: $id', name: 'TaskRepositoryImpl');

      if (await networkInfo.isConnected) {
        try {
          final String? token = await _getAuthToken();
          await remoteDataSource.deleteTask(id, token);
          developer.log('Task deleted from remote: $id',
              name: 'TaskRepositoryImpl');
        } on ServerFailure catch (e) {
          developer.log(
              'ServerFailure during remote deleteTask: ${e.message}. Task deleted locally.',
              name: 'TaskRepositoryImpl');
        } on SocketException catch (e) {
          developer.log(
              'Network error during remote deleteTask: $e. Task deleted locally.',
              name: 'TaskRepositoryImpl');
        } catch (e) {
          developer.log(
              'Unknown error during remote deleteTask: $e. Task deleted locally.',
              name: 'TaskRepositoryImpl');
        }
      } else {
        developer.log(
            'No network. Task $id deleted locally. Will need sync for remote deletion.',
            name: 'TaskRepositoryImpl');
      }
      return Right(null);
    } catch (e) {
      developer.log('CacheFailure during local deleteTask: ${e.toString()}',
          name: 'TaskRepositoryImpl');
      return Left(
          CacheFailure('Failed to delete task locally: ${e.toString()}'));
    }
  }

  @override
  FutureEither<List<TaskEntity>> getAllTasks() async {
    if (await networkInfo.isConnected) {
      try {
        final String? token = await _getAuthToken();
        final remoteTasksModels = await remoteDataSource.getAllTasks(token);
        await localDataSource.clearAllTasks();
        final List<TaskModel> tasksToCache = [];
        for (var remoteTaskModel in remoteTasksModels) {
          tasksToCache.add(remoteTaskModel.copyWith(isSynced: true));
        }

        await localDataSource.cacheTasks(tasksToCache);
        developer.log(
            'Fetched ${remoteTasksModels.length} tasks from remote and cached.',
            name: 'TaskRepositoryImpl');
        return Right(tasksToCache);
      } on ServerFailure catch (e) {
        developer.log(
            'ServerFailure fetching from remote: ${e.message}. Falling back to local.',
            name: 'TaskRepositoryImpl');
        return _getAllTasksFromLocal();
      } on SocketException catch (e) {
        developer.log(
            'Network error fetching from remote: $e. Falling back to local.',
            name: 'TaskRepositoryImpl');
        return _getAllTasksFromLocal();
      } catch (e) {
        developer.log(
            'Unknown error fetching from remote: $e. Falling back to local.',
            name: 'TaskRepositoryImpl');
        return _getAllTasksFromLocal();
      }
    } else {
      developer.log('Offline, fetching tasks from local cache.',
          name: 'TaskRepositoryImpl');
      return _getAllTasksFromLocal();
    }
  }

  FutureEither<List<TaskEntity>> _getAllTasksFromLocal() async {
    try {
      final localTaskModels = await localDataSource.getAllTasks();
      return Right(localTaskModels);
    } catch (e) {
      developer.log('CacheFailure fetching from local: ${e.toString()}',
          name: 'TaskRepositoryImpl');
      return Left(CacheFailure(
          'Failed to load tasks from local storage: ${e.toString()}'));
    }
  }

  @override
  FutureEither<TaskEntity?> getTaskById(String id) async {
    try {
      final taskModel = await localDataSource.getTaskById(id);
      if (taskModel != null) {
        return Right(taskModel);
      } else {
        developer.log('Task $id not found locally.',
            name: 'TaskRepositoryImpl');
        return Right(null);
      }
    } catch (e) {
      developer.log('CacheFailure getting task by ID $id: ${e.toString()}',
          name: 'TaskRepositoryImpl');
      return Left(CacheFailure('Failed to get task by ID: ${e.toString()}'));
    }
  }

  @override
  FutureEither<void> updateTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task).copyWith(isSynced: false);
    try {
      await localDataSource.updateTask(taskModel);
      developer.log('Task updated locally: ${taskModel.id}',
          name: 'TaskRepositoryImpl');

      if (await networkInfo.isConnected) {
        try {
          final String? token = await _getAuthToken();
          final updatedRemoteTask =
              await remoteDataSource.updateTask(taskModel, token);
          await localDataSource
              .updateTask(updatedRemoteTask.copyWith(isSynced: true));
          developer.log(
              'Task synced with remote after update: ${updatedRemoteTask.id}',
              name: 'TaskRepositoryImpl');
        } on ServerFailure catch (e) {
          developer.log(
              'ServerFailure during remote updateTask: ${e.message}. Task updated locally, unsynced.',
              name: 'TaskRepositoryImpl');
        } on SocketException catch (e) {
          developer.log(
              'Network error during remote updateTask: $e. Task updated locally, unsynced.',
              name: 'TaskRepositoryImpl');
        } catch (e) {
          developer.log(
              'Unknown error during remote updateTask: $e. Task updated locally, unsynced.',
              name: 'TaskRepositoryImpl');
        }
      } else {
        developer.log(
            'No network. Task ${taskModel.id} updated locally, unsynced.',
            name: 'TaskRepositoryImpl');
      }
      return Right(null);
    } catch (e) {
      developer.log('CacheFailure during local updateTask: ${e.toString()}',
          name: 'TaskRepositoryImpl');
      return Left(
          CacheFailure('Failed to update task locally: ${e.toString()}'));
    }
  }

  @override
  FutureEither<void> syncTasks() async {
    if (!await networkInfo.isConnected) {
      developer.log('Sync skipped: No network connection.',
          name: 'TaskRepositoryImpl');
      return const Left(NetworkFailure('No network connection to sync tasks.'));
    }

    try {
      developer.log('Starting sync process...', name: 'TaskRepositoryImpl');
      final unsyncedLocalTasks = await localDataSource.getUnsyncedTasks();
      developer.log('Found ${unsyncedLocalTasks.length} unsynced local tasks.',
          name: 'TaskRepositoryImpl');

      List<TaskModel> failedToSyncTasks = List.from(unsyncedLocalTasks);

      for (TaskModel localTask in unsyncedLocalTasks) {
        try {
          final String? token = await _getAuthToken();
          TaskModel syncedTask;
          try {
            developer.log(
                'Attempting to update task ${localTask.id} on remote during sync.',
                name: 'TaskRepositoryImpl');
            syncedTask = await remoteDataSource.updateTask(localTask, token);
          } on ServerFailure catch (e) {
            if (e.message.contains("404") ||
                e.message.toLowerCase().contains("not found")) {
              developer.log(
                  'Task ${localTask.id} not found on remote (during sync update attempt), attempting to add.',
                  name: 'TaskRepositoryImpl');
              syncedTask = await remoteDataSource.addTask(localTask, token);
            } else {
              rethrow;
            }
          }

          await localDataSource.updateTask(syncedTask.copyWith(isSynced: true));
          failedToSyncTasks.remove(localTask);
          developer.log(
              'Successfully synced local task ${localTask.id} to remote as ${syncedTask.id}.',
              name: 'TaskRepositoryImpl');
        } catch (e) {
          developer.log(
              'Failed to sync individual task ${localTask.id}: $e. It remains unsynced.',
              name: 'TaskRepositoryImpl');
        }
      }

      developer.log(
          'Fetching all tasks from remote after syncing local changes.',
          name: 'TaskRepositoryImpl');
      final String? token = await _getAuthToken();
      final remoteTasksResult = await remoteDataSource.getAllTasks(token);

      await localDataSource.clearAllTasks();
      final List<TaskModel> tasksToStore = [];
      for (var task in remoteTasksResult) {
        tasksToStore.add(task.copyWith(isSynced: true));
      }
      await localDataSource.cacheTasks(tasksToStore);
      developer.log(
          'Local cache updated with ${remoteTasksResult.length} tasks from remote after sync.',
          name: 'TaskRepositoryImpl');

      if (failedToSyncTasks.isNotEmpty) {
        developer.log(
            '${failedToSyncTasks.length} tasks failed to sync individually but full remote list fetched.',
            name: 'TaskRepositoryImpl');
        return Left(ServerFailure(
            '${failedToSyncTasks.length} tasks could not be synced. Others synced and list refreshed.'));
      }

      developer.log('Sync process completed successfully.',
          name: 'TaskRepositoryImpl');
      return Right(null);
    } on ServerFailure catch (e) {
      developer.log('ServerFailure during sync process: ${e.message}',
          name: 'TaskRepositoryImpl');
      return Left(e);
    } on SocketException catch (e) {
      developer.log('Network error during sync process: $e',
          name: 'TaskRepositoryImpl');
      return const Left(NetworkFailure('Network error during sync.'));
    } catch (e) {
      developer.log('Unknown error during sync process: ${e.toString()}',
          name: 'TaskRepositoryImpl');
      return Left(UnknownFailure('Sync failed: ${e.toString()}'));
    }
  }
}
