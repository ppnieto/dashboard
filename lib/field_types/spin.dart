import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_dashboard/dashboard.dart';
import 'package:flutter_spinbox/material.dart';

class FieldTypeSpin extends FieldType {
  final double maxValue;
  final double minValue;
  final double step;
  final double? defaultValue;
  final int? decimals;
  FieldTypeSpin({this.maxValue = 100, this.minValue = 0, this.step = 1, this.defaultValue, this.decimals});

  @override
  getListContent(BuildContext context, DocumentSnapshot _object, ColumnModule column) {
    if (decimals != null) {
      double num = getField(_object, column.field, 0).toDouble();

      return Text(num.toStringAsFixed(decimals!));
    } else {
      return super.getListContent(context, _object, column);
    }
  }

  @override
  getEditContent(BuildContext context,  ColumnModule column) {
//    var value = _object?.getFieldAdm(column.field, defaultValue) ?? values[column.field];
var value = getFieldValue(column) ?? defaultValue;

    if (getObject()?.hasFieldAdm(column.field) == false && value != null) {
      updateData(context, column, value);
    }

    if (value is String) {
      value = int.parse(value);
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      SizedBox(
        width: 200,
        child: SpinBox(
          min: this.minValue,
          max: this.maxValue,
          step: this.step,
          enabled: column.editable,
          value: value ?? 0,
          onChanged: (value) {
            updateData(context, column, value);
          },
        ),
      ),
      if (!column.mandatory && column.editable)
        IconButton(
          icon: Icon(Icons.clear, color: Theme.of(context).primaryColor),
          onPressed: () {
            updateData(context, column, null);
          },
        ),
      Spacer()
    ]);
  }
}
