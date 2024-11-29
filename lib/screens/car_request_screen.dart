import 'dart:convert'; // Para manejar JSON
import 'package:flutter/material.dart';
import 'package:signature/signature.dart'; // Paquete para la firma
import 'package:http/http.dart' as http; // Para la solicitud HTTP

class CarRequestScreen extends StatefulWidget {
  final String carName;
  final String username; // Recibimos el nombre del usuario al navegar

  CarRequestScreen({required this.carName, required this.username});

  @override
  _CarRequestScreenState createState() => _CarRequestScreenState();
}

class _CarRequestScreenState extends State<CarRequestScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
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

  // Método para enviar la solicitud de reserva
  Future<void> _reserveCar() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, seleccione ambas fechas')),
      );
      return;
    }

    // Verificar si hay una firma válida
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, firme antes de continuar')),
      );
      return;
    }

    // Obtener la firma como string
    final signatureData = await _signatureController.toPngBytes();
    final signatureBase64 = base64Encode(signatureData!);

    // Construir los datos para la solicitud
    final reservationData = {
      "nombre": widget.carName,
      "usuario": widget.username,
      "firma": signatureBase64,
      "fecha_reserva":
          "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}",
      "fecha_devolucion":
          "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}",
    };

    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/reservarCoche');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reservationData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva realizada con éxito')),
        );
        Navigator.pop(context); // Volver al panel
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.reasonPhrase}')),
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
              // Selección de Fecha de Solicitud
              Text(
                'Fecha de Solicitud',
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
              SizedBox(height: 16),

              // Selección de Fecha de Entrega
              Text(
                'Fecha de Entrega',
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
                        ? 'Seleccione la fecha de entrega'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
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
                  onPressed: _reserveCar,
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
