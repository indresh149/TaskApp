
import 'package:flutter/material.dart';
import 'package:notesapp/core/constants/app_strings.dart';

class EmptyListWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyListWidget({
    super.key,
    this.message = AppStrings.noTasksFound,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 80, color: Theme.of(context).hintColor),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}