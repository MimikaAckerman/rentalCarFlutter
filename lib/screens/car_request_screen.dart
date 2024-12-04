import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CarRequestScreen extends StatefulWidget {
  final String carName;
  final String username;

  CarRequestScreen({required this.carName, required this.username});

  @override
  _CarRequestScreenState createState() => _CarRequestScreenState();
}

class _CarRequestScreenState extends State<CarRequestScreen> {
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  bool _isLoading = false;

  Future<bool> _isReservationValid(
      DateTime fechaInicio, DateTime fechaFin) async {
    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/vehiculosOcupados');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> reservations = jsonDecode(response.body);

        // Filtrar reservas para el coche actual
        final carReservations = reservations.where((reservation) {
          return reservation['nombre'] == widget.carName;
        }).toList();

        // Verificar si hay solapamiento
        for (var reservation in carReservations) {
          DateTime existingStart = DateTime.parse(reservation['fechaInicio']);
          DateTime existingEnd = DateTime.parse(reservation['fechaFin']);

          // Condición de solapamiento
          if (!(fechaFin.isBefore(existingStart) ||
              fechaInicio.isAfter(existingEnd))) {
            return false; // Reservas se solapan
          }
        }
        return true; // No hay solapamiento
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al obtener reservas: ${response.statusCode}')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
      return false;
    }
  }

  Future<void> _handleReserve() async {
    final String fechaInicioText = _fechaInicioController.text;
    final String fechaFinText = _fechaFinController.text;

    if (fechaInicioText.isEmpty || fechaFinText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa ambas fechas')),
      );
      return;
    }

    try {
      DateTime fechaInicio = DateTime.parse(fechaInicioText);
      DateTime fechaFin = DateTime.parse(fechaFinText);

      if (fechaInicio.isAfter(fechaFin)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'La fecha de inicio debe ser antes que la fecha de fin')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Verificar si la reserva es válida
      bool isValid = await _isReservationValid(fechaInicio, fechaFin);

      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva válida. Procesando...')),
        );
        // Aquí puedes enviar la solicitud de reserva al servidor
        // TODO: Añade lógica para realizar la reserva
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Este coche ya está reservado en este horario')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Formato de fecha inválido. Usa YYYY-MM-DD HH:MM:SS')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservar ${widget.carName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fechaInicioController,
              decoration: InputDecoration(
                labelText: 'Fecha Inicio (YYYY-MM-DD HH:MM:SS)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _fechaFinController,
              decoration: InputDecoration(
                labelText: 'Fecha Fin (YYYY-MM-DD HH:MM:SS)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleReserve,
              child:
                  _isLoading ? CircularProgressIndicator() : Text('Reservar'),
            ),
          ],
        ),
      ),
    );
  }
}
