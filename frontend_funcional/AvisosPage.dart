import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

// Módulo de Avisos mejorado
class AvisosPage extends StatefulWidget {
  @override
  _AvisosPageState createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> avisos = [];
  bool _mostrarNotificacion = false;
  String _mensajeNotificacion = '';
  
  // Lista de grupos donde el usuario es miembro o administrador
  List<Map<String, dynamic>> _grupos = [
    {"nombre": "Matemáticas Avanzadas", "esAdmin": true},
    {"nombre": "Física Cuántica", "esAdmin": false},
    {"nombre": "Historia Universal", "esAdmin": true},
    {"nombre": "Desarrollo de Software", "esAdmin": false},
  ];
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    // Avisos de ejemplo
    avisos = [
      {
        "titulo": "Cambio de horario - Matemáticas",
        "contenido": "La clase de Matemáticas del viernes se cambia a las 10:00",
        "fecha": "2025-03-12",
        "tipo": "personal"
      },
      {
        "titulo": "Recordatorio entrega de proyecto",
        "contenido": "No olviden entregar la primera parte del proyecto este domingo",
        "fecha": "2025-03-11",
        "tipo": "grupo",
        "grupo": "Desarrollo de Software"
      }
    ];
  }

  void _mostrarDialogoAgregarAviso() {
    final formKey = GlobalKey<FormState>();
    String titulo = "";
    String contenido = "";
    String tipoAviso = "personal";
    String grupoSeleccionado = _grupos.firstWhere((g) => g["esAdmin"], orElse: () => {"nombre": ""})["nombre"];

    List<Map<String, dynamic>> gruposAdmin = _grupos.where((g) => g["esAdmin"]).toList();
    bool mostrarOpcionGrupo = gruposAdmin.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Crear Nuevo Aviso"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      onChanged: (value) => titulo = value,
                      decoration: InputDecoration(
                        labelText: "Título del Aviso",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un título';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      onChanged: (value) => contenido = value,
                      decoration: InputDecoration(
                        labelText: "Contenido",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese el contenido del aviso';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Mostrar opción de grupo solo si el usuario es administrador en algún grupo
                    if (mostrarOpcionGrupo)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: tipoAviso,
                            items: [
                              DropdownMenuItem(value: "personal", child: Text("Aviso Personal")),
                              DropdownMenuItem(value: "grupo", child: Text("Aviso de Grupo"))
                            ],
                            onChanged: (value) => setStateDialog(() => tipoAviso = value!),
                            decoration: InputDecoration(labelText: "Tipo de aviso", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: 16),
                          if (tipoAviso == "grupo")
                            DropdownButtonFormField<String>(
                              value: grupoSeleccionado,
                              items: gruposAdmin.map((g) => DropdownMenuItem(value: g["nombre"].toString(), child: Text(g["nombre"].toString()))).toList(),
                              onChanged: (value) => setStateDialog(() => grupoSeleccionado = value!),
                              decoration: InputDecoration(labelText: "Selecciona el grupo", border: OutlineInputBorder()),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final fechaActual = DateTime.now();
                    final fechaStr = "${fechaActual.year}-${fechaActual.month.toString().padLeft(2, '0')}-${fechaActual.day.toString().padLeft(2, '0')}";
                    
                    setState(() {
                      avisos.add({
                        "titulo": titulo,
                        "contenido": contenido,
                        "fecha": fechaStr,
                        "tipo": tipoAviso,
                        if (tipoAviso == "grupo") "grupo": grupoSeleccionado
                      });
                      
                      _mostrarNotificacion = true;
                      _mensajeNotificacion = 'Aviso creado correctamente';
                      
                      // Ordenar avisos por fecha (más recientes primero)
                      avisos.sort((a, b) => b['fecha'].toString().compareTo(a['fecha'].toString()));
                    });
                    
                    Navigator.pop(context);
                    
                    // Ocultar notificación después de 3 segundos
                    Future.delayed(Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() {
                          _mostrarNotificacion = false;
                        });
                      }
                    });
                  }
                },
                child: Text("Publicar Aviso"),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _eliminarAviso(int index) {
    final avisoEliminado = avisos[index];
    
    setState(() {
      avisos.removeAt(index);
      _mostrarNotificacion = true;
      _mensajeNotificacion = 'Aviso "${avisoEliminado['titulo']}" eliminado';
      
      // Ocultar notificación después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _mostrarNotificacion = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text("Avisos")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Publicar Aviso"),
                  onPressed: _mostrarDialogoAgregarAviso,
                ),
                SizedBox(height: 20),
                
                Expanded(
                  child: avisos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No hay avisos disponibles",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                    itemCount: avisos.length,
                    itemBuilder: (context, index) {
                      final aviso = avisos[index];
                      final esGrupo = aviso["tipo"] == "grupo";
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            aviso['titulo'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text(aviso['contenido']),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    "Publicado: ${aviso['fecha']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Spacer(),
                                  if (esGrupo)
                                    Chip(
                                      label: Text(
                                        "Grupo: ${aviso['grupo']}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: Colors.blue,
                                      padding: EdgeInsets.all(4),
                                    )
                                  else
                                    Chip(
                                      label: Text(
                                        "Personal",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.all(4),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarAviso(index),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Notificación flotante
          if (_mostrarNotificacion)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        _mensajeNotificacion,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}