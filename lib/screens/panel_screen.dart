import 'dart:async'; // Para usar Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'car_request_screen.dart';
import 'return_car_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'package:collection/collection.dart';

class PanelScreen extends StatefulWidget {
  final String username;

  PanelScreen({required this.username});

  @override
  _PanelScreenState createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  List<Map<String, dynamic>> carList = []; // Lista de todos los vehículos
  List<Map<String, dynamic>> occupiedCars = []; // Lista de coches ocupados
  Timer? _timer; // Temporizador para actualización automática
  bool _navigatedToReturnScreen =
      false; // Controlar si ya navegamos a ReturnCarScreen

  @override
  void initState() {
    super.initState();
    _fetchAllCars(); // Inicializar vehículos disponibles
    _fetchOccupiedCars(); // Inicializar vehículos ocupados
    _startAutoRefresh(); // Activar auto-refresh
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar temporizador al salir
    super.dispose();
  }

  // Iniciar temporizador para actualizar datos
  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchOccupiedCars(); // Actualizar coches ocupados
    });
  }

  // Cargar todos los vehículos disponibles
  Future<void> _fetchAllCars() async {
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

  // Obtener coches ocupados y verificar si el usuario tiene uno reservado
  Future<void> _fetchOccupiedCars() async {
    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/vehiculosOcupados');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> newOccupiedCars =
            List<Map<String, dynamic>>.from(data);

        // Actualizar solo si hay cambios en los datos
        if (!const DeepCollectionEquality()
            .equals(occupiedCars, newOccupiedCars)) {
          setState(() {
            occupiedCars = newOccupiedCars;
          });
        }

        // Verificar si el usuario tiene un vehículo reservado
        if (!_navigatedToReturnScreen) {
          final userCar = occupiedCars.firstWhere(
            (car) => car['usuario'] == widget.username,
            orElse: () => {}, //devuelve un mapa vacio
          );

          if (userCar.isNotEmpty) {
            _navigatedToReturnScreen = true; // Prevenir navegación múltiple
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReturnCarScreen(
                  carName: userCar['nombre'],
                  username: widget.username,
                ),
              ),
            );
          }
        }
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
    final isOccupied =
        occupiedCars.any((occupiedCar) => occupiedCar['nombre'] == carName);

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
            opacity: isOccupied ? 0.5 : 1.0,
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
                      ? null // Deshabilitar botón si está ocupado
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
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.username),
              accountEmail: Text('${widget.username}@gmail.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.username[0].toUpperCase(),
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangePasswordScreen(username: widget.username),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: carList.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView(
                children: carList.map((car) => _buildCarCard(car)).toList(),
              ),
      ),
    );
  }
}
