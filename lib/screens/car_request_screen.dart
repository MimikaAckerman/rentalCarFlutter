import 'package:flutter/material.dart';
import 'package:signature/signature.dart'; // Paquete para la firma

class CarRequestScreen extends StatefulWidget {
  final String carName;

  // Recibimos el nombre del coche al navegar
  CarRequestScreen({required this.carName});

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
                  onPressed: () {
                    if (_startDate == null || _endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Por favor, seleccione ambas fechas'),
                        ),
                      );
                      return;
                    }

                    // Aquí podrías procesar los datos y enviarlos a un backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Solicitud enviada exitosamente'),
                      ),
                    );
                  },
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
