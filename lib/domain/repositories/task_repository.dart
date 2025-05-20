
import 'package:notesapp/core/errors/failure.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:either_dart/either.dart'; 


typedef FutureEither<T> = Future<Either<Failure, T>>;

abstract class TaskRepository {
  FutureEither<List<TaskEntity>> getAllTasks();
  FutureEither<TaskEntity?> getTaskById(String id);
  FutureEither<void> addTask(TaskEntity task);
  FutureEither<void> updateTask(TaskEntity task);
  FutureEither<void> deleteTask(String id);
  FutureEither<void> syncTasks(); 
}