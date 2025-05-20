import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:notesapp/app_config.dart';
import 'package:notesapp/core/errors/failure.dart';
import 'package:notesapp/data/models/task_model.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getAllTasks(String? token);
  Future<TaskModel> addTask(TaskModel task, String? token);
  Future<TaskModel> updateTask(TaskModel task, String? token);
  Future<void> deleteTask(String taskId, String? token);

  Future<List<TaskModel>> syncTasks(List<TaskModel> localTasks, String? token);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final http.Client client;
  final String _baseUrl = AppConfig.apiBaseUrl;

  TaskRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<TaskModel>> getAllTasks(String? token) async {
    // Simulate API call
    developer.log('Fetching all tasks from remote',
        name: 'TaskRemoteDataSource');
    final response = await client
        .get(
          Uri.parse('$_baseUrl/tasks'),
          headers: _getHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData
          .map((taskJson) =>
              TaskModel.fromJson(taskJson).copyWith(isSynced: true))
          .toList();
    } else if (response.statusCode == 401) {
      throw const ServerFailure('Unauthorized. Please login again.');
    } else {
      developer.log(
          'Error fetching tasks: ${response.statusCode} ${response.body}',
          name: 'TaskRemoteDataSource');
      throw ServerFailure(
          'Failed to load tasks from server. Status: ${response.statusCode}');
    }
  }

  @override
  Future<TaskModel> addTask(TaskModel task, String? token) async {
    developer.log('Adding task to remote: ${task.title}',
        name: 'TaskRemoteDataSource');
    final response = await client
        .post(
          Uri.parse('$_baseUrl/tasks'),
          headers: _getHeaders(token),
          body: json.encode(task.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return TaskModel.fromJson(json.decode(response.body))
          .copyWith(isSynced: true);
    } else if (response.statusCode == 401) {
      throw const ServerFailure('Unauthorized. Cannot add task.');
    } else {
      developer.log(
          'Error adding task: ${response.statusCode} ${response.body}',
          name: 'TaskRemoteDataSource');
      throw ServerFailure('Failed to add task. Status: ${response.statusCode}');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task, String? token) async {
    developer.log('Updating task on remote: ${task.id}',
        name: 'TaskRemoteDataSource');
    final response = await client
        .put(
          Uri.parse('$_baseUrl/tasks/${task.id}'),
          headers: _getHeaders(token),
          body: json.encode(task.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return TaskModel.fromJson(json.decode(response.body))
          .copyWith(isSynced: true);
    } else if (response.statusCode == 401) {
      throw const ServerFailure('Unauthorized. Cannot update task.');
    } else if (response.statusCode == 404) {
      throw const ServerFailure('Task not found on server.');
    } else {
      developer.log(
          'Error updating task: ${response.statusCode} ${response.body}',
          name: 'TaskRemoteDataSource');
      throw ServerFailure(
          'Failed to update task. Status: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteTask(String taskId, String? token) async {
    developer.log('Deleting task from remote: $taskId',
        name: 'TaskRemoteDataSource');
    final response = await client
        .delete(
          Uri.parse('$_baseUrl/tasks/$taskId'),
          headers: _getHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      throw const ServerFailure('Unauthorized. Cannot delete task.');
    } else if (response.statusCode == 404) {
      developer.log('Task not found on server for deletion: $taskId',
          name: 'TaskRemoteDataSource');
      return;
    } else {
      developer.log(
          'Error deleting task: ${response.statusCode} ${response.body}',
          name: 'TaskRemoteDataSource');
      throw ServerFailure(
          'Failed to delete task. Status: ${response.statusCode}');
    }
  }

  @override
  Future<List<TaskModel>> syncTasks(
      List<TaskModel> localTasks, String? token) async {
    developer.log('Syncing ${localTasks.length} tasks with remote',
        name: 'TaskRemoteDataSource');

    final response = await client
        .post(
          Uri.parse('$_baseUrl/tasks/sync'),
          headers: _getHeaders(token),
          body: json.encode(localTasks.map((task) => task.toJson()).toList()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);

      return jsonData
          .map((taskJson) =>
              TaskModel.fromJson(taskJson).copyWith(isSynced: true))
          .toList();
    } else if (response.statusCode == 401) {
      throw const ServerFailure('Unauthorized. Sync failed.');
    } else {
      developer.log(
          'Error syncing tasks: ${response.statusCode} ${response.body}',
          name: 'TaskRemoteDataSource');
      throw ServerFailure(
          'Failed to sync tasks. Status: ${response.statusCode}');
    }
  }

  Future<T> _requestWithRetry<T>(Future<T> Function() requestFunction,
      {int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        return await requestFunction();
      } on SocketException catch (e) {
        developer.log('Network error (attempt ${attempt + 1}): $e',
            name: 'TaskRemoteDataSource');
        attempt++;
        if (attempt >= retries)
          throw NetworkFailure('Failed after $retries attempts: $e');
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on TimeoutException catch (e) {
        developer.log('Request timeout (attempt ${attempt + 1}): $e',
            name: 'TaskRemoteDataSource');
        attempt++;
        if (attempt >= retries)
          throw NetworkFailure('Request timed out after $retries attempts: $e');
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        rethrow;
      }
    }
    throw const UnknownFailure('Should not reach here in retry logic.');
  }
}
