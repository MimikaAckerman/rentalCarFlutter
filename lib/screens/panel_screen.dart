import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'car_request_screen.dart'; // Importar la pantalla del formulario

class PanelScreen extends StatefulWidget {
  final String username;

  PanelScreen({required this.username});

  @override
  _PanelScreenState createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  List<Map<String, dynamic>> carStatus =
      []; // Lista para almacenar el estado de los coches

  @override
  void initState() {
    super.initState();
    _fetchCarStatus();
  }

  Future<void> _fetchCarStatus() async {
    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/availableCard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          carStatus =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al obtener datos: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Widget _buildCarCard(String carName, String imagePath, String status) {
    // Determinar colores y efectos según el estado
    final isAvailable = status == 'libre';
    final color = isAvailable ? Colors.green : Colors.red.withOpacity(0.5);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del coche
          Opacity(
            opacity:
                isAvailable ? 1.0 : 0.3, // Imagen borrosa si no está disponible
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                height: 180,
                width: double.infinity,
              ),
            ),
          ),
          // Nombre del coche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              carName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Botón Reservar e Indicador de estado
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicador de estado
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Disponible' : 'No Disponible',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Botón Reservar
                ElevatedButton(
                  onPressed: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CarRequestScreen(carName: carName),
                            ),
                          );
                        }
                      : null, // Deshabilitar el botón si no está disponible
                  child: Text('Reservar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Principal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: carStatus.isEmpty
            ? Center(child: CircularProgressIndicator()) // Indicador de carga
            : ListView(
                children: carStatus.map((car) {
                  // Mapear coches con su estado
                  if (car['nombre'] == 'Opel Corsa 2131MJG') {
                    return _buildCarCard(
                      'Opel Corsa 2023',
                      'assets/opel_corsa.jpg',
                      car['status'],
                    );
                  } else if (car['nombre'] == 'Nissan Juke 9843MNZ') {
                    return _buildCarCard(
                      'Coche Deportivo',
                      'assets/coche_deportivo.jpg',
                      car['status'],
                    );
                  }
                  return SizedBox.shrink(); // Ignorar coches no mapeados
                }).toList(),
              ),
      ),
    );
  }
}
