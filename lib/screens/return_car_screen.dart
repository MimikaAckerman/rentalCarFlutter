import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_platform/universal_platform.dart';

class ReturnCarScreen extends StatefulWidget {
  final String carName;
  final String username;

  ReturnCarScreen({required this.carName, required this.username});

  @override
  _ReturnCarScreenState createState() => _ReturnCarScreenState();
}

class _ReturnCarScreenState extends State<ReturnCarScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _parkingController = TextEditingController();
  final TextEditingController _vehicleConditionController =
      TextEditingController();
  final TextEditingController _fuelLevelController = TextEditingController();

  XFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  Future<void> _submitReturn() async {
    final url =
        Uri.parse('https://api-psc-goland.azurewebsites.net/entregaCoche');

    try {
      // Concatenar todos los campos en un solo string separados por comas
      String comentarios = [
        "Motivo de utilización: ${_reasonController.text}",
        "Lugar de desplazamiento: ${_locationController.text}",
        "Km de devolución: ${_kmController.text}",
        "Lugar de estacionamiento: ${_parkingController.text}",
        "Situación actual del vehículo: ${_vehicleConditionController.text}",
        "Nivel de depósito: ${_fuelLevelController.text}",
      ].join(', ');

      Map<String, String> fields = {
        'usuario': widget.username,
        'nombre': widget.carName,
        'comentarios': comentarios,
      };

      if (_selectedFile != null) {
        if (UniversalPlatform.isWeb) {
          final fileBytes = await _selectedFile!.readAsBytes();
          var request = http.MultipartRequest('PUT', url)
            ..fields.addAll(fields)
            ..files.add(http.MultipartFile.fromBytes(
              'factura',
              fileBytes,
              filename: _selectedFile!.name,
            ));

          var response = await request.send();

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Devolución procesada exitosamente')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error al procesar la devolución: ${response.statusCode}')),
            );
          }
        } else {
          var request = http.MultipartRequest('PUT', url)
            ..fields.addAll(fields)
            ..files.add(await http.MultipartFile.fromPath(
              'factura',
              _selectedFile!.path,
            ));

          var response = await request.send();

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Devolución procesada exitosamente')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error al procesar la devolución: ${response.statusCode}')),
            );
          }
        }
      } else {
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(fields),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Devolución procesada exitosamente')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error al procesar la devolución: ${response.statusCode}')),
          );
        }
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
        title: Text('Devolución del Vehículo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehículo: ${widget.carName}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Usuario: ${widget.username}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildTextField(_reasonController, 'Motivo de utilización'),
              SizedBox(height: 16),
              _buildTextField(_locationController, 'Lugar de desplazamiento'),
              SizedBox(height: 16),
              _buildTextField(_kmController, 'Km de devolución'),
              SizedBox(height: 16),
              _buildTextField(_parkingController, 'Lugar de estacionamiento'),
              SizedBox(height: 16),
              _buildTextField(
                  _vehicleConditionController, 'Situación actual del vehículo'),
              SizedBox(height: 16),
              _buildTextField(_fuelLevelController, 'Nivel de depósito'),
              SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickFile,
                    child: Text('Subir Factura'),
                  ),
                  SizedBox(width: 16),
                  _selectedFile != null
                      ? Text(
                          'Archivo: ${_selectedFile!.name}',
                          style: TextStyle(fontSize: 14, color: Colors.green),
                        )
                      : Text(
                          'No se ha seleccionado ningún archivo',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                ],
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_reasonController.text.isEmpty ||
                        _locationController.text.isEmpty ||
                        _kmController.text.isEmpty ||
                        _parkingController.text.isEmpty ||
                        _vehicleConditionController.text.isEmpty ||
                        _fuelLevelController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Por favor, completa todos los campos antes de continuar.')),
                      );
                      return;
                    }

                    _submitReturn();
                  },
                  child: Text('Devolver Vehículo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
