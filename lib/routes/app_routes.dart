import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';
import 'package:notesapp/presentation/blocs/task_add_edit/task_add_edit_bloc.dart';
import 'package:notesapp/presentation/blocs/task_list/task_list_bloc.dart';
import 'package:notesapp/presentation/views/task_add_edit_view.dart';
import 'package:notesapp/presentation/views/task_list_view.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
   

    switch (settings.name) {
      case TaskListView.routeName:
        return MaterialPageRoute(
          builder: (context) => BlocProvider<TaskListBloc>(
            create: (ctx) => TaskListBloc(
              taskRepository: RepositoryProvider.of<TaskRepository>(ctx),
            )..add(const FetchTasks()), 
            child: const TaskListView(),
          ),
        );
      case TaskAddEditView.routeNameAdd:
        return MaterialPageRoute(
          builder: (context) => BlocProvider<TaskAddEditBloc>(
            create: (ctx) => TaskAddEditBloc(
              taskRepository: RepositoryProvider.of<TaskRepository>(ctx),
            )..add(InitializeNewTask()), 
            child: const TaskAddEditView(isEditing: false),
          ),
        );
      case TaskAddEditView.routeNameEdit:
        final taskId = settings.arguments as String?;
        if (taskId == null) {
           return _errorRoute('Task ID missing for edit route');
        }
        return MaterialPageRoute(
          builder: (context) => BlocProvider<TaskAddEditBloc>(
            create: (ctx) => TaskAddEditBloc(
              taskRepository: RepositoryProvider.of<TaskRepository>(ctx),
              editingTaskId: taskId, 
            ),
            child: TaskAddEditView(isEditing: true, taskId: taskId),
          ),
        );
      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}