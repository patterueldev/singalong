part of 'core.dart';

class GenericException {
  const GenericException();

  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final exception = this;
    if (exception is UnknownException) {
      return localizations.unknownError;
    } else if (exception is UnhandledException) {
      return localizations.unhandled(exception.toString());
    } else if (exception is APIException) {
      return LocalizedString((_) => exception.message);
    } else {
      throw Exception("This should be inherited and handled elsewhere.");
    }
  }

  factory GenericException.api(String message) = APIException._;
  factory GenericException.unknown() = UnknownException._;
  factory GenericException.unhandled(Object exception) = UnhandledException._;
}

class APIException extends GenericException {
  final String message;
  const APIException._(this.message) : super();

  @override
  String toString() => message;
}

class UnknownException extends GenericException {
  const UnknownException._() : super();
}

class UnhandledException extends GenericException {
  final Object exception;
  const UnhandledException._(this.exception) : super();

  @override
  String toString() => exception.toString();
}

class CustomException extends GenericException {
  final String message;
  const CustomException(this.message) : super();

  @override
  String toString() => message;
}
