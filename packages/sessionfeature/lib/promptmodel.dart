part of 'sessionfeature.dart';

class PromptModel {
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const PromptModel({
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });
}
