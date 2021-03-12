import 'package:dashboard/admin/model/admin_modules.dart';
import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:sweetsheet/sweetsheet.dart';

class AdminScreen extends StatefulWidget {
  Module module;
  bool showScaffoldBack;
  CollectionReference collection;

  AdminScreen({this.module, this.showScaffoldBack = false, this.collection});

  @override
  State<StatefulWidget> createState() => AdminScreenState();
}

enum TipoPantalla { listado, detalle, nuevo, confirmar }

class AdminScreenState extends State<AdminScreen> {
  TipoPantalla tipo = TipoPantalla.listado;
  DocumentSnapshot detalle;
  Map<String, dynamic> updateData;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> filtro = {};

  CollectionReference getCollection() {
    String collection = widget.collection == null ? widget.module.collection : widget.collection.path;
    return FirebaseFirestore.instance.collection(collection);
  }

  Query addFilters(Map<String, dynamic> filtro, Query query) {
    Query result = query;
    if (filtro != null) {
      for (MapEntry filterEntry in filtro.entries) {
        if (filterEntry.value != null && filterEntry.value.toString().isNotEmpty) {
          print("   add filter " + filterEntry.key + " = " + filterEntry.value.toString());
          result = result.where(filterEntry.key, isEqualTo: filterEntry.value);
        }
      }
    }
    return result;
  }

  getList() {
    Query query = getCollection();
    query = addFilters(filtro, query);
    query = addFilters(widget.module.getFilter(), query);

    if (widget.module.orderBy != null) {
      query = query.orderBy(widget.module.orderBy);
    }

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return Container();
        return ListView(children: [
          PaginatedDataTable(
              rowsPerPage: widget.module.rowsPerPage,
              columns: widget.module.columns.where((element) => element.listable).map((column) {
                    return DataColumn(label: Text(column.label));
                  }).toList() +
                  (widget.module.canRemove ? [DataColumn(label: Container())] : []),
              source: MyDataTableSource(snapshot, widget.module, context, (index) {
                setState(() {
                  detalle = snapshot.data.docs[index];
                  updateData = detalle.data();
                  tipo = TipoPantalla.detalle;
                });
              }))
        ]);
      },
    );
  }

  getEditField(ColumnModule column) {
    return Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < responsiveDashboardWidth ? 5 : 20),
        child: column.getEditContent(updateData[column.field], null, (value) {
          setState(() {
            updateData[column.field] = value;
          });
        }));
  }

  doGuardar() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      if (widget.module.onSave != null) {
        widget.module.onSave(tipo == TipoPantalla.nuevo, this.updateData);
      }

      if (tipo == TipoPantalla.detalle) {
        detalle.reference.update(this.updateData).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Elemento guardado con éxito'),
            duration: Duration(seconds: 2),
          ));
          setState(() {
            this.tipo = TipoPantalla.listado;
          });
        });
      }
      if (tipo == TipoPantalla.nuevo) {
        getCollection().add(this.updateData).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Elemento guardado con éxito'),
            duration: Duration(seconds: 2),
          ));
          setState(() {
            this.tipo = TipoPantalla.listado;
          });
        });
      }
    }
  }

  getDetail() => SingleChildScrollView(
        child: Card(
          elevation: 2,
          margin: MediaQuery.of(context).size.width >= responsiveDashboardWidth ? EdgeInsets.fromLTRB(64, 32, 64, 64) : EdgeInsets.all(5),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < responsiveDashboardWidth ? 32.0 : 5),
            child: Container(
                //padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Builder(
                    builder: (context) => Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: widget.module.columns.map<Widget>((column) {
                              if (column.showOnEdit) {
                                return getEditField(column);
                              } else {
                                return Container();
                              }
                            }).toList())))),
          ),
        ),
      );

  getNuevo() => SingleChildScrollView(
        child: Card(
          elevation: 2,
          margin: EdgeInsets.fromLTRB(64, 32, 64, 64),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Builder(
                    builder: (context) => Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: widget.module.columns.map<Widget>((column) {
                                  if (column.showOnNew) {
                                    return getEditField(column);
                                  } else {
                                    return Container();
                                  }
                                }).toList() +
                                [])))),
          ),
        ),
      );

  getTitle() {
    return Text(widget.module.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }

  getConfirmar() =>
      Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Text("¿Está seguro que desea realizar la operación?"), TextButton(onPressed: () {}, child: Text("SI"))])));

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (tipo == TipoPantalla.listado) {
      content = getList();
    } else if (tipo == TipoPantalla.detalle) {
      content = getDetail();
    } else if (tipo == TipoPantalla.nuevo) {
      content = getNuevo();
    } else if (tipo == TipoPantalla.confirmar) {
      content = getConfirmar();
    }

    getLeading() {
      if (widget.showScaffoldBack) return null;
      if (tipo != TipoPantalla.listado) {
        return IconButton(
            icon: Icon(FontAwesome.arrow_left),
            onPressed: () {
              setState(() {
                tipo = TipoPantalla.listado;
              });
            });
      } else {
        return Container();
      }
    }

    getActions() {
      if (tipo == TipoPantalla.listado && widget.module.canAdd) {
        return [
          IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                detalle = null;
                updateData = {};
                tipo = TipoPantalla.nuevo;
              });
            },
          )
        ];
      }
      if (tipo == TipoPantalla.detalle || tipo == TipoPantalla.nuevo) {
        return [
          IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(FontAwesome.save),
            onPressed: () {
              doGuardar();
            },
          ),
          tipo == TipoPantalla.detalle && widget.module.canRemove
              ? IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(FontAwesome.remove),
                  onPressed: () async {
                    doBorrar(context, detalle.reference, () {
                      setState(() {
                        tipo = TipoPantalla.listado;
                      });
                    });
                  },
                )
              : Container()
        ];
      }
      return <Widget>[];
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.module.title),
          leading: getLeading(),
          actions: <Widget>[] +
              widget.module.columns.map<Widget>((ColumnModule columnModule) {
                if (columnModule.filter) {
                  if (filtro.containsKey(columnModule.field) == false) {
                    filtro[columnModule.field] = "";
                  }
                  return Row(children: [
                    columnModule.getFilterContent(filtro[columnModule.field], (val) {
                      print("val = ");
                      print(val);
                      setState(() {
                        filtro[columnModule.field] = val;
                      });
                    })
                  ]);
                } else
                  return Container();
              }).toList() +
              getActions(),
        ),
        body: content);
    /*

    return Padding(
        padding: EdgeInsets.all(20), child: Card(child: Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [getTitle(), content]))));*/
  }
}

doBorrar(BuildContext context, DocumentReference ref, Function postDelete) {
  final SweetSheet _sweetSheet = SweetSheet();
  _sweetSheet.show(
    context: context,
    title: Text("¿Está seguro de borrar el elemento?"),
    description: Text("Esta acción no podrá deshacerse después"),
    color: SweetSheetColor.DANGER,
    icon: Icons.delete,
    positive: SweetSheetAction(
      onPressed: () {
        ref.delete();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('El elemento ha sido borrado'),
          duration: Duration(seconds: 2),
        ));
        postDelete();
      },
      title: 'Borrar',
    ),
    negative: SweetSheetAction(
      onPressed: () {
        Navigator.of(context).pop();
        return false;
      },
      title: 'Cancelar',
    ),
  );
}

class MyDataTableSource extends DataTableSource {
  AsyncSnapshot<QuerySnapshot> data;
  BuildContext context;
  Module module;
  Function onTap;
  int indexSelected = 3;
  MyDataTableSource(this.data, this.module, this.context, this.onTap);
  @override
  DataRow getRow(int index) {
    QueryDocumentSnapshot _object = data.data.docs[index];

    return DataRow.byIndex(
        index: index,
        cells: module.columns.where((element) => element.listable).map<DataCell>((column) {
              return DataCell(column.getListContent(_object),
                  onTap: column.clickToDetail && module.canEdit
                      ? () {
                          this.onTap(index);
                        }
                      : null);
            }).toList() +
            (module.canRemove
                ? [
                    DataCell(RaisedButton.icon(
                      color: Colors.blue,
                      icon: Icon(FontAwesome.remove, color: Colors.white),
                      label: Text("Borrar", style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        doBorrar(context, _object.reference, () {
                          if (module.onRemove != null) {
                            module.onRemove(_object);
                          }
                        });
                      },
                    ))
                  ]
                : []));
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.data.docs.length;

  @override
  int get selectedRowCount => 0;
}
