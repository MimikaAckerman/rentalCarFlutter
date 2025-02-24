import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScreenCocheEstacionado extends StatefulWidget {
  @override
  _ScreenCocheEstacionadoState createState() => _ScreenCocheEstacionadoState();
}

class _ScreenCocheEstacionadoState extends State<ScreenCocheEstacionado> {
  List<dynamic> _coches = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    fetchCochesEstacionados();
  }

  Future<void> fetchCochesEstacionados() async {
    final url = Uri.parse(
        "https://api-psc-goland.azurewebsites.net/getVehiculoEstacionado"); // Cambia a la URL de tu API en producción

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _coches = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coches Estacionados'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(height: 10),
                      Text('Error al cargar los datos',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchCochesEstacionados,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _coches.isEmpty
                  ? Center(child: Text('No hay registros de estacionamiento'))
                  : ListView.builder(
                      itemCount: _coches.length,
                      itemBuilder: (context, index) {
                        final coche = _coches[index];
                        return Card(
                          elevation: 3,
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: Icon(Icons.local_parking,
                                color: Colors.blueAccent, size: 30),
                            title: Text(
                                coche["nombre_vehiculo"] ?? "Desconocido",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Última ubicación: ${coche["lugar_aparcado"] ?? "No disponible"}",
                                    style: TextStyle(fontSize: 14)),
                                Text(
                                    "Fecha entrega: ${coche["fentrega_log"] ?? "No disponible"}",
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
