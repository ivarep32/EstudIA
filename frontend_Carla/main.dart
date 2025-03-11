import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Asegúrate de inicializar Firebase y configurar google-services.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const String backendUrl = "http://127.0.0.1:5000"; // Cambia por la IP de tu backend

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Académica',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(),
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

// Widget para manejar el estado de autenticación
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return snapshot.data == null ? LoginPage() : HomePage();
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// Página de Login
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo electrónico')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('Ingresar')),
          ],
        ),
      ),
    );
  }
}

// Página principal con navegación inferior
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HorariosPage(),
    // Puedes agregar aquí: EventosPage(), CronometroPage(), AvisosPage(), RepositorioPage()
    Center(child: Text('Módulo de Eventos')),
    Center(child: Text('Módulo de Cronómetro')),
    Center(child: Text('Módulo de Avisos')),
    Center(child: Text('Módulo de Repositorio')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Académica'),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              })
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
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

// Servicio API para llamar a nuestro backend Flask
class ApiService {
  static const String baseUrl = MyApp.backendUrl;

  static Future<List<dynamic>> getHorarios() async {
    final response = await http.get(Uri.parse('$baseUrl/horarios'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener horarios');
    }
  }

  // Aquí puedes agregar otros métodos para eventos, cronómetro, avisos, archivos...
}

// Página de Horarios
class HorariosPage extends StatefulWidget {
  @override
  _HorariosPageState createState() => _HorariosPageState();
}
class _HorariosPageState extends State<HorariosPage> {
  List<dynamic> horarios = [];
  bool isLoading = false;
  final _asignaturaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  String? _diaSemana;

  @override
  void initState() {
    super.initState();
    fetchHorarios();
  }

  Future<void> fetchHorarios() async {
    setState(() => isLoading = true);
    try {
      var data = await ApiService.getHorarios();
      setState(() {
        horarios = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar horarios: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Función para agregar un horario (aquí deberías implementar el POST al endpoint)
  Future<void> addHorario() async {
    // En este boceto solo recargamos la lista
    fetchHorarios();
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(controller: _asignaturaController, decoration: InputDecoration(labelText: 'Asignatura')),
                TextField(controller: _horaInicioController, decoration: InputDecoration(labelText: 'Hora de inicio'), keyboardType: TextInputType.datetime),
                TextField(controller: _horaFinController, decoration: InputDecoration(labelText: 'Hora de fin'), keyboardType: TextInputType.datetime),
                DropdownButton<String>(
                  value: _diaSemana,
                  hint: Text('Selecciona un día'),
                  items: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
                      .map((dia) => DropdownMenuItem(child: Text(dia), value: dia))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _diaSemana = value;
                    });
                  },
                ),
                ElevatedButton(onPressed: addHorario, child: Text('Agregar Horario')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
