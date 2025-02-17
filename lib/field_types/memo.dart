import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_dashboard/dashboard.dart';

class FieldTypeMemo extends FieldType {
  int maxLines;
  double? listWidth;
  FieldTypeMemo({this.maxLines = 4, this.listWidth});

  Widget _getListContent(
      BuildContext context, DocumentSnapshot _object, ColumnModule column) {
    return Text(_object.getFieldAdm(column.field, '-').toString());
  }

  @override
  getListContent(BuildContext context, DocumentSnapshot _object,
          ColumnModule column) =>
      listWidth != null
          ? Container(
              width: this.listWidth,
              child: _getListContent(context, _object, column))
          : _getListContent(context, _object, column);

  @override
  getEditContent(BuildContext context,ColumnModule column) {
    var value = getFieldValue(column);
    return TextFormField(
        enabled: column.editable,
        initialValue: value,
        maxLines: this.maxLines,
        decoration: InputDecoration(
            labelText: column.label,
            filled: !column.editable,
            fillColor: column.editable
                ? Theme.of(context).canvasColor.withAlpha(1)
                : Theme.of(context).disabledColor),
        onSaved: (val) {
          updateData(context, column, val);
        });
  }
}
