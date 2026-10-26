import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      home: const PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.garage, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('PORTONES ASISTENCIA', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaCliente())),
                icon: const Icon(Icons.person),
                label: const Text('SOY CLIENTE / VECINO'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), textStyle: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginAdmin())),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('SOY ADMINISTRADOR'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 20), textStyle: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});
  @override
  State<LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin> {
  final _claveController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarClave() async {
    setState(() => _cargando = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('configuracion').doc('seguridad').get();
      final claveCorrecta = doc.data()?['clave_admin'] ?? '';

      if (_claveController.text.trim() == claveCorrecta) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaAdmin()));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clave de administrador incorrecta')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Administrador')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: _claveController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Clave de Administrador', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _verificarClave,
                child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('INGRESAR AL PANEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});
  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  final _direccionController = TextEditingController();
  final _claveController = TextEditingController();
  bool _cargando = false;

  Future<void> _ingresar() async {
    setState(() => _cargando = true);
    try {
      final query = await FirebaseFirestore.instance.collection('edificios')
          .where('direccion', isEqualTo: _direccionController.text.trim())
          .where('clave_acceso', isEqualTo: _claveController.text.trim()).get();

      if (query.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dirección o clave incorrecta')));
      } else {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaReporte(edificioId: query.docs.first.id, edificioData: query.docs.first.data())));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _direccionController, decoration: const InputDecoration(labelText: 'Dirección del edificio', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _claveController, decoration: const InputDecoration(labelText: 'Clave de acceso', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _cargando ? null : _ingresar, child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('INGRESAR'))),
          ],
        ),
      ),
    );
  }
}

class PantallaReporte extends StatelessWidget {
  final String edificioId;
  final Map<String, dynamic> edificioData;

  const PantallaReporte({super.key, required this.edificioId, required this.edificioData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(edificioData['direccion'] ?? 'Edificio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.location_on, color: Colors.red), title: Text(edificioData['direccion'] ?? ''), subtitle: Text('${edificioData['barrio'] ?? ''}, ${edificioData['ciudad'] ?? ''}'))),
          const SizedBox(height: 20),
          const Text('ÚLTIMOS EVENTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Sin eventos recientes'), subtitle: Text('Los últimos 2 eventos aparecerán aquí'))),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaFormularioReclamo(edificioId: edificioId, direccion: edificioData['direccion'] ?? ''))),
            icon: const Icon(Icons.add_alert),
            label: const Text('REPORTAR UN PROBLEMA'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }
}

class PantallaFormularioReclamo extends StatefulWidget {
  final String edificioId;
  final String direccion;
  const PantallaFormularioReclamo({super.key, required this.edificioId, required this.direccion});
  @override
  State<PantallaFormularioReclamo> createState() => _PantallaFormularioReclamoState();
}

class _PantallaFormularioReclamoState extends State<PantallaFormularioReclamo> {
  // ⚠️ DATOS DE CLOUDINARY
  static const String CLOUD_NAME = 'eh9nas8t';
  static const String UPLOAD_PRESET = 'portones_preset';

  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _piso = TextEditingController();
  final _depto = TextEditingController();
  final _telefono = TextEditingController();
  final _texto = TextEditingController();
  bool _enviando = false;
  File? _fotoSeleccionada;

  Future<void> _seleccionarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _fotoSeleccionada = File(pickedFile.path));
    }
  }

  Future<String?> _subirFotoACloudinary(File foto) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$CLOUD_NAME/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = UPLOAD_PRESET;
      request.files.add(await http.MultipartFile.fromPath('file', foto.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      }
    } catch (e) {
      print('Error subiendo foto: $e');
    }
    return null;
  }

  Future<void> _enviar() async {
    if (_nombre.text.isEmpty || _apellido.text.isEmpty || _texto.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completá nombre, apellido y descripción')));
      return;
    }
    setState(() => _enviando = true);

    String? fotoUrl;
    if (_fotoSeleccionada != null) {
      fotoUrl = await _subirFotoACloudinary(_fotoSeleccionada!);
    }

    try {
      await FirebaseFirestore.instance.collection('solicitudes').add({
        'edificioId': widget.edificioId,
        'direccion': widget.direccion,
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'piso': _piso.text.trim(),
        'depto': _depto.text.trim(),
        'telefono': _telefono.text.trim(),
        'texto': _texto.text.trim(),
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
        'fotoUrl': fotoUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Solicitud enviada correctamente')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Reclamo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _apellido, decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _piso, decoration: const InputDecoration(labelText: 'Piso', border: OutlineInputBorder()))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _depto, decoration: const InputDecoration(labelText: 'Depto', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _telefono, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _texto, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción del problema', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text('Adjuntar Foto (Opcional):'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _seleccionarFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _seleccionarFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          if (_fotoSeleccionada != null) ...[
            const SizedBox(height: 10),
            Image.file(_fotoSeleccionada!, height: 150),
            const Text('Foto lista para subir', style: TextStyle(color: Colors.green)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _enviando ? null : _enviar, child: _enviando ? const CircularProgressIndicator() : const Text('ENVIAR SOLICITUD')),
        ],
      ),
    );
  }
}

class PantallaAdmin extends StatelessWidget {
  const PantallaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Administrador')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('solicitudes').orderBy('fecha', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final solicitudes = snapshot.data!.docs;
          if (solicitudes.isEmpty) return const Center(child: Text('No hay solicitudes pendientes'));

          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final data = solicitudes[index].data() as Map<String, dynamic>;
              final docId = solicitudes[index].id;
              final fotoUrl = data['fotoUrl'] as String?;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.build, color: Colors.orange),
                  title: Text(data['direccion'] ?? 'Sin dirección'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['nombre']} ${data['apellido']} - Piso ${data['piso']} Dpto ${data['depto']}'),
                      Text('Tel: ${data['telefono']}'),
                      Text('Problema: ${data['texto']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (fotoUrl != null) const Text('📷 Foto adjunta', style: TextStyle(color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text('Estado: ${data['estado']}', style: TextStyle(fontWeight: FontWeight.bold, color: data['estado'] == 'pendiente' ? Colors.orange : Colors.green)),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Detalle del Reclamo'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Dirección: ${data['direccion']}'),
                              Text('Nombre: ${data['nombre']} ${data['apellido']}'),
                              Text('Piso: ${data['piso']} - Dpto: ${data['depto']}'),
                              Text('Teléfono: ${data['telefono']}'),
                              const SizedBox(height: 10),
                              const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(data['texto'] ?? ''),
                              if (fotoUrl != null) ...[
                                const SizedBox(height: 10),
                                const Text('Foto del problema:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Image.network(fotoUrl, height: 200, errorBuilder: (context, error, stackTrace) => const Text('Error al cargar la foto')),
                              ],
                              const Divider(),
                              const Text('Cambiar estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({'estado': 'pendiente'});
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('Pendiente'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({'estado': 'en proceso'});
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('En Proceso'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({'estado': 'resuelto'});
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('Resuelto'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
