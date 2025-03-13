import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

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