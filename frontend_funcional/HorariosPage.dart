import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

// Módulo de Horarios mejorado
class HorariosPage extends StatefulWidget {
  @override
  _HorariosPageState createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> with AutomaticKeepAliveClientMixin {
  List<dynamic> horarios = [];
  String _diaActual = '';
  List<Map<String, dynamic>> _datosGrafico = [];
  final List<Color> _colores = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pinkAccent,
  ];
  bool _mostrarNotificacion = false;
  String _mensajeNotificacion = '';

  final List<String> diasSemana = [
    "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
  ];

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
    fetchHorariosDummy();
    _actualizarDiaActual();
  }

  void _actualizarDiaActual() {
    final hoy = DateTime.now().weekday;
    _diaActual = diasSemana[hoy - 1]; // weekday va de 1 (lunes) a 7 (domingo)
    _actualizarGrafico();
  }

  void _actualizarGrafico() {
    _datosGrafico = [];
    
    // Filtrar horarios del día actual
    final horariosHoy = horarios.where((h) => h['dia_semana'] == _diaActual).toList();
    
    for (int i = 0; i < horariosHoy.length; i++) {
      final horario = horariosHoy[i];
      
      // Calcular duración en minutos
      final inicio = _parseHora(horario['hora_inicio']);
      final fin = _parseHora(horario['hora_fin']);
      final duracion = _calcularDuracionMinutos(inicio, fin);
      
      _datosGrafico.add({
        'name': horario['asignatura'],
        'value': duracion.toDouble(),
        'color': _colores[i % _colores.length]
      });
    }
    
    // Si no hay horarios para hoy, agregamos un valor por defecto
    if (_datosGrafico.isEmpty) {
      _datosGrafico.add({
        'name': 'Sin clases',
        'value': 100.0,
        'color': Colors.grey
      });
    }
  }

  TimeOfDay _parseHora(String hora) {
    final parts = hora.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1])
    );
  }

  int _calcularDuracionMinutos(TimeOfDay inicio, TimeOfDay fin) {
    return (fin.hour * 60 + fin.minute) - (inicio.hour * 60 + inicio.minute);
  }

  Future<void> fetchHorariosDummy() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      horarios = [
        {"id": 1, "asignatura": "Matemáticas", "hora_inicio": "08:00", "hora_fin": "09:30", "dia_semana": "Lunes"},
        {"id": 2, "asignatura": "Física", "hora_inicio": "10:00", "hora_fin": "11:30", "dia_semana": "Martes"}
      ];
      _actualizarGrafico();
    });
  }

void _mostrarDialogoAgregarHorario() {
  final formKey = GlobalKey<FormState>();
  String asignatura = "";
  String diaSeleccionado = diasSemana.first;
  TimeOfDay horaInicio = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay horaFin = TimeOfDay(hour: 9, minute: 0);
  String tipoHorario = "personal";
  String grupoSeleccionado = _grupos.firstWhere((g) => g["esAdmin"], orElse: () => {"nombre": ""})["nombre"];

  List<Map<String, dynamic>> gruposAdmin = _grupos.where((g) => g["esAdmin"]).toList();
  bool mostrarOpcionGrupo = gruposAdmin.isNotEmpty;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> seleccionarHora(BuildContext context, bool esInicio) async {
            final TimeOfDay? seleccionada = await showTimePicker(
              context: context,
              initialTime: esInicio ? horaInicio : horaFin,
            );

            if (seleccionada != null) {
              setStateDialog(() {
                if (esInicio) {
                  horaInicio = seleccionada;
                } else {
                  horaFin = seleccionada;
                }
              });
            }
          }

          return AlertDialog(
            title: Text("Agregar Nuevo Horario"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      onChanged: (value) => asignatura = value,
                      decoration: InputDecoration(labelText: "Asignatura", border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese una asignatura' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: diaSeleccionado,
                      items: diasSemana.map((dia) => DropdownMenuItem(value: dia, child: Text(dia))).toList(),
                      onChanged: (value) => setStateDialog(() => diaSeleccionado = value!),
                      decoration: InputDecoration(labelText: "Día de la semana", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text("Hora de inicio: ${horaInicio.format(context)}"),
                      trailing: Icon(Icons.access_time),
                      onTap: () => seleccionarHora(context, true),
                    ),
                    ListTile(
                      title: Text("Hora de fin: ${horaFin.format(context)}"),
                      trailing: Icon(Icons.access_time),
                      onTap: () => seleccionarHora(context, false),
                    ),
                    SizedBox(height: 16),

                    if (mostrarOpcionGrupo)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: tipoHorario,
                            items: [
                              DropdownMenuItem(value: "personal", child: Text("Horario Personal")),
                              DropdownMenuItem(value: "grupo", child: Text("Horario de Grupo"))
                            ],
                            onChanged: (value) => setStateDialog(() => tipoHorario = value!),
                            decoration: InputDecoration(labelText: "Tipo de horario", border: OutlineInputBorder()),
                          ),
                          if (tipoHorario == "grupo")
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
                    final inicioMinutos = horaInicio.hour * 60 + horaInicio.minute;
                    final finMinutos = horaFin.hour * 60 + horaFin.minute;

                    if (finMinutos <= inicioMinutos) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La hora de fin debe ser posterior a la de inicio')));
                      return;
                    }

                    setState(() {
                      horarios.add({
                        "id": horarios.length + 1,
                        "asignatura": asignatura,
                        "hora_inicio": "${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}",
                        "hora_fin": "${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}",
                        "dia_semana": diaSeleccionado,
                        "tipo": tipoHorario,
                        if (tipoHorario == "grupo") "grupo": grupoSeleccionado
                      });
                      _mostrarNotificacion = true;
                      _mensajeNotificacion = 'Horario añadido correctamente';
                    });

                    Navigator.pop(context);
                    Future.delayed(Duration(seconds: 3), () => setState(() => _mostrarNotificacion = false));
                  }
                },
                child: Text("Agregar"),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text("Horarios")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text("Añadir Horario"),
            onPressed: _mostrarDialogoAgregarHorario,
          ),
          SizedBox(height: 20),
          for (var horario in horarios)
            ListTile(
              title: Text("${horario['asignatura']} (${horario['dia_semana']})"),
              subtitle: Text("${horario['hora_inicio']} - ${horario['hora_fin']}"),
              trailing: horario["tipo"] == "grupo"
                  ? Chip(label: Text("Grupo: ${horario['grupo']}", style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue)
                  : Chip(label: Text("Personal"), backgroundColor: Colors.green),
            ),
        ],
      ),
    );
  }
}