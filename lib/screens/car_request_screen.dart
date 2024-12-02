import 'package:flutter/material.dart';
import 'package:signature/signature.dart'; // Paquete para la firma
import 'dart:convert';
import 'package:http/http.dart' as http;

class CarRequestScreen extends StatefulWidget {
  final String carName;
  final String username;

  // Recibimos el nombre del coche y el usuario al navegar
  CarRequestScreen({required this.carName, required this.username});

  @override
  _CarRequestScreenState createState() => _CarRequestScreenState();
}

class _CarRequestScreenState extends State<CarRequestScreen> {
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // Método para mostrar el calendario y seleccionar una fecha
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(Duration(days: 365)), // Hasta un año en el futuro
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  // Método para seleccionar la hora
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  // Método para enviar la solicitud
  Future<void> _sendRequest() async {
    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todas las fechas y horas')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, firme el documento')),
      );
      return;
    }

    // Convertir la firma a base64
    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) return;
    final signatureBase64 = base64Encode(signatureBytes);

    // Construir el cuerpo de la solicitud
    final requestBody = {
      "nombre": widget.carName,
      "usuario": widget.username,
      "firma": signatureBase64,
      "fecha_reserva":
          "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}",
      "hora_reserva":
          "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}",
      "fecha_devolucion":
          "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}",
      "hora_devolucion":
          "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}",
    };

    // Enviar la solicitud al servidor
    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/reservarCoche');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud enviada exitosamente')),
        );
        Navigator.pop(context); // Volver al panel principal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al enviar la solicitud: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitud - ${widget.carName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selección de Fecha y Hora de Solicitud
              Text(
                'Fecha y Hora de Solicitud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _startDate == null
                        ? 'Seleccione la fecha de solicitud'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context, true),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _startTime == null
                        ? 'Seleccione la hora de solicitud'
                        : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Selección de Fecha y Hora de Devolución
              Text(
                'Fecha y Hora de Devolución',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _endDate == null
                        ? 'Seleccione la fecha de devolución'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context, false),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _endTime == null
                        ? 'Seleccione la hora de devolución'
                        : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Campo de Firma
              Text(
                'Firma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => _signatureController.clear(),
                child: Text('Limpiar Firma'),
              ),

              SizedBox(height: 24),

              // Botón de Solicitar
              Center(
                child: ElevatedButton(
                  onPressed: _sendRequest,
                  child: Text('Solicitar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
