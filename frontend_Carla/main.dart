import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión Académica',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _usuario = "Usuario";
  String _estadoAnimo = "Normal";
  List<Map<String, dynamic>> _grupos = [
    {"nombre": "Matemáticas Avanzadas", "admin": true, "miembros": ["Ana", "Carlos", "Lucía"]},
    {"nombre": "Física General", "admin": false, "miembros": ["Pedro", "María", "Javier"]},
    {"nombre": "Club de Programación", "admin": false, "miembros": ["Elena", "David"]},
    {"nombre": "Historia del Arte", "admin": true, "miembros": ["Sofía", "Martín"]},
  ];

  final List<Widget> _pages = [
    HorariosPage(),
    EventosPage(),
    CronometroPage(),
    AvisosPage(),
    RepositorioPage(),
  ];

  
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _mostrarDialogoLogin());
  }
  void _mostrarDialogoLogin() {
    String nombreUsuario = "";
    String contrasena = "";
    bool ocultarContrasena = true;

    showDialog(
      context: context,
      barrierDismissible: false, // No cerrar con tap fuera
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(

              title: Text("Iniciar Sesión"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: "Nombre de Usuario"),
                    onChanged: (value) => nombreUsuario = value,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarContrasena ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            ocultarContrasena = !ocultarContrasena;
                          });
                        },
                      ),
                    ),
                    obscureText: ocultarContrasena,
                    onChanged: (value) => contrasena = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (nombreUsuario.isNotEmpty && contrasena.isNotEmpty) {
                      setState(() {
                        _usuario = nombreUsuario;
                      });
                      Navigator.pop(context);
                      _mostrarDialogoEstadoAnimo();
                    }
                  },
                  child: Text("Ingresar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoEstadoAnimo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Hola, $_usuario!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("¿Cómo te sientes hoy?"),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      [
                        Icons.battery_0_bar_outlined, // Muy cansado
                        Icons.battery_2_bar, // Cansado
                        Icons.battery_4_bar, // Normal
                        Icons.battery_6_bar, // Energético
                        Icons.battery_full, // Súper cargado
                      ][index],
                      color: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.lightGreen,
                        Colors.green,
                      ][index],
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }


 void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilPage(
          usuario: _usuario,
          estadoAnimo: _estadoAnimo,
          grupos: _grupos,
          actualizarGrupos: (nuevosGrupos) {
            setState(() {
              _grupos = nuevosGrupos;
            });
          },
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EstudIA"),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: _abrirPerfil,
            tooltip: "Perfil",
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Horarios'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Cronómetro'),
          BottomNavigationBarItem(icon: Icon(Icons.announcement), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Repositorio'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class PerfilPage extends StatefulWidget {
  final String usuario;
  final String estadoAnimo;
  final List<Map<String, dynamic>> grupos;
  final Function(List<Map<String, dynamic>>) actualizarGrupos;

  PerfilPage({required this.usuario, required this.estadoAnimo, required this.grupos, required this.actualizarGrupos});


  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  void _agregarMiembro(int index) {
    String nuevoMiembro = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Añadir Miembro"),
          content: TextField(
            decoration: InputDecoration(labelText: "Nombre del nuevo miembro"),
            onChanged: (value) => nuevoMiembro = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nuevoMiembro.isNotEmpty) {
                  setState(() {
                    widget.grupos[index]["miembros"].add(nuevoMiembro);
                  });
                  widget.actualizarGrupos(widget.grupos);
                  Navigator.pop(context);
                }
              },
              child: Text("Agregar"),
            ),
          ],
        );
      },
    );
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Perfil de ${widget.usuario}")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text("Estado de ánimo: ${widget.estadoAnimo}", style: TextStyle(fontSize: 18)),
          Divider(height: 30, thickness: 2),
          Text("Grupos de estudio:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...widget.grupos.map((grupo) {
            return ListTile(
              title: Text(grupo["nombre"]),
              subtitle: Text("Miembros: ${grupo["miembros"].join(", ")}"),
              trailing: grupo["admin"]
                  ? IconButton(
                      icon: Icon(Icons.person_add, color: Colors.blue),
                      onPressed: () => _agregarMiembro(widget.grupos.indexOf(grupo)),
                    )
                  : null,
            );
          }).toList(),
        ],
      ),
    );
  }
}



// Clase para el gráfico circular
class PieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double radius;

  PieChart({required this.data, this.radius = 100.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: PieChartPainter(data: data),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double total = 0;
    for (var item in data) {
      total += item['value'] as double;
    }

    double startAngle = -math.pi / 2; // Comienza desde arriba

    for (var item in data) {
      final sweepAngle = 2 * math.pi * (item['value'] as double) / total;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = item['color'] as Color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

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

    Future<void> seleccionarHora(BuildContext context, bool esInicio) async {
      final TimeOfDay? seleccionada = await showTimePicker(
        context: context,
        initialTime: esInicio ? horaInicio : horaFin,
      );

      if (seleccionada != null) {
        setState(() {
          if (esInicio) {
            horaInicio = seleccionada;
          } else {
            horaFin = seleccionada;
          }
        });
      }
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
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

                    // Mostrar opción de grupo solo si el usuario es administrador en algún grupo
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
      ),
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

// Módulo de Eventos mejorado con funcionalidad de grupo/personal
class EventosPage extends StatefulWidget {
  @override
  _EventosPageState createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> eventos = [];
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
    String titulo = "";
    String descripcion = "";
    DateTime fechaSeleccionada = DateTime.now();
    TimeOfDay horaSeleccionada = TimeOfDay.now();
    String tipoEvento = "personal";
    String grupoSeleccionado = _grupos.firstWhere((g) => g["esAdmin"], orElse: () => {"nombre": ""})["nombre"];
    
    List<Map<String, dynamic>> gruposAdmin = _grupos.where((g) => g["esAdmin"]).toList();
    bool mostrarOpcionGrupo = gruposAdmin.isNotEmpty;
    
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
        _mostrarDialogoAgregarEvento();
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
        _mostrarDialogoAgregarEvento();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Agregar Evento"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
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
                    
                    // Añadir evento y mostrar notificación
                    final nuevoEvento = {
                      "titulo": titulo,
                      "fecha": formatearFecha(fechaSeleccionada),
                      "hora": horaStr,
                      "descripcion": descripcion,
                      "tipo": tipoEvento,
                      if (tipoEvento == "grupo") "grupo": grupoSeleccionado
                    };
                    
                    setState(() {
                      eventos.add(nuevoEvento);
                      _mostrarNotificacion = true;
                      _mensajeNotificacion = 'Evento "${titulo}" añadido correctamente';
                      
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
                child: Text("Agregar"),
              ),
            ],
          );
        }
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
// Módulo de Cronómetro
class CronometroPage extends StatefulWidget {
  @override
  _CronometroPageState createState() => _CronometroPageState();
}

class _CronometroPageState extends State<CronometroPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  bool _isRunning = false;
  String _tiempoActual = "00:00:00";
  Duration _elapsed = Duration.zero;
  List<String> _vueltas = [];
  String _nombreSesion = "Sesión de estudio";
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(days: 1), // Duración larga para cronómetro continuo
    );
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _elapsed = _controller.duration! * _controller.value;
          _actualizarTiempo();
        });
      }
    });
  }

  void _actualizarTiempo() {
    int horas = _elapsed.inHours;
    int minutos = _elapsed.inMinutes.remainder(60);
    int segundos = _elapsed.inSeconds.remainder(60);
    
    _tiempoActual = 
      '${horas.toString().padLeft(2, '0')}:'
      '${minutos.toString().padLeft(2, '0')}:'
      '${segundos.toString().padLeft(2, '0')}';
  }

  void _iniciarDetener() {
    setState(() {
      if (_isRunning) {
        _controller.stop();
      } else {
        final previousDuration = _elapsed;
        _controller.reset();
        _controller.duration = Duration(days: 1) - previousDuration;
        _controller.forward();
      }
      _isRunning = !_isRunning;
    });
  }

  void _reiniciar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reiniciar cronómetro"),
          content: Text("¿Estás seguro de que quieres reiniciar el cronómetro y perder el tiempo actual?"),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Reiniciar"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _controller.stop();
                  _isRunning = false;
                  _elapsed = Duration.zero;
                  _actualizarTiempo();
                  _vueltas.clear();
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _registrarVuelta() {
    setState(() {
      _vueltas.add('Vuelta ${_vueltas.length + 1}: $_tiempoActual');
    });
  }

  void _mostrarDialogoNombreSesion() {
    String nuevoNombre = _nombreSesion;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Nombre de la sesión"),
        content: TextField(
          onChanged: (value) => nuevoNombre = value,
          decoration: InputDecoration(
            hintText: "Ingrese un nombre para la sesión",
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: _nombreSesion),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _nombreSesion = nuevoNombre;
              });
              Navigator.pop(context);
            },
            child: Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _nombreSesion,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: _mostrarDialogoNombreSesion,
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _tiempoActual,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _isRunning ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? "Detener" : "Iniciar"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: _isRunning ? Colors.orange : Colors.green,
                ),
                onPressed: _iniciarDetener,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.flag),
                label: Text("Vuelta"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                onPressed: _isRunning ? _registrarVuelta : null,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("Reiniciar"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.red,
                ),
                onPressed: _elapsed.inSeconds > 0 ? _reiniciar : null,
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Lista de vueltas
          Expanded(
            child: _vueltas.isEmpty
              ? Center(
                  child: Text(
                    "No hay vueltas registradas",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _vueltas.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${_vueltas.length - index}'),
                        ),
                        title: Text(_vueltas[_vueltas.length - 1 - index]),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

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


class RepositorioPage extends StatefulWidget {
  @override
  _RepositorioPageState createState() => _RepositorioPageState();
}

class _RepositorioPageState extends State<RepositorioPage> {
  String _carpetaActual = "Raíz";
  List<String> _ruta = ["Raíz"];
  List<Map<String, dynamic>> _archivos = [
    {"nombre": "Documentos", "tipo": "carpeta", "ruta": "Raíz"},
    {"nombre": "Tareas", "tipo": "carpeta", "ruta": "Raíz"},
    {"nombre": "Apuntes.pdf", "tipo": "archivo", "ruta": "Raíz", "tamano": "1.5 MB"},
    {"nombre": "Ejercicios.docx", "tipo": "archivo", "ruta": "Raíz", "tamano": "2.3 MB"},
  ];

  void _abrirCarpeta(String nombre) {
    setState(() {
      _carpetaActual = "$_carpetaActual/$nombre";
      _ruta.add(nombre);
    });
  }

  void _regresar() {
    if (_ruta.length > 1) {
      setState(() {
        _ruta.removeLast();
        _carpetaActual = _ruta.join("/");
      });
    }
  }

  void _agregarCarpeta() {
    String nuevaCarpeta = "Nueva Carpeta ${_archivos.length + 1}";
    setState(() {
      _archivos.add({"nombre": nuevaCarpeta, "tipo": "carpeta", "ruta": _carpetaActual});
    });
  }

  void _agregarArchivo() {
    String nuevoArchivo = "Archivo ${_archivos.length + 1}.txt";
    setState(() {
      _archivos.add({"nombre": nuevoArchivo, "tipo": "archivo", "ruta": _carpetaActual, "tamano": "500 KB"});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> archivosFiltrados =
        _archivos.where((archivo) => archivo["ruta"] == _carpetaActual).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Repositorio"),
        leading: _ruta.length > 1
            ? IconButton(icon: Icon(Icons.arrow_back), onPressed: _regresar)
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "Ubicación: ${_ruta.join(" > ")}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: archivosFiltrados.isEmpty
                ? Center(child: Text("Esta carpeta está vacía"))
                : ListView.builder(
                    itemCount: archivosFiltrados.length,
                    itemBuilder: (context, index) {
                      var archivo = archivosFiltrados[index];
                      return ListTile(
                        leading: Icon(archivo["tipo"] == "carpeta" ? Icons.folder : Icons.insert_drive_file),
                        title: Text(archivo["nombre"]),
                        subtitle: archivo["tipo"] == "archivo" ? Text("Tamaño: ${archivo["tamano"]}") : null,
                        onTap: archivo["tipo"] == "carpeta" ? () => _abrirCarpeta(archivo["nombre"]) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "carpeta",
            onPressed: _agregarCarpeta,
            child: Icon(Icons.create_new_folder),
            tooltip: "Nueva Carpeta",
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "archivo",
            onPressed: _agregarArchivo,
            child: Icon(Icons.upload_file),
            tooltip: "Subir Archivo",
          ),
        ],
      ),
    );
  }
}