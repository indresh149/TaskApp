
import 'package:flutter/material.dart';
import 'package:notesapp/core/constants/app_strings.dart';
import 'package:notesapp/core/enums/priority.dart';
import 'package:notesapp/core/enums/task_status.dart';
import 'package:notesapp/core/utils/date_formatter.dart';
import 'package:notesapp/domain/entities/task_entity.dart';
import 'package:notesapp/presentation/widgets/confirm_dialog.dart';

class TaskListItemWidget extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final ValueChanged<String> onDelete;

  const TaskListItemWidget({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  Color _getPriorityColor(Priority priority, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case Priority.high:
        return Colors.red.shade700;
      case Priority.medium:
        return Colors.orange.shade700;
      case Priority.low:
        return isDark ? Colors.green.shade400 : Colors.green.shade600;
     
      
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.data_usage; 
      case TaskStatus.done:
        return Icons.check_circle_outline;
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete(task.id);
      },
      background: Container(
        color: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showConfirmDialog(
          context,
          title: AppStrings.deleteTask,
          content: AppStrings.deleteTaskConfirmation,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ListTile(
          onTap: onTap,
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(task.status),
                color: task.status == TaskStatus.done ? Colors.green : Theme.of(context).colorScheme.secondary,
              ),
              if (!task.isSynced) 
                Icon(Icons.sync_problem, color: Colors.orange, size: 16),
            ],
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${DateFormatter.formatDateTime(task.createdDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (task.dueDate != null)
                Text(
                  'Due: ${DateFormatter.formatDateTime(task.dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: task.dueDate!.isBefore(DateTime.now()) && task.status != TaskStatus.done
                        ? Colors.red
                        : null,
                  ),
                ),
            ],
          ),
          trailing: Container(
            width: 10,
            height: double.infinity,
            color: _getPriorityColor(task.priority, context),
          ),
          isThreeLine: true, 
        ),
      ),
    );
  }
}