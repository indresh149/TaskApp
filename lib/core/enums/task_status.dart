enum TaskStatus { todo, inProgress, done }

String taskStatusToString(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'To Do';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.done:
      return 'Done';
  }
}

TaskStatus stringToTaskStatus(String statusStr) {
  switch (statusStr.toLowerCase()) {
    case 'to do':
    case 'todo':
      return TaskStatus.todo;
    case 'in progress':
    case 'inprogress':
      return TaskStatus.inProgress;
    case 'done':
      return TaskStatus.done;
    default:
      return TaskStatus.todo;
  }
}
