import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

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