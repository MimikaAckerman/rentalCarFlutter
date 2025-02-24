import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CarRequestScreen extends StatefulWidget {
  final String carName;
  final String username;

  const CarRequestScreen(
      {super.key, required this.carName, required this.username});

  @override
  _CarRequestScreenState createState() => _CarRequestScreenState();
}

class _CarRequestScreenState extends State<CarRequestScreen> {
  DateTime? _fechaInicio;
  TimeOfDay? _horaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaFin;
  bool _isLoading = false;
  final TextEditingController _firmaController =
      TextEditingController(); // Controlador para la firma

  Future<void> _selectFechaInicio() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _fechaInicio = pickedDate;
          _horaInicio = pickedTime;
        });
      }
    }
  }

  Future<void> _selectFechaFin() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _fechaFin = pickedDate;
          _horaFin = pickedTime;
        });
      }
    }
  }

  // Función para formatear fecha y hora en "YYYY-MM-DD HH:MM:SS"
  String _formatDateTime(DateTime date, TimeOfDay time) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} "
        "${_twoDigits(time.hour)}:${_twoDigits(time.minute)}:00";
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

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

          // ❌ Si hay solapamiento, la reserva no es válida
          if (!(fechaFin.isBefore(existingStart) ||
              fechaInicio.isAfter(existingEnd))) {
            return false;
          }
        }
        return true; // ✅ Si no hay solapamiento, permite la reserva
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
    if (_fechaInicio == null ||
        _horaInicio == null ||
        _fechaFin == null ||
        _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona ambas fechas y horas')),
      );
      return;
    }

    final DateTime fechaInicio = DateTime(
      _fechaInicio!.year,
      _fechaInicio!.month,
      _fechaInicio!.day,
      _horaInicio!.hour,
      _horaInicio!.minute,
    );

    final DateTime fechaFin = DateTime(
      _fechaFin!.year,
      _fechaFin!.month,
      _fechaFin!.day,
      _horaFin!.hour,
      _horaFin!.minute,
    );

    if (fechaInicio.isAfter(fechaFin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('La fecha de inicio debe ser antes que la fecha de fin')),
      );
      return;
    }

    if (_firmaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa tu firma digital')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool isValid = await _isReservationValid(fechaInicio, fechaFin);

    if (isValid) {
      final url =
          Uri.parse('https://api-psc-goland.azurewebsites.net/reservarCoche');
      final Map<String, dynamic> requestData = {
        "nombre": widget.carName,
        "usuario": widget.username,
        "firma": _firmaController.text, // ✅ Firma ingresada por el usuario
        "fsolicitud":
            _formatDateTime(_fechaInicio!, _horaInicio!), // ✅ Formato correcto
        "fentrega": _formatDateTime(_fechaFin!, _horaFin!) // ✅ Formato correcto
      };

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reserva realizada con éxito')),
          );
          Navigator.pop(context); // ✅ Cerrar pantalla después de reservar
        } else {
          final responseBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error: ${responseBody["error"] ?? "Error desconocido"}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Este coche ya está reservado en este horario')),
      );
    }

    setState(() {
      _isLoading = false;
    });
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
            ListTile(
              title: Text(_fechaInicio != null && _horaInicio != null
                  ? 'Inicio: ${_formatDateTime(_fechaInicio!, _horaInicio!)}'
                  : 'Seleccionar fecha y hora de inicio'),
              trailing: Icon(Icons.calendar_today),
              onTap: _selectFechaInicio,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(_fechaFin != null && _horaFin != null
                  ? 'Fin: ${_formatDateTime(_fechaFin!, _horaFin!)}'
                  : 'Seleccionar fecha y hora de fin'),
              trailing: Icon(Icons.calendar_today),
              onTap: _selectFechaFin,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _firmaController,
              decoration: InputDecoration(labelText: 'Firma digital'),
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
