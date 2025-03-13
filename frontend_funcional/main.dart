import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';
import "PerfilPage.dart";
import "RepositorioPage.dart";
import "AvisosPage.dart";
import "CronometroPage.dart";
import "EventosPage.dart";
import "HorariosPage.dart";
import "ApiService.dart";

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
                  onPressed: () async {
                    if (nombreUsuario.isNotEmpty && contrasena.isNotEmpty) {
                      bool loggedIn = await ApiService.instance.login(nombreUsuario, contrasena);
                      if (loggedIn) {
                        setState(() => _usuario = nombreUsuario);
                        Navigator.pop(context);
                        _mostrarDialogoEstadoAnimo();
                      } else {
                        // Show an alert if credentials are wrong
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Error"),
                              content: Text("Usuario o contraseña incorrectos"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK"),
                                ),
                              ],
                            );
                          },
                        );
                      }
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