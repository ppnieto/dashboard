import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dashboard/dashboard.dart';
import 'package:flutter/material.dart';

class FieldTypeWidget extends FieldType {
  @override
  bool async() => this.getAsyncValueFunction != null;

  final Widget? Function(
      BuildContext context, DocumentSnapshot? object, bool inList) builder;

  final Function(DocumentSnapshot<Object?> object, ColumnModule column)?
      getAsyncValueFunction;

  FieldTypeWidget({required this.builder, this.getAsyncValueFunction});

  @override
  getEditContent(BuildContext context,  ColumnModule column) {
    return builder(context, getObject(), false);
  }

  @override
  getListContent(
      BuildContext context, DocumentSnapshot _object, ColumnModule column) {
    return builder(context, _object, true);
  }


}
