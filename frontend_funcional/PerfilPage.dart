import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

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