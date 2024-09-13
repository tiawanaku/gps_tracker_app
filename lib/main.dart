import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Necesario para usar Timer
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationSender(),
    );
  }
}

class LocationSender extends StatefulWidget {
  @override
  _LocationSenderState createState() => _LocationSenderState();
}

class _LocationSenderState extends State<LocationSender> {
  String _locationMessage = "Esperando para enviar la ubicación...";
  Timer? _timer; // Timer para enviar la ubicación periódicamente

  @override
  void initState() {
    super.initState();
    // Configurar el Timer para enviar la ubicación cada 2 minutos
    _timer = Timer.periodic(Duration(minutes: 2), (Timer t) => _getLocationAndSend());
    // Llamar inmediatamente a la función para obtener la ubicación al iniciar
    _getLocationAndSend();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el Timer cuando se destruye el widget
    super.dispose();
  }

  Future<void> _getLocationAndSend() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _locationMessage = "Verificando servicios de ubicación...";
    });

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = "Los servicios de ubicación están deshabilitados.";
      });
      return;
    }

    setState(() {
      _locationMessage = "Verificando permisos de ubicación...";
    });

    // Solicitar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = "Los permisos de ubicación fueron denegados.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "Los permisos de ubicación fueron denegados permanentemente.";
      });
      return;
    }

    setState(() {
      _locationMessage = "Obteniendo ubicación...";
    });

    try {
      // Obtener la ubicación
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationMessage = "Ubicación: ${position.latitude}, ${position.longitude}";
      });

      // Preparar los datos en formato JSON
      var jsonData = jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      // Enviar la ubicación al endpoint en localhost
      String url = 'http://64.225.54.113:8046/gps';
      var response = await http.post(
        Uri.parse(url),
        body: jsonData,
      );

      if (response.statusCode == 200) {
        setState(() {
          _locationMessage = "Ubicación enviada con éxito al servidor!";
        });
      } else {
        setState(() {
          _locationMessage = "Error al enviar la ubicación al servidor: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = "Error de conexión: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GPS Tracker"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_locationMessage, textAlign: TextAlign.center), // Alineación para que el texto no se corte
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getLocationAndSend, // Puedes mantener el botón por conveniencia
                child: Text("Obtener ubicación"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
