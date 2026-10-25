import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PortonesApp());
}

class PortonesApp extends StatelessWidget {
  const PortonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portones Asistencia',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _direccionController = TextEditingController();
  final _claveController = TextEditingController();
  bool _cargando = false;
  String _error = '';

  Future<void> _ingresar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final direccion = _direccionController.text.trim();
      final clave = _claveController.text.trim();

      final query = await FirebaseFirestore.instance
          .collection('edificios')
          .where('direccion', isEqualTo: direccion)
          .where('clave_acceso', isEqualTo: clave)
          .get();

      if (query.docs.isEmpty) {
        setState(() { _error = 'Dirección o clave incorrecta'; _cargando = false; });
        return;
      }

      final edificioId = query.docs.first.id;
      final edificioData = query.docs.first.data();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaEdificio(edificioId: edificioId, edificioData: edificioData),
          ),
        );
      }
    } catch (e) {
      setState(() { _error = 'Error de conexión: $e'; _cargando = false; });
    }
    setState(() { _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portones - Asistencia')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.garage, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección del edificio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _claveController,
              decoration: const InputDecoration(labelText: 'Clave de acceso', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _ingresar,
                child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('INGRESAR', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función GPS próximamente')));
              },
              child: const Text('📍 No sé la dirección (Usar GPS)'),
            )
          ],
        ),
      ),
    );
  }
}

class PantallaEdificio extends StatelessWidget {
  final String edificioId;
  final Map<String, dynamic> edificioData;

  const PantallaEdificio({super.key, required this.edificioId, required this.edificioData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(edificioData['direccion'] ?? 'Edificio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(edificioData['direccion'] ?? ''),
              subtitle: Text('${edificioData['barrio'] ?? ''}, ${edificioData['ciudad'] ?? ''}'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('ÚLTIMOS EVENTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Sin eventos recientes'),
              subtitle: Text('Los últimos 2 eventos aparecerán aquí'),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formulario de reclamo próximamente')));
            },
            icon: const Icon(Icons.add_alert),
            label: const Text('REPORTAR UN PROBLEMA'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }
}
