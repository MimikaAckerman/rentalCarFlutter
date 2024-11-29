import 'dart:async'; // Para usar Timer
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
  List<Map<String, dynamic>> carList = []; // Lista de todos los vehículos
  List<String> occupiedCars = []; // Lista de nombres de coches ocupados
  Timer? _timer; // Temporizador para actualización automática

  @override
  void initState() {
    super.initState();
    _fetchAllCars(); // Cargar todos los vehículos inicialmente
    _fetchOccupiedCars(); // Cargar los vehículos ocupados
    _startAutoRefresh(); // Iniciar actualización automática
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el temporizador cuando se destruye la pantalla
    super.dispose();
  }

  // Iniciar el temporizador para actualizar datos automáticamente
  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchOccupiedCars();
    });
  }

  // Cargar todos los vehículos disponibles (simulado o desde una API)
  Future<void> _fetchAllCars() async {
    // Aquí podrías conectar a una API para obtener todos los vehículos
    setState(() {
      carList = [
        {"nombre": "Opel Corsa 2131MJG", "imagen": "assets/opel_corsa.jpg"},
        {
          "nombre": "Nissan Juke 9843MNZ",
          "imagen": "assets/coche_deportivo.jpg"
        },
        // Agregar más vehículos aquí si es necesario
      ];
    });
  }

  // Obtener los coches ocupados
  Future<void> _fetchOccupiedCars() async {
    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/vehiculosOcupados');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          occupiedCars = data.map((car) => car['nombre'].toString()).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al obtener coches ocupados: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final carName = car['nombre'];
    final imagePath = car['imagen'];
    final isOccupied = occupiedCars.contains(carName);

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
            opacity: isOccupied ? 0.5 : 1.0, // Imagen borrosa si está ocupado
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
                    color: isOccupied ? Colors.grey : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOccupied ? 'Ocupado' : 'Disponible',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Botón Reservar
                ElevatedButton(
                  onPressed: isOccupied
                      ? null // Deshabilitar el botón si está ocupado
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarRequestScreen(
                                carName: carName,
                                username: widget.username,
                              ),
                            ),
                          );
                        },
                  child: Text('Reservar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOccupied ? Colors.grey : Colors.blue,
                  ),
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
        child: carList.isEmpty
            ? Center(child: CircularProgressIndicator()) // Indicador de carga
            : ListView(
                children: carList.map((car) => _buildCarCard(car)).toList(),
              ),
      ),
    );
  }
}
