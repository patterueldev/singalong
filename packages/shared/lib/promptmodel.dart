part of 'shared.dart';

class PromptModel {
  final LocalizedString title;
  final LocalizedString message;
  final LocalizedString actionText;
  final VoidCallback onAction;

  const PromptModel({
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });
}
