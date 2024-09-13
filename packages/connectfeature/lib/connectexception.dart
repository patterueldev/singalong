part of 'connectfeature.dart';

class ConnectException extends GenericException {
  final ExceptionType type;
  const ConnectException._(this.type) : super();

  @override
  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final connectLocalizations = localizations as ConnectLocalizations;
    switch (type) {
      case ExceptionType.emptyName:
        return connectLocalizations.emptyName;
      case ExceptionType.emptySessionId:
        return connectLocalizations.emptySessionId;
      case ExceptionType.invalidName:
        final exception = this as InvalidNameException;
        return connectLocalizations.invalidName(exception.name);
      case ExceptionType.invalidSessionId:
        final exception = this as InvalidSessionIDException;
        return connectLocalizations.invalidSessionId(exception.sessionId);
      default:
        return super.localizedFrom(localizations);
    }
  }

  factory ConnectException.emptyName() =>
      const ConnectException._(ExceptionType.emptyName);
  factory ConnectException.emptySessionId() =>
      const ConnectException._(ExceptionType.emptySessionId);
  factory ConnectException.invalidName(String name) = InvalidNameException._;
  factory ConnectException.invalidSessionId(String sessionId) =
      InvalidSessionIDException._;
}

enum ExceptionType {
  emptyName,
  emptySessionId,
  invalidName,
  invalidSessionId,
}

class InvalidNameException extends ConnectException {
  final String name;
  const InvalidNameException._(this.name) : super._(ExceptionType.invalidName);
}

class InvalidSessionIDException extends ConnectException {
  final String sessionId;
  const InvalidSessionIDException._(this.sessionId)
      : super._(ExceptionType.invalidSessionId);
}
