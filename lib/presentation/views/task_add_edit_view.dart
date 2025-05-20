import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notesapp/core/constants/app_strings.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/core/utils/date_formatter.dart';
import 'package:notesapp/core/utils/snackbar_utils.dart';
import 'package:notesapp/presentation/blocs/task_add_edit/task_add_edit_bloc.dart';
import 'package:notesapp/presentation/widgets/app_text_field.dart';
import 'package:notesapp/presentation/widgets/loading_widget.dart';

class TaskAddEditView extends StatefulWidget {
  static const String routeNameAdd = '/add-task';
  static const String routeNameEdit = '/edit-task';

  final bool isEditing;
  final String? taskId;

  const TaskAddEditView({
    super.key,
    required this.isEditing,
    this.taskId,
  });

  @override
  State<TaskAddEditView> createState() => _TaskAddEditViewState();
}

class _TaskAddEditViewState extends State<TaskAddEditView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagInputController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagInputController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(
      BuildContext context, TaskAddEditState currentState) async {
    final bloc = context.read<TaskAddEditBloc>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentState.dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != currentState.dueDate) {
      bloc.add(DueDateChanged(picked));
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      context.read<TaskAddEditBloc>().add(SaveTaskRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<TaskAddEditBloc, TaskAddEditState>(
      listener: (context, state) {
        if (state.status == TaskAddEditStatus.success) {
          SnackBarUtils.showSuccessSnackbar(
            context,
            state.isEditing
                ? AppStrings.taskUpdatedSuccessfully
                : AppStrings.taskAddedSuccessfully,
          );
          Navigator.of(context).pop(true);
        } else if (state.status == TaskAddEditStatus.failure) {
          SnackBarUtils.showErrorSnackbar(
              context, state.errorMessage ?? 'An unknown error occurred.');
        }

        if (state.status == TaskAddEditStatus.loaded ||
            state.status == TaskAddEditStatus.initial && widget.isEditing) {
          if (_titleController.text != state.title) {
            _titleController.text = state.title;
            _titleController.selection = TextSelection.fromPosition(
                TextPosition(offset: _titleController.text.length));
          }
          if (_descriptionController.text != state.description) {
            _descriptionController.text = state.description;
            _descriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _descriptionController.text.length));
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
                state.isEditing ? AppStrings.editTask : AppStrings.addTask),
            actions: [
              if (state.status == TaskAddEditStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _submitForm,
                ),
            ],
          ),
          body: _buildBody(context, state, theme),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, TaskAddEditState state, ThemeData theme) {
    // Initial loading state for editing
    if (widget.isEditing &&
        (state.status == TaskAddEditStatus.initial ||
            (state.status == TaskAddEditStatus.loading &&
                state.title.isEmpty))) {
      return const LoadingWidget(message: "Loading task details...");
    }
    // Error state when loading for editing failed before form is shown
    if (widget.isEditing &&
        state.status == TaskAddEditStatus.failure &&
        state.title.isEmpty) {
      return Center(
          child: Text("Error: ${state.errorMessage ?? 'Failed to load task'}"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _titleController,
              labelText: AppStrings.title,
              validator: (value) => (value == null || value.isEmpty)
                  ? AppStrings.fieldRequired
                  : null,
              onChanged: (value) =>
                  context.read<TaskAddEditBloc>().add(TitleChanged(value)),
            ),
            AppTextField(
              controller: _descriptionController,
              labelText: AppStrings.description,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              onChanged: (value) => context
                  .read<TaskAddEditBloc>()
                  .add(DescriptionChanged(value)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: state.priority,
              decoration: const InputDecoration(
                  labelText: AppStrings.priority, border: OutlineInputBorder()),
              items: Priority.values
                  .map((p) => DropdownMenuItem<Priority>(
                      value: p, child: Text(priorityToString(p))))
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  context.read<TaskAddEditBloc>().add(PriorityChanged(v));
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              value: state.taskStatus,
              decoration: const InputDecoration(
                  labelText: AppStrings.status, border: OutlineInputBorder()),
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem<TaskStatus>(
                      value: s, child: Text(taskStatusToString(s))))
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  context.read<TaskAddEditBloc>().add(StatusChanged(v));
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.dueDate),
              subtitle: Text(state.dueDate == null
                  ? 'Not set'
                  : DateFormatter.formatDate(state.dueDate!)),
              trailing: Icon(Icons.calendar_today, color: theme.primaryColor),
              onTap: () => _pickDueDate(context, state),
              leading: state.dueDate != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () => context
                          .read<TaskAddEditBloc>()
                          .add(const DueDateChanged(null)),
                      tooltip: "Clear Due Date",
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Tags', style: theme.textTheme.titleMedium),
            Wrap(
              spacing: 8.0,
              children: state.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => context
                            .read<TaskAddEditBloc>()
                            .add(TagRemoved(tag)),
                      ))
                  .toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _tagInputController,
                    labelText: 'Add a tag',
                    hintText: 'e.g., work, personal',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_tagInputController.text.isNotEmpty) {
                      context
                          .read<TaskAddEditBloc>()
                          .add(TagAdded(_tagInputController.text.trim()));
                      _tagInputController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.status == TaskAddEditStatus.loading
                  ? null
                  : _submitForm,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16)),
              child: state.status == TaskAddEditStatus.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3))
                  : Text(state.isEditing
                      ? AppStrings.saveTask
                      : AppStrings.addTask),
            ),
          ],
        ),
      ),
    );
  }
}
