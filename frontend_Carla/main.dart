import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Académica',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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

  final List<Widget> _pages = [
    HorariosPage(),
    EventosPage(),
    CronometroPage(),
    AvisosPage(),
    Center(child: Text('Módulo de Repositorio', style: TextStyle(fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestión Académica')),
      body: Column(
        children: [
          SizedBox(height: 10),
          Divider(thickness: 2, color: Colors.grey.shade300), // Separador
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _pages[_currentIndex],
            ),
          ),
        ],
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
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
     ),
    );
  }
}

// Otras páginas
class HorariosPage extends StatefulWidget {
  @override
  _HorariosPageState createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  List<dynamic> horarios = [];

  final List<String> diasSemana = [
    "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
  ];

  @override
  void initState() {
    super.initState();
    fetchHorariosDummy();
  }

  Future<void> fetchHorariosDummy() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      horarios = [
        {"id": 1, "asignatura": "Matemáticas", "hora_inicio": "08:00", "hora_fin": "09:30", "dia_semana": "Lunes"},
        {"id": 2, "asignatura": "Física", "hora_inicio": "10:00", "hora_fin": "11:30", "dia_semana": "Martes"}
      ];
    });
  }

  void _mostrarDialogoAgregarHorario() {
    String asignatura = "";
    String diaSeleccionado = diasSemana.first;
    TimeOfDay horaInicio = TimeOfDay(hour: 8, minute: 0);
    TimeOfDay horaFin = TimeOfDay(hour: 9, minute: 0);

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
      builder: (context) => AlertDialog(
        title: Text("Agregar Nuevo Horario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => asignatura = value,
              decoration: InputDecoration(labelText: "Asignatura"),
            ),
            DropdownButton<String>(
              value: diaSeleccionado,
              onChanged: (String? newValue) {
                setState(() {
                  diaSeleccionado = newValue!;
                });
              },
              items: diasSemana.map((dia) {
                return DropdownMenuItem(
                  value: dia,
                  child: Text(dia),
                );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Inicio: ${horaInicio.format(context)}"),
                ElevatedButton(
                  onPressed: () => seleccionarHora(context, true),
                  child: Text("Seleccionar"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Fin: ${horaFin.format(context)}"),
                ElevatedButton(
                  onPressed: () => seleccionarHora(context, false),
                  child: Text("Seleccionar"),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                horarios.add({
                  "id": horarios.length + 1,
                  "asignatura": asignatura,
                  "hora_inicio": horaInicio.format(context),
                  "hora_fin": horaFin.format(context),
                  "dia_semana": diaSeleccionado
                });
              });
              Navigator.pop(context);
            },
            child: Text("Agregar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _mostrarDialogoAgregarHorario,
          child: Text("Añadir Horario"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: horarios.length,
            itemBuilder: (context, index) {
              var horario = horarios[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('${horario['asignatura']} - ${horario['dia_semana']}'),
                  subtitle: Text('${horario['hora_inicio']} - ${horario['hora_fin']}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EventosPage extends StatefulWidget {
  @override
  _EventosPageState createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  List<Map<String, String>> eventos = [];

  void _mostrarDialogoAgregarEvento() {
    String titulo = "";
    DateTime fechaSeleccionada = DateTime.now();
    TimeOfDay horaSeleccionada = TimeOfDay.now();

    Future<void> seleccionarFecha() async {
      final DateTime? seleccionada = await showDatePicker(
        context: context,
        initialDate: fechaSeleccionada,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );

      if (seleccionada != null) {
        setState(() {
          fechaSeleccionada = seleccionada;
        });
      }
    }

    Future<void> seleccionarHora() async {
      final TimeOfDay? seleccionada = await showTimePicker(
        context: context,
        initialTime: horaSeleccionada,
      );

      if (seleccionada != null) {
        setState(() {
          horaSeleccionada = seleccionada;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Agregar Evento"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => titulo = value,
              decoration: InputDecoration(labelText: "Título del Evento"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Fecha: ${fechaSeleccionada.toLocal()}".split(' ')[0]),
                ElevatedButton(
                  onPressed: seleccionarFecha,
                  child: Text("Seleccionar"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Hora: ${horaSeleccionada.format(context)}"),
                ElevatedButton(
                  onPressed: seleccionarHora,
                  child: Text("Seleccionar"),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                eventos.add({
                  "titulo": titulo,
                  "fecha": fechaSeleccionada.toLocal().toString().split(' ')[0],
                  "hora": horaSeleccionada.format(context),
                });
              });
              Navigator.pop(context);
            },
            child: Text("Agregar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _mostrarDialogoAgregarEvento,
          child: Text("Añadir Evento"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              var evento = eventos[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.event),
                  title: Text(evento['titulo']!),
                  subtitle: Text("${evento['fecha']} - ${evento['hora']}"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CronometroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.timer),
        label: Text('Iniciar Cronómetro'),
        onPressed: () {},
      ),
    );
  }
}

class AvisosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.notifications),
        label: Text('Publicar Aviso'),
        onPressed: () {},
      ),
    );
  }
}