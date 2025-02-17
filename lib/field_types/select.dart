import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class FieldTypeSelect extends FieldType {
  final String? initialValue;
  final Map<dynamic, String> options;
  final Widget? unselected;
  final Function? validate;
  final String? frozenValue;
  final bool editInList;

  FieldTypeSelect({required this.options, this.unselected, this.initialValue, this.validate, this.frozenValue, this.editInList = false});

  @override
  bool showLabel() => true;

  @override
  String getValue(DocumentSnapshot _object, ColumnModule column) {
    if (_object.hasFieldAdm(column.field)) {
      var key = _object.get(column.field);
      bool contains = options.containsKey(key);
      if (key is Map) {
        for (var k in options.keys) {
          if (k is Map) {
            if (mapEquals(key, k)) {
              return options[k] ?? "";
            }
          }
        }
      }
      if (this.options.containsKey(key)) {
        return this.options[key] ?? "";
      } else {
        if (this.unselected != null) {
          return "<unselected>";
        }
      }
    }
    return "<sin asignar>";
  }

  @override
  getListContent(BuildContext context, DocumentSnapshot _object, ColumnModule column) {
    if (editInList) {
      String content = getValue(_object, column);

      return Container(
          width: 300,
          child: PopupMenuButton<String>(
              tooltip: content,
              child: Text(
                content,
                //style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              itemBuilder: (context) {
                return <PopupMenuItem<String>>[PopupMenuItem<String>(value: "", child: Text("<sin asignar>", style: TextStyle(color: Colors.red)))] +
                    options.entries.map((e) {
                      return PopupMenuItem<String>(value: e.key, child: Text(e.value));
                    }).toList();
              },
              onSelected: column.editable == false
                  ? null
                  : (String ref) {
                      _object.reference.set({column.field: ref}, SetOptions(merge: true)).then((value) => print("updated!!!"));
                    })

          /*
          child: DropdownButtonFormField(
            value: value == null ? initialValue : value,
            isExpanded: true,
            items: options.entries.map((e) {
              return DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
                enabled: !(frozenValue != null && frozenValue == e.key),
              );
            }).toList(),
            onChanged: (frozenValue != null && value == frozenValue) || column.editable == false
                ? null
                : (val) {
                    updateData(context, column, val);
                  },
            onSaved: (val) {
              updateData(context, column, val);
            },
            validator: (val) {
              if (column.mandatory && val == null) return "Campo obligatorio";
              if (validate != null) return validate!(initialValue, val);
              return null;
            },
          )*/
          );
    } else {
      if (_object.hasFieldAdm(column.field)) {
        var key = _object.get(column.field);
        if (this.options.containsKey(key)) {
          return Text(this.options[key] ?? "");
        } else {
          if (this.unselected != null) {
            return this.unselected;
          }
        }
      }

      return Text("<sin asignar>", style: TextStyle(color: Colors.red));
    }
  }

  @override
  getEditContent(BuildContext context,  ColumnModule column) {
    var value = getFieldValue(column);
    
    /*if (_object?.hasFieldAdm(column.field) ?? false) {
      value = _object?.get(column.field);
    } else {
      value = values[column.field].toString();
    }
    */

    return Container(
        width: 300,
        child: DropdownButtonFormField(
          value: value ?? initialValue,
          isExpanded: true,
          decoration: InputDecoration(
            filled: !column.editable,
            fillColor: column.editable ? Theme.of(context).canvasColor.withAlpha(1) : Theme.of(context).disabledColor,
          ),
          items: options.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value, style: TextStyle(color: column.editable ? null : Theme.of(context).primaryColor)),
              enabled: !(frozenValue != null && frozenValue == e.key),
            );
          }).toList(),
          onChanged: (frozenValue != null && value == frozenValue) || column.editable == false
              ? null
              : (val) {
                  updateData(context, column, val);
                },
          onSaved: (val) {
            updateData(context, column, val);
          },
          validator: (val) {
            if (column.mandatory && val == null) return "Campo obligatorio";
            if (validate != null) return validate!(initialValue, val);
            return null;
          },
        ));
  }
}
