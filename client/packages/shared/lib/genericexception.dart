part of 'shared.dart';

class GenericException {
  const GenericException();

  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final exception = this;
    if (exception is UnknownException) {
      return localizations.unknownError;
    } else if (exception is UnhandledException) {
      return localizations.unhandled(exception.toString());
    } else {
      throw Exception("This should be inherited and handled elsewhere.");
    }
  }

  factory GenericException.unknown() = UnknownException._;
  factory GenericException.unhandled(Object exception) = UnhandledException._;
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
