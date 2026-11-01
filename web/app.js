// Importamos las librerías de Firebase desde internet (CDN)
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getFirestore, collection, query, where, getDocs, addDoc, serverTimestamp, orderBy, limit } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// ⚠️ CONFIGURACIÓN DE FIREBASE (Reemplazá con tus datos)
const firebaseConfig = {
  apiKey: "TU_API_KEY",
  authDomain: "portones-asistencia.firebaseapp.com",
  projectId: "portones-asistencia",
  storageBucket: "portones-asistencia.appspot.com",
  messagingSenderId: "TU_SENDER_ID",
  appId: "TU_APP_ID"
};

// Inicializamos Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Variables globales
let edificioActualId = null;

// Función para ingresar como cliente
window.ingresarCliente = async function() {
    const nombre = document.getElementById('login-nombre').value.trim();
    const clave = document.getElementById('login-clave').value.trim();
    const errorMsg = document.getElementById('login-error');

    if (!nombre || !clave) {
        errorMsg.textContent = "Por favor, completá ambos campos.";
        return;
    }

    try {
        const q = query(collection(db, "edificios"), where("nombre", "==", nombre), where("clave_acceso", "==", clave));
        const querySnapshot = await getDocs(q);

        if (querySnapshot.empty) {
            errorMsg.textContent = "Nombre o clave incorrecta.";
        } else {
            errorMsg.textContent = "";
            const doc = querySnapshot.docs[0];
            edificioActualId = doc.id;
            const data = doc.data();

            // Mostrar panel
            document.getElementById('login-box').classList.add('hidden');
            document.getElementById('panel-cliente').classList.remove('hidden');
            document.getElementById('nombre-edificio-panel').textContent = "Edificio: " + (data.nombre || data.direccion);

            // Cargar eventos
            cargarEventos();
        }
    } catch (e) {
        console.error(e);
        errorMsg.textContent = "Error de conexión: " + e.message;
    }
};

// Función para cargar los últimos eventos
async function cargarEventos() {
    if (!edificioActualId) return;
    const listaEventos = document.getElementById('lista-eventos');
    listaEventos.innerHTML = "Cargando...";

    try {
        const q = query(collection(db, "solicitudes"), where("edificioId", "==", edificioActualId), orderBy("fecha", "desc"), limit(2));
        const querySnapshot = await getDocs(q);

        if (querySnapshot.empty) {
            listaEventos.innerHTML = "<p>No hay eventos recientes.</p>";
            return;
        }

        listaEventos.innerHTML = "";
        querySnapshot.forEach((doc) => {
            const data = doc.data();
            const div = document.createElement('div');
            div.className = 'evento-item';
            
            let html = `<p><strong>Estado:</strong> ${data.estado || 'pendiente'}</p>`;
            html += `<p><strong>Problema:</strong> ${data.texto}</p>`;
            
            if (data.conversacion && data.conversacion.length > 0) {
                html += `<div class="respuesta"><strong>Conversación:</strong><br>`;
                data.conversacion.forEach(msg => {
                    html += `💬 ${msg.emisor}: ${msg.texto}<br>`;
                });
                html += `</div>`;
            }
            
            div.innerHTML = html;
            listaEventos.appendChild(div);
        });
    } catch (e) {
        console.error(e);
        listaEventos.innerHTML = "<p>Error al cargar eventos.</p>";
    }
}

// Función para enviar un nuevo reclamo
window.enviarReclamo = async function() {
    if (!edificioActualId) return;

    const nombre = document.getElementById('reclamo-nombre').value.trim();
    const apellido = document.getElementById('reclamo-apellido').value.trim();
    const piso = document.getElementById('reclamo-piso').value.trim();
    const depto = document.getElementById('reclamo-depto').value.trim();
    const telefono = document.getElementById('reclamo-telefono').value.trim();
    const texto = document.getElementById('reclamo-texto').value.trim();

    if (!nombre || !apellido || !texto) {
        alert("Por favor, completá nombre, apellido y descripción.");
        return;
    }

    try {
        const direccionEdificio = document.getElementById('nombre-edificio-panel').textContent.replace("Edificio: ", "");

        await addDoc(collection(db, "solicitudes"), {
            edificioId: edificioActualId,
            direccion: direccionEdificio,
            nombre: nombre,
            apellido: apellido,
            piso: piso,
            depto: depto,
            telefono: telefono,
            texto: texto,
            fecha: serverTimestamp(),
            estado: 'pendiente',
            fotoUrl: null,
            videoUrl: null,
            conversacion: []
        });

        alert("✅ Solicitud enviada correctamente.");
        
        // Limpiar formulario
        document.getElementById('reclamo-nombre').value = "";
        document.getElementById('reclamo-apellido').value = "";
        document.getElementById('reclamo-piso').value = "";
        document.getElementById('reclamo-depto').value = "";
        document.getElementById('reclamo-telefono').value = "";
        document.getElementById('reclamo-texto').value = "";

        // Recargar eventos
        cargarEventos();

    } catch (e) {
        console.error(e);
        alert("Error al enviar la solicitud: " + e.message);
    }
};

// Función para cerrar sesión
window.cerrarSesion = function() {
    edificioActualId = null;
    document.getElementById('panel-cliente').classList.add('hidden');
    document.getElementById('login-box').classList.remove('hidden');
    document.getElementById('login-nombre').value = "";
    document.getElementById('login-clave').value = "";
    document.getElementById('lista-eventos').innerHTML = "";
};
