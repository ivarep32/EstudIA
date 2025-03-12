import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// URL de tu backend Flask (si deseas probar las llamadas HTTP; de lo contrario, usa datos dummy)
const String backendUrl = "http://127.0.0.1:5000";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Académica (Sin Firebase)',
      theme: ThemeData(primarySwatch: Colors.blue),
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

  // Lista de páginas (dummy) para cada funcionalidad.
  final List<Widget> _pages = [
    HorariosPage(),
    EventosPage(),
    CronometroPage(),
    AvisosPage(),
    Center(child: Text('Módulo de Repositorio'))
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión Académica'),
      ),
      body: _pages[_currentIndex],
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
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// Ejemplo de la página de Horarios usando datos dummy
class HorariosPage extends StatefulWidget {
  @override
  _HorariosPageState createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  List<dynamic> horarios = [];
  bool isLoading = false;

  // Datos dummy para simular horarios
  final List<Map<String, dynamic>> dummyHorarios = [
    {"id": 1, "asignatura": "Matemáticas", "hora_inicio": "08:00", "hora_fin": "09:30", "dia_semana": "Lunes"},
    {"id": 2, "asignatura": "Física", "hora_inicio": "10:00", "hora_fin": "11:30", "dia_semana": "Martes"}
  ];

  @override
  void initState() {
    super.initState();
    // Puedes simular una carga inicial usando datos dummy
    fetchHorariosDummy();
  }

  Future<void> fetchHorariosDummy() async {
    setState(() {
      isLoading = true;
    });
    // Simulamos una espera para "cargar" datos (por ejemplo, 1 segundo)
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      horarios = dummyHorarios;
      isLoading = false;
    });
  }

  // Ejemplo simple para agregar un horario dummy
  void addHorarioDummy() {
    setState(() {
      int newId = horarios.length + 1;
      horarios.add({
        "id": newId,
        "asignatura": "Nueva Asignatura $newId",
        "hora_inicio": "12:00",
        "hora_fin": "13:00",
        "dia_semana": "Miércoles"
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          isLoading
              ? CircularProgressIndicator()
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    var horario = horarios[index];
                    return ListTile(
                      title: Text('${horario['asignatura']} - ${horario['dia_semana']}'),
                      subtitle: Text('${horario['hora_inicio']} a ${horario['hora_fin']}'),
                    );
                  },
                ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: addHorarioDummy,
            child: Text('Agregar Horario Dummy'),
          ),
        ],
      ),
    );
  }
}

class MoodPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () => _showMoodDialog(context));
    return HomePage(); // Se reemplaza AuthWrapper() por HomePage()
  }

  void _showMoodDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('¿Cómo te sientes hoy?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return ListTile(
                title: Text('Nivel de energía: ${index + 1}'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Aquí se puede agregar la lógica para ajustar la carga de trabajo
                },
              );
            }),
          ),
        );
      },
    );
  }
}


// Nuevos módulos de avisos, eventos y cronometro


class EventosPage extends StatefulWidget {
  @override
  _EventosPageState createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  List<Map<String, dynamic>> eventos = [];
  Map<String, dynamic> nuevoEvento = {
    'tipo': 'entrega',
    'fecha': '',
    'descripcion': '',
    'recordatorio': false,
  };

  @override
  void initState() {
    super.initState();
    fetchEventos();
  }

  Future<void> fetchEventos() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/eventos'),
        headers: {'Authorization': 'Bearer TOKEN_AQUI'},
      );

      if (response.statusCode == 200) {
        setState(() {
          eventos = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Error al obtener eventos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener eventos: $e');
    }
  }

  Future<void> addEvento() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/eventos'),
        headers: {
          'Authorization': 'Bearer TOKEN_AQUI',
          'Content-Type': 'application/json',
        },
        body: json.encode(nuevoEvento),
      );

      if (response.statusCode == 201) {
        setState(() {
          eventos.add(json.decode(response.body));
          nuevoEvento = {'tipo': 'entrega', 'fecha': '', 'descripcion': '', 'recordatorio': false};
        });
      } else {
        print('Error al crear evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al crear evento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Eventos Académicos')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: eventos.length,
              itemBuilder: (context, index) {
                final evento = eventos[index];
                return ListTile(
                  title: Text('${evento['tipo']} - ${evento['descripcion']}'),
                  subtitle: Text(DateTime.parse(evento['fecha']).toLocal().toString()),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: nuevoEvento['tipo'],
                  items: ['entrega', 'examen'].map((String tipo) {
                    return DropdownMenuItem(value: tipo, child: Text(tipo));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      nuevoEvento['tipo'] = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Tipo'),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Fecha (YYYY-MM-DD HH:MM)'),
                  onChanged: (value) => setState(() => nuevoEvento['fecha'] = value),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Descripción'),
                  onChanged: (value) => setState(() => nuevoEvento['descripcion'] = value),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: nuevoEvento['recordatorio'],
                      onChanged: (value) {
                        setState(() {
                          nuevoEvento['recordatorio'] = value!;
                        });
                      },
                    ),
                    Text('Recordatorio'),
                  ],
                ),
                ElevatedButton(
                  onPressed: addEvento,
                  child: Text('Agregar Evento'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class CronometroPage extends StatefulWidget {
  @override
  _CronometroPageState createState() => _CronometroPageState();
}

class _CronometroPageState extends State<CronometroPage> {
  bool running = false;
  int time = 0; // Tiempo en segundos
  String tareaId = '';
  String? registroId;
  Timer? timer;

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        time += 1;
      });
    });
  }

  void stopTimer() {
    if (timer != null) {
      timer!.cancel();
    }
  }

  Future<void> iniciarCronometro() async {
    if (tareaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Por favor, ingresa un ID de tarea"),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/cronometro/start'),
        headers: {
          'Authorization': 'Bearer TOKEN_AQUI',
          'Content-Type': 'application/json',
        },
        body: json.encode({'tarea_id': tareaId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          registroId = json.decode(response.body)['id'];
          running = true;
          time = 0;
        });
        startTimer();
      } else {
        print('Error al iniciar cronómetro: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al iniciar cronómetro: $e');
    }
  }

  Future<void> detenerCronometro() async {
    if (registroId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/cronometro/stop'),
        headers: {
          'Authorization': 'Bearer TOKEN_AQUI',
          'Content-Type': 'application/json',
        },
        body: json.encode({'registro_id': registroId}),
      );

      if (response.statusCode == 200) {
        stopTimer();
        final duracion = json.decode(response.body)['duracion'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tiempo registrado: $duracion segundos'),
        ));
        setState(() {
          running = false;
          registroId = null;
          time = 0;
        });
      } else {
        print('Error al detener cronómetro: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al detener cronómetro: $e');
    }
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Cronómetro de Trabajo')),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'ID de la tarea'),
            onChanged: (value) {
              setState(() {
                tareaId = value;
              });
            },
          ),
          SizedBox(height: 20),
          Text('Tiempo: $time segundos', style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          running
              ? ElevatedButton(
                  onPressed: detenerCronometro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Detener'),
                )
              : ElevatedButton(
                  onPressed: iniciarCronometro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Iniciar'),
                ),
        ],
      ),
    ),
  );
}


class AvisosPage extends StatefulWidget {
  @override
  _AvisosPageState createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  List<Map<String, dynamic>> avisos = [];
  TextEditingController mensajeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAvisos();
  }

  Future<void> fetchAvisos() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/avisos'), // Cambia por la URL de tu backend
        headers: {'Authorization': 'Bearer TOKEN_AQUI'},
      );

      if (response.statusCode == 200) {
        setState(() {
          avisos = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('Error al obtener avisos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener avisos: $e');
    }
  }

  Future<void> publicarAviso() async {
    if (mensajeController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/avisos'),
        headers: {
          'Authorization': 'Bearer TOKEN_AQUI',
          'Content-Type': 'application/json',
        },
        body: json.encode({'mensaje': mensajeController.text}),
      );

      if (response.statusCode == 201) {
        setState(() {
          avisos.insert(0, json.decode(response.body));
          mensajeController.clear();
        });
      } else {
        print('Error al publicar aviso: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al publicar aviso: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Avisos (Solo Delegados)')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: mensajeController,
              decoration: InputDecoration(
                labelText: 'Escribe un aviso',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: publicarAviso,
              child: Text('Publicar Aviso'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: avisos.length,
                itemBuilder: (context, index) {
                  final aviso = avisos[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(aviso['mensaje']),
                      subtitle: Text(
                        DateTime.parse(aviso['fecha_publicacion']).toLocal().toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}