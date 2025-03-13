import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

// Módulo de Eventos mejorado con funcionalidad de grupo/personal
class EventosPage extends StatefulWidget {
  @override
  _EventosPageState createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> eventos = [];
  bool _mostrarNotificacion = false;
  String _mensajeNotificacion = '';
  String titulo = "";
  String descripcion = "";
  
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
    // Eventos de ejemplo
    eventos = [
      {
        "titulo": "Examen de Cálculo",
        "fecha": "2025-03-15",
        "hora": "10:00",
        "descripcion": "Traer calculadora y formulario",
        "tipo": "personal"
      },
      {
        "titulo": "Entrega de Proyecto",
        "fecha": "2025-03-20",
        "hora": "23:59",
        "descripcion": "Enviar por correo electrónico",
        "tipo": "grupo",
        "grupo": "Desarrollo de Software"
      }
    ];
  }

void _mostrarDialogoAgregarEvento() {
  final formKey = GlobalKey<FormState>();
  DateTime fechaSeleccionada = DateTime.now();
  TimeOfDay horaSeleccionada = TimeOfDay.now();
  String tipoEvento = "personal";
  String grupoSeleccionado = _grupos.firstWhere((g) => g["esAdmin"], orElse: () => {"nombre": ""})["nombre"];

  List<Map<String, dynamic>> gruposAdmin = _grupos.where((g) => g["esAdmin"]).toList();
  bool mostrarOpcionGrupo = gruposAdmin.isNotEmpty;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        Future<void> seleccionarFecha(BuildContext context) async {
          final DateTime? seleccionada = await showDatePicker(
            context: context,
            initialDate: fechaSeleccionada,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );

          if (seleccionada != null) {
            setStateDialog(() => fechaSeleccionada = seleccionada);
          }
        }

        Future<void> seleccionarHora(BuildContext context) async {
          final TimeOfDay? seleccionada = await showTimePicker(
            context: context,
            initialTime: horaSeleccionada,
          );

          if (seleccionada != null) {
            setStateDialog(() => horaSeleccionada = seleccionada);
          }
        }

        return AlertDialog(
          title: Text("Agregar Evento"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: titulo,
                    onChanged: (value) => setStateDialog(() => titulo = value),
                    decoration: InputDecoration(
                      labelText: "Título del Evento",
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
                    initialValue: descripcion,
                    onChanged: (value) => setStateDialog(() => descripcion = value),
                    decoration: InputDecoration(
                      labelText: "Descripción (opcional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text("Fecha:"),
                    subtitle: Text("${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}"),
                    trailing: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => seleccionarFecha(context),
                    ),
                  ),
                  ListTile(
                    title: Text("Hora:"),
                    subtitle: Text(horaSeleccionada.format(context)),
                    trailing: IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () => seleccionarHora(context),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (mostrarOpcionGrupo)
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: tipoEvento,
                          items: [
                            DropdownMenuItem(value: "personal", child: Text("Evento Personal")),
                            DropdownMenuItem(value: "grupo", child: Text("Evento de Grupo"))
                          ],
                          onChanged: (value) => setStateDialog(() => tipoEvento = value!),
                          decoration: InputDecoration(labelText: "Tipo de evento", border: OutlineInputBorder()),
                        ),
                        if (tipoEvento == "grupo")
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final horaStr = '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}';

                  Navigator.pop(context);

                  setState(() {
                    eventos.add({
                      "titulo": titulo,
                      "fecha": "${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}",
                      "hora": horaStr,
                      "descripcion": descripcion,
                      "tipo": tipoEvento,
                      if (tipoEvento == "grupo") "grupo": grupoSeleccionado
                    });
                    _mostrarNotificacion = true;
                    _mensajeNotificacion = 'Evento "${titulo}" añadido correctamente';

                    Future.delayed(Duration(seconds: 3), () {
                      if (mounted) setState(() => _mostrarNotificacion = false);
                    });
                  });
                }
              },
              child: Text("Agregar"),
            ),
          ],
        );
      },
    ),
  );
}


  void _eliminarEvento(int index) {
    final eventoEliminado = eventos[index];
    
    setState(() {
      eventos.removeAt(index);
      _mostrarNotificacion = true;
      _mensajeNotificacion = 'Evento "${eventoEliminado['titulo']}" eliminado';
      
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

  void _mostrarDialogoEditarEvento(int index) {
    final formKey = GlobalKey<FormState>();
    final evento = eventos[index];
    String titulo = evento['titulo'];
    String descripcion = evento['descripcion'] ?? '';
    DateTime fechaSeleccionada = DateTime.parse(evento['fecha']);
    String tipoEvento = evento['tipo'] ?? 'personal';
    String grupoSeleccionado = evento['grupo'] ?? _grupos.firstWhere((g) => g["esAdmin"], orElse: () => {"nombre": ""})["nombre"];
    
    List<Map<String, dynamic>> gruposAdmin = _grupos.where((g) => g["esAdmin"]).toList();
    bool mostrarOpcionGrupo = gruposAdmin.isNotEmpty;
    
    // Parsear hora
    final horaPartes = (evento['hora'] as String).split(':');
    TimeOfDay horaSeleccionada = TimeOfDay(
      hour: int.parse(horaPartes[0]), 
      minute: int.parse(horaPartes[1])
    );
    
    // Formateador de fecha para mostrar
    String formatearFecha(DateTime fecha) {
      return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    }

    Future<void> seleccionarFecha(BuildContext context) async {
      final DateTime? seleccionada = await showDatePicker(
        context: context,
        initialDate: fechaSeleccionada,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );

      if (seleccionada != null) {
        fechaSeleccionada = seleccionada;
        // Forzar reconstrucción del diálogo
        Navigator.pop(context);
        _mostrarDialogoEditarEvento(index);
      }
    }

    Future<void> seleccionarHora(BuildContext context) async {
      final TimeOfDay? seleccionada = await showTimePicker(
        context: context,
        initialTime: horaSeleccionada,
      );

      if (seleccionada != null) {
        horaSeleccionada = seleccionada;
        // Forzar reconstrucción del diálogo
        Navigator.pop(context);
        _mostrarDialogoEditarEvento(index);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Editar Evento"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: titulo,
                      onChanged: (value) => titulo = value,
                      decoration: InputDecoration(
                        labelText: "Título del Evento",
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
                      initialValue: descripcion,
                      onChanged: (value) => descripcion = value,
                      decoration: InputDecoration(
                        labelText: "Descripción (opcional)",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text("Fecha:"),
                      subtitle: Text(formatearFecha(fechaSeleccionada)),
                      trailing: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => seleccionarFecha(context),
                      ),
                    ),
                    ListTile(
                      title: Text("Hora:"),
                      subtitle: Text(horaSeleccionada.format(context)),
                      trailing: IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () => seleccionarHora(context),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    // Mostrar opción de grupo solo si el usuario es administrador en algún grupo
                    if (mostrarOpcionGrupo)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: tipoEvento,
                            items: [
                              DropdownMenuItem(value: "personal", child: Text("Evento Personal")),
                              DropdownMenuItem(value: "grupo", child: Text("Evento de Grupo"))
                            ],
                            onChanged: (value) => setStateDialog(() => tipoEvento = value!),
                            decoration: InputDecoration(labelText: "Tipo de evento", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: 16),
                          if (tipoEvento == "grupo")
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
                    // Formatear hora
                    final horaStr = '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}';
                    
                    // Cerrar el diálogo primero
                    Navigator.pop(context);
                    
                    setState(() {
                      eventos[index] = {
                        "titulo": titulo,
                        "fecha": formatearFecha(fechaSeleccionada),
                        "hora": horaStr,
                        "descripcion": descripcion,
                        "tipo": tipoEvento,
                        if (tipoEvento == "grupo") "grupo": grupoSeleccionado
                      };
                      _mostrarNotificacion = true;
                      _mensajeNotificacion = 'Evento "${titulo}" actualizado correctamente';
                      
                      // Ordenar eventos por fecha
                      eventos.sort((a, b) => a['fecha'].toString().compareTo(b['fecha'].toString()));
                      
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
                },
                child: Text("Guardar Cambios"),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("Añadir Evento"),
                    onPressed: _mostrarDialogoAgregarEvento,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  Text(
                    "Eventos Próximos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              Expanded(
                child: eventos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No hay eventos programados",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    var evento = eventos[index];
                    final esGrupo = evento["tipo"] == "grupo";
                    
                    // Calcular días restantes
                    final fechaEvento = DateTime.parse(evento['fecha']);
                    final hoy = DateTime.now();
                    final diferencia = fechaEvento.difference(hoy).inDays;
                    
                    // Decidir color según proximidad
                    Color colorIndicador;
                    if (diferencia < 0) {
                      colorIndicador = Colors.grey; // Ya pasó
                    } else if (diferencia <= 3) {
                      colorIndicador = Colors.red; // Próximo (3 días o menos)
                    } else if (diferencia <= 7) {
                      colorIndicador = Colors.orange; // Cercano (7 días o menos)
                    } else {
                      colorIndicador = Colors.green; // Futuro (más de 7 días)
                    }
                    
                    String textoIndicador;
                    if (diferencia < 0) {
                      textoIndicador = "Evento pasado";
                    } else if (diferencia == 0) {
                      textoIndicador = "¡Hoy!";
                    } else if (diferencia == 1) {
                      textoIndicador = "¡Mañana!";
                    } else {
                      textoIndicador = "En $diferencia días";
                    }
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorIndicador,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _mostrarDialogoEditarEvento(index),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorIndicador.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      esGrupo ? Icons.group : Icons.person,
                                      color: colorIndicador,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          evento['titulo'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "${evento['fecha']} a las ${evento['hora']}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorIndicador.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      textoIndicador,
                                      style: TextStyle(
                                        color: colorIndicador,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (evento['descripcion'] != null && evento['descripcion'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0, left: 8.0),
                                  child: Text(
                                    evento['descripcion'],
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              if (esGrupo)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.group, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        "Grupo: ${evento['grupo']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _mostrarDialogoEditarEvento(index),
                                    tooltip: "Editar evento",
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarEvento(index),
                                    tooltip: "Eliminar evento",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Notificación
          if (_mostrarNotificacion)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _mostrarNotificacion ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mensajeNotificacion,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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