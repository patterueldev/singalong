library shared;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Either;

part 'genericlocalizations.dart';
part 'localizedstring.dart';
part 'promptmodel.dart';
part 'genericexception.dart';
part 'assetsource.dart';
part 'service_usecase.dart';

class Pagination {}

class OffsetPagination extends Pagination {
  final int offset;

  OffsetPagination(this.offset);
}

class CursorPagination extends Pagination {
  final String cursor;

  CursorPagination(this.cursor);
}

class PagePagination extends Pagination {
  final int page;

  PagePagination(this.page);
}
