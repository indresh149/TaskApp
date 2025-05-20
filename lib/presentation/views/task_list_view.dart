
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/core/constants/app_strings.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/core/utils/snackbar_utils.dart';
import 'package:notesapp/presentation/blocs/task_list/task_list_bloc.dart';
import 'package:notesapp/presentation/blocs/theme/theme_cubit.dart';
import 'package:notesapp/presentation/views/task_add_edit_view.dart';
import 'package:notesapp/presentation/widgets/empty_list_widget.dart';
import 'package:notesapp/presentation/widgets/loading_widget.dart';
import 'package:notesapp/presentation/widgets/task_list_item_widget.dart';

class TaskListView extends StatefulWidget {
  static const String routeName = '/';
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
   
    _searchController.addListener(() {
      context.read<TaskListBloc>().add(SearchTasks(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddTask(BuildContext context) async {
    final result = await Navigator.pushNamed(context, TaskAddEditView.routeNameAdd);
    if (result == true && mounted) {
      context.read<TaskListBloc>().add(const FetchTasks()); 
    }
  }

  void _navigateToEditTask(BuildContext context, String taskId) async {
    final result = await Navigator.pushNamed(
      context,
      TaskAddEditView.routeNameEdit,
      arguments: taskId,
    );
    if (result == true && mounted) {
      context.read<TaskListBloc>().add(const FetchTasks()); 
    }
  }

  void _showFilterMenu(BuildContext context) {
   
    final taskListBloc = context.read<TaskListBloc>();
    final currentLoadedState = taskListBloc.state is TaskListLoaded ? taskListBloc.state as TaskListLoaded : null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setSheetState) {
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8.0, runSpacing: 8.0,
                children: <Widget>[
                  Text("Filter by Status", style: Theme.of(context).textTheme.titleMedium),
                  DropdownButton<TaskStatus?>(
                    value: currentLoadedState?.filterStatus,
                    hint: const Text("Any Status"), isExpanded: true,
                    items: [
                      const DropdownMenuItem<TaskStatus?>(value: null, child: Text("Any Status")),
                      ...TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(taskStatusToString(s))))
                    ],
                    onChanged: (value) {
                      taskListBloc.add(FilterTasksByStatus(value));
                      setSheetState((){});
                    },
                  ),
                  Text("Filter by Priority", style: Theme.of(context).textTheme.titleMedium),
                  DropdownButton<Priority?>(
                    value: currentLoadedState?.filterPriority,
                    hint: const Text("Any Priority"), isExpanded: true,
                    items: [
                      const DropdownMenuItem<Priority?>(value: null, child: Text("Any Priority")),
                      ...Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(priorityToString(p))))
                    ],
                    onChanged: (value) {
                       taskListBloc.add(FilterTasksByPriority(value));
                       setSheetState((){});
                    },
                  ),
                  ElevatedButton(
                    child: const Text("Clear Filters"),
                    onPressed: () {
                      taskListBloc.add(ClearTaskFilters());
                      Navigator.pop(ctx);
                    },
                  ),
                  ElevatedButton(
                    child: const Text("Apply"),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sync with Server",
            onPressed: () => context.read<TaskListBloc>().add(SyncTasks()),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filter Tasks",
            onPressed: () => _showFilterMenu(context),
          ),
          BlocBuilder<ThemeCubit, ThemeState>( // For theme icon
            builder: (context, themeState) {
              bool isCurrentlyDark;
              if (themeState.themeMode == ThemeMode.system) {
                  isCurrentlyDark = platformBrightness == Brightness.dark;
              } else {
                  isCurrentlyDark = themeState.themeMode == ThemeMode.dark;
              }
              return IconButton(
                icon: Icon(isCurrentlyDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: "Toggle Theme",
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme(platformBrightness);
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchTasks,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // BLoC event already handled by listener
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        tooltip: AppStrings.addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList() {
    return BlocConsumer<TaskListBloc, TaskListState>(
      listener: (context, state) {
        // Handle side effects like Snackbars for specific states
        if (state is TaskListSyncFailure) {
          SnackBarUtils.showErrorSnackbar(context, "Sync failed: ${state.message}");
        } else if (state is TaskListSyncSuccess) { // Assuming TaskListSyncSuccess would be a distinct state
          SnackBarUtils.showSuccessSnackbar(context, state.message);
        } else if (state is TaskDeletionFailure) {
          SnackBarUtils.showErrorSnackbar(context, "Failed to delete task: ${state.message}");
        } else if (state is TaskDeletionSuccess){ // If you add this state
           SnackBarUtils.showSuccessSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is TaskListLoading && !(state is TaskListLoaded)) { // Show loading only if not already loaded
          return const LoadingWidget(message: "Loading tasks...");
        } else if (state is TaskListError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: () => context.read<TaskListBloc>().add(const FetchTasks(forceRemote: true)), child: const Text("Retry"))
              ],
            )
          );
        } else if (state is TaskListEmpty) {
            return EmptyListWidget(message: state.message, icon: Icons.inbox_outlined);
        } else if (state is TaskListLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TaskListBloc>().add(const FetchTasks(forceRemote: true));
            },
            child: ListView.builder(
              itemCount: state.filteredTasks.length,
              itemBuilder: (context, index) {
                final task = state.filteredTasks[index];
                return TaskListItemWidget(
                  task: task,
                  onTap: () => _navigateToEditTask(context, task.id),
                  onDelete: (taskId) {
                    context.read<TaskListBloc>().add(DeleteTask(taskId));
                  },
                );
              },
            ),
          );
        } else if (state is TaskListSyncing) {
            return const LoadingWidget(message: "Syncing tasks...");
        }
        // Default to initial or an empty container if state is not handled.
        return const LoadingWidget(message: "Initializing...");
      },
    );
  }
}