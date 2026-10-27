import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaAdmin()));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clave incorrecta')));
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
            TextField(controller: _claveController, obscureText: true, decoration: const InputDecoration(labelText: 'Clave de Administrador', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _cargando ? null : _verificarClave, child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('INGRESAR'))),
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
  final _nombreController = TextEditingController();
  final _claveController = TextEditingController();
  bool _cargando = false;

  Future<void> _ingresar() async {
    setState(() => _cargando = true);
    try {
      final query = await FirebaseFirestore.instance.collection('edificios')
          .where('nombre', isEqualTo: _nombreController.text.trim())
          .where('clave_acceso', isEqualTo: _claveController.text.trim()).get();

      if (query.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre o clave incorrecta')));
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
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre del Edificio (Ej: Torre Costanera)', border: OutlineInputBorder())),
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
    final String titulo = edificioData['nombre'] ?? edificioData['direccion'] ?? 'Edificio';
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('solicitudes').where('edificioId', isEqualTo: edificioId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var solicitudes = snapshot.data!.docs;
          solicitudes.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? fechaA = dataA['fecha'] as Timestamp?;
            Timestamp? fechaB = dataB['fecha'] as Timestamp?;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;
            return fechaB.compareTo(fechaA);
          });
          if (solicitudes.length > 2) solicitudes = solicitudes.take(2).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: ListTile(leading: const Icon(Icons.location_on, color: Colors.red), title: Text(edificioData['direccion'] ?? ''), subtitle: Text('${edificioData['barrio'] ?? ''}, ${edificioData['ciudad'] ?? ''}'))),
              const SizedBox(height: 20),
              const Text('ÚLTIMOS EVENTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              if (solicitudes.isEmpty) const Card(child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Sin eventos recientes'), subtitle: Text('Los últimos 2 eventos aparecerán aquí'))),
              ...solicitudes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final tieneRespuesta = data['respuestaAdmin'] != null && data['respuestaAdmin'].toString().isNotEmpty;
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.info, color: data['estado'] == 'resuelto' ? Colors.green : Colors.orange),
                    title: Text(data['texto'] ?? 'Sin descripción', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estado: ${data['estado'] ?? 'pendiente'}'),
                        if (tieneRespuesta) ...[
                          const Divider(),
                          const Text('💬 Respuesta del administrador:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Text(data['respuestaAdmin'], style: const TextStyle(color: Colors.blue)),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaFormularioReclamo(edificioId: edificioId, direccion: edificioData['direccion'] ?? ''))),
                icon: const Icon(Icons.add_alert),
                label: const Text('REPORTAR UN PROBLEMA'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          );
        },
      ),
    );
  }
}class PantallaFormularioReclamo extends StatefulWidget {
  final String edificioId;
  final String direccion;
  const PantallaFormularioReclamo({super.key, required this.edificioId, required this.direccion});
  @override
  State<PantallaFormularioReclamo> createState() => _PantallaFormularioReclamoState();
}

class _PantallaFormularioReclamoState extends State<PantallaFormularioReclamo> {
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
  File? _videoSeleccionado;

  Future<void> _seleccionarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) setState(() => _fotoSeleccionada = File(pickedFile.path));
  }

  Future<void> _seleccionarVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
    if (pickedFile != null) setState(() => _videoSeleccionado = File(pickedFile.path));
  }

  Future<String?> _subirArchivoACloudinary(File archivo, String tipo) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$CLOUD_NAME/$tipo/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = UPLOAD_PRESET;
      request.files.add(await http.MultipartFile.fromPath('file', archivo.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final jsonMap = jsonDecode(String.fromCharCodes(responseData));
        return jsonMap['secure_url'];
      }
    } catch (e) { print('Error: $e'); }
    return null;
  }

  Future<void> _enviar() async {
    if (_nombre.text.isEmpty || _apellido.text.isEmpty || _texto.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completá nombre, apellido y descripción')));
      return;
    }
    setState(() => _enviando = true);
    String? fotoUrl;
    String? videoUrl;
    if (_fotoSeleccionada != null) fotoUrl = await _subirArchivoACloudinary(_fotoSeleccionada!, 'image');
    if (_videoSeleccionado != null) videoUrl = await _subirArchivoACloudinary(_videoSeleccionado!, 'video');
    try {
      await FirebaseFirestore.instance.collection('solicitudes').add({
        'edificioId': widget.edificioId, 'direccion': widget.direccion, 'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(), 'piso': _piso.text.trim(), 'depto': _depto.text.trim(),
        'telefono': _telefono.text.trim(), 'texto': _texto.text.trim(), 'fecha': FieldValue.serverTimestamp(),
        'estado': 'pendiente', 'fotoUrl': fotoUrl, 'videoUrl': videoUrl, 'respuestaAdmin': '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Solicitud enviada')));
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
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => _seleccionarFoto(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Cámara'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: () => _seleccionarFoto(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galería'))),
          ]),
          if (_fotoSeleccionada != null) ...[const SizedBox(height: 10), Image.file(_fotoSeleccionada!, height: 150)],
          const SizedBox(height: 20),
          const Text('Adjuntar Video (Opcional, máx 30s):'),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: _seleccionarVideo, icon: const Icon(Icons.videocam), label: const Text('Grabar Video'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45))),
          if (_videoSeleccionado != null) ...[const SizedBox(height: 10), const Text('✅ Video listo para subir', style: TextStyle(color: Colors.green))],
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _enviando ? null : _enviar, child: _enviando ? const CircularProgressIndicator() : const Text('ENVIAR SOLICITUD')),
        ],
      ),
    );
  }
}

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});
  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Administrador')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaNuevoEdificio())),
        child: const Icon(Icons.add_business),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('📋 SOLICITUDES PENDIENTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('solicitudes').orderBy('fecha', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final solicitudes = snapshot.data!.docs;
              if (solicitudes.isEmpty) return const Text('No hay solicitudes pendientes');
              return Column(
                children: solicitudes.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.build, color: Colors.orange),
                      title: Text(data['direccion'] ?? 'Sin dirección'),
                      subtitle: Text('${data['nombre']} ${data['apellido']} - Estado: ${data['estado']}'),
                      onTap: () => showDialog(context: context, builder: (context) => DialogoDetalleAdmin(data: data, docId: doc.id, fotoUrl: data['fotoUrl'], videoUrl: data['videoUrl'])),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(height: 40),
          const Text('🏢 MIS EDIFICIOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('edificios').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final edificios = snapshot.data!.docs;
              if (edificios.isEmpty) return const Text('No hay edificios registrados');
              return Column(
                children: edificios.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.apartment, color: Colors.blue),
                      title: Text(data['nombre'] ?? data['direccion'] ?? 'Sin nombre'),
                      subtitle: Text(data['ciudad'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaGestionPortones(edificioId: doc.id, edificioData: data))),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PantallaGestionPortones extends StatelessWidget {
  final String edificioId;
  final Map<String, dynamic> edificioData;
  const PantallaGestionPortones({super.key, required this.edificioId, required this.edificioData});

  @override
  Widget build(BuildContext context) {
    final String titulo = edificioData['nombre'] ?? edificioData['direccion'] ?? 'Portones';
    return Scaffold(
      appBar: AppBar(title: Text('Portones: $titulo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaNuevoPorton(edificioId: edificioId))),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('portones').where('edificioId', isEqualTo: edificioId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final portones = snapshot.data!.docs;
          if (portones.isEmpty) return const Center(child: Text('No hay portones. Toca el + para agregar uno.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: portones.length,
            itemBuilder: (context, index) {
              final data = portones[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.garage, color: Colors.blue),
                  title: Text(data['ubicacion'] ?? 'Sin nombre'),
                  subtitle: Text('Marca: ${data['marca'] ?? '-'} | Modelo: ${data['modelo'] ?? '-'}'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetallePorton(portonId: portones[index].id, portonData: data))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
