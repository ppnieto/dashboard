import 'package:firebase_dashboard/admin_modules.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dashboard/controllers/dashboard.dart';
import 'package:firebase_dashboard/controllers/detalle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FieldTypeText extends FieldType {
  final RegExp? regexp;
  final bool nullable;
  final Function? showTextFunction;
  final bool obscureText;
  final bool emptyNull;
  final Widget? nullWidget;
  final int ellipsisLength;
  final bool tooltip;
  final int maxLines;
  final String? regExpMessage;
  final bool introSendForm;
  final bool autoFocus;

  final TextEditingController controller = TextEditingController();

  FieldTypeText(
      {this.nullable = true,
      this.regexp,
      this.showTextFunction,
      this.obscureText = false,
      this.emptyNull = false,
      this.tooltip = false,
      this.introSendForm = false,
      this.maxLines = 2,
      this.regExpMessage = "Formato incorrecto",
      this.autoFocus = false,
      this.ellipsisLength = 0,
      this.nullWidget});

  @override
  getListContent(BuildContext context, DocumentSnapshot _object, ColumnModule column) {
    if (hasField(_object, column.field)) {
      String texto = showTextFunction == null ? getField(_object, column.field, "").toString() : showTextFunction!(_object[column.field]);
      if (this.ellipsisLength > 0 && texto.length >= this.ellipsisLength) {
        return Text(texto);
      } else {
        if (tooltip) {
          return Tooltip(
              message: texto,
              child: Text(
                texto,
                maxLines: this.maxLines,
                overflow: TextOverflow.ellipsis,
              ));
        } else {
          return Text(texto);
        }
      }
    }
    return nullWidget == null ? Text("-") : nullWidget;
  }

  @override
  getEditContent(BuildContext context, DocumentSnapshot? _object, Map<String, dynamic> values, ColumnModule column) {
    var value = getFieldFromMap(values, column.field, null);
    value = showTextFunction == null ? value : showTextFunction!(value);

    controller.text = value ?? "";
    print('${column.field} => ${controller.text}');
    return Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            updateData(context, column, controller.text);
          }
        },
        child: TextFormField(
            controller: controller,
            //enabled: column.editable,
            readOnly: !column.editable,
            obscureText: this.obscureText,
            enableSuggestions: this.obscureText,
            autofocus: this.autoFocus,
            autocorrect: this.obscureText,
            decoration: InputDecoration(
                labelText: column.label,
                filled: !column.editable,
                fillColor: column.editable ? Theme.of(context).canvasColor.withAlpha(1) : Theme.of(context).disabledColor),
            validator: (value) {
              if (regexp != null) {
                if (!regexp!.hasMatch(value ?? "")) {
                  return regExpMessage;
                }
              }

              if (column.mandatory && (value == null || value.isEmpty)) return "Campo obligatorio";
              return null;
            },
            /*
            onFieldSubmitted: introSendForm
                ? (value) async {
                    Get.log('on field submitted');
                    DetalleController detalleController = Get.find<DetalleController>(tag: DashboardController.tag);
                    detalleController.doGuardar();
                  }
                : null,
                */
            onSaved: (val) {
              print("text onsaved $val");
              if (emptyNull) {
                val = (val ?? "").isEmpty ? null : val;
              }
              updateData(context, column, val);
            }));
  }
}
