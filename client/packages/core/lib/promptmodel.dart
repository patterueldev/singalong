part of 'core.dart';

class PromptModel {
  final LocalizedString title;
  final LocalizedString message;
  final List<PromptAction> actions;

  const PromptModel._({
    required this.title,
    required this.message,
    required this.actions,
  });

  factory PromptModel.standard(
    GenericLocalizations localizations, {
    required LocalizedString title,
    required LocalizedString message,
    required LocalizedString actionText,
    required VoidCallback action,
  }) =>
      PromptModel._(
        title: title,
        message: message,
        actions: [
          PromptAction(title: localizations.cancelButtonText),
          PromptAction(
            title: actionText,
            action: action,
          ),
        ],
      );

  factory PromptModel.custom({
    required LocalizedString title,
    required LocalizedString message,
    required List<PromptAction> actions,
  }) =>
      PromptModel._(
        title: title,
        message: message,
        actions: actions,
      );

  factory PromptModel.quick({
    required String title,
    required String message,
    required String actionText,
  }) =>
      PromptModel._(
        title: LocalizedString((_) => title),
        message: LocalizedString((_) => message),
        actions: [
          PromptAction(
            title: LocalizedString((_) => actionText),
          ),
        ],
      );
}

class PromptAction {
  final LocalizedString title;
  final VoidCallback? action;

  const PromptAction({
    required this.title,
    this.action,
  });
}
