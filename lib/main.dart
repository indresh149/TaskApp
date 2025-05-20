import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/app_config.dart';
import 'package:notesapp/core/network/network_info.dart';
import 'package:notesapp/core/theme/app_theme.dart';
import 'package:notesapp/data/datasources/local/task_local_data_source.dart';
import 'package:notesapp/data/datasources/remote/task_remote_data_source.dart';
import 'package:notesapp/data/repositories/task_repository_impl.dart';
import 'package:notesapp/domain/repositories/task_repository.dart';
import 'package:notesapp/presentation/blocs/simple_bloc_observer.dart';
import 'package:notesapp/presentation/blocs/theme/theme_cubit.dart';
import 'package:notesapp/routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('FlutterError: ${details.exception}',
        stackTrace: details.stack,
        error: details.exception,
        name: 'FlutterErrorHandler');
  };

  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = SimpleBlocObserver();

  final TaskLocalDataSource taskLocalDataSource = TaskLocalDataSource();
  final NetworkInfo networkInfo = NetworkInfoImpl(Connectivity());
  final TaskRemoteDataSource taskRemoteDataSource =
      TaskRemoteDataSourceImpl(client: http.Client());

  final TaskRepository taskRepository = TaskRepositoryImpl(
    localDataSource: taskLocalDataSource,
    remoteDataSource: taskRemoteDataSource,
    networkInfo: networkInfo,
  );

  runApp(
    RepositoryProvider<TaskRepository>(
      create: (context) => taskRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: AppConfig.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.themeMode,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: '/',
        );
      },
    );
  }
}
