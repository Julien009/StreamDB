// ── Cargar catálogo desde SQL Server ─────────────
let todasLasPeliculas = [];
let peliculaActual    = { id: null, nombre: null };

async function cargarCatalogo() {
  try {
    const response  = await fetch('/peliculas');
    const peliculas = await response.json();
    todasLasPeliculas = peliculas;
    mostrarCatalogo(peliculas);
  } catch (error) {
    console.error('Error cargando catálogo:', error);
  }
}

function mostrarCatalogo(peliculas) {
  const grid = document.getElementById('grid-peliculas');
  grid.innerHTML = '';

  peliculas.forEach(p => {
    const emoji  = p.Tipo === 'Pelicula' ? '🎬' : '📺';
    const tipoCss = p.Tipo === 'Pelicula' ? 'tipo-pelicula' : 'tipo-serie';

    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <div class="card-poster">${emoji}</div>
      <div class="card-info">
        <div class="card-titulo">${p.Nombre}</div>
        <div class="card-genero">${p.Genero} · ${p.AnioEstreno}</div>
        <span class="card-tipo ${tipoCss}">${p.Tipo}</span>
        <button class="btn-reproducir" onclick="reproducir(${p.idPelicula}, '${p.Nombre.replace(/'/g, "\\'")}')">
          ▶ Reproducir
        </button>
      </div>
    `;
    grid.appendChild(card);
  });
}

// ── Filtrar por género ────────────────────────────
function filtrar(genero) {
  document.querySelectorAll('.filtro-btn').forEach(btn => {
    btn.classList.remove('activo');
  });
  event.target.classList.add('activo');

  if (genero === 'todos') {
    mostrarCatalogo(todasLasPeliculas);
  } else {
    const filtradas = todasLasPeliculas.filter(p => p.Genero === genero);
    mostrarCatalogo(filtradas);

    // Registrar preferencia en MongoDB
    fetch('/preferencias/add', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        idUsuario : 1,
        genero    : genero,
        fecha     : new Date().toISOString().split('T')[0]
      })
    });
  }
}

// ── Búsqueda en vivo (filtra mientras escribe) ────
function buscarEnVivo(termino) {
  if (termino.trim() === '') {
    mostrarCatalogo(todasLasPeliculas);
    return;
  }
  const filtradas = todasLasPeliculas.filter(p =>
    p.Nombre.toLowerCase().includes(termino.toLowerCase())
  );
  mostrarCatalogo(filtradas);
}

// ── Registrar búsqueda al presionar Enter ─────────
async function registrarBusqueda(termino) {
  if (termino.trim().length < 2) return;

  const filtradas = todasLasPeliculas.filter(p =>
    p.Nombre.toLowerCase().includes(termino.toLowerCase())
  );

  await fetch('/historial/add', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      idUsuario     : 1,
      busqueda      : termino,
      resultados    : filtradas.length,
      sin_resultado : filtradas.length === 0,
      fecha         : new Date().toISOString().split('T')[0]
    })
  });
}

// ── Variable para sesión activa de historial ──────
let sesionActualId = null;

// ── Reproductor y registro de evento en MongoDB ───
async function reproducir(idPelicula, nombre) {
  peliculaActual = { id: idPelicula, nombre: nombre };
  document.getElementById('titulo-pelicula').textContent = nombre;
  document.getElementById('modal-reproductor').classList.remove('oculto');
  document.getElementById('evento-status').style.display = 'none';
  document.getElementById('form-resena').style.display   = 'none';
  document.getElementById('resena-status').style.display = 'none';
  document.getElementById('texto-resena').value = '';

  // Buscar datos de la película del catálogo ya cargado
  const peli = todasLasPeliculas.find(p => p.idPelicula === idPelicula);

  try {
    // 0) Registrar dispositivo (NUEVO)
    await registrarDispositivo();
    // 1) Registro en eventos_streaming (igual que antes)
    const r1 = await fetch('/reproducir', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        idUsuario  : 1,
        idPelicula : idPelicula,
        pelicula   : nombre,
        dispositivo: 'Web',
        fecha      : new Date().toISOString().split('T')[0]
      })
    });

    // 2) Crear/reanudar sesión en historial_reproducciones (NUEVO)
    const r2 = await fetch('/reproduccion/iniciar', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        idUsuario   : 1,
        usuario     : 'Walter Garcia',
        idPelicula  : idPelicula,
        pelicula    : nombre,
        genero      : peli ? peli.Genero : '',
        duracion_min: peli ? (peli.Duracion || 120) : 120,
        calidad     : '1080p'
      })
    });

    const res2 = await r2.json();
    sesionActualId = res2.sesion_id;  // guardamos el _id para los updates

    const status = document.getElementById('evento-status');
    status.style.display = 'block';
    status.textContent   = '✅ Evento registrado en MongoDB: ' + nombre;

    document.getElementById('form-resena').style.display = 'block';

    // 3) Escuchar eventos del video para hacer UPDATE (NUEVO)
    registrarEventosVideo();

  } catch (error) {
    console.error('Error registrando evento:', error);
  }
}

// ── Cerrar reproductor ────────────────────────────
function cerrarReproductor() {
  document.getElementById('modal-reproductor').classList.add('oculto');
  const video = document.getElementById('video-player');
  video.pause();
  video.currentTime = 0;
}

// ── Enviar reseña a MongoDB ───────────────────────
async function enviarResena() {
  const texto        = document.getElementById('texto-resena').value.trim();
  const calificacion = document.getElementById('calificacion').value;

  if (!texto) {
    alert('Escribe tu reseña antes de enviar.');
    return;
  }

  await fetch('/resenas/add', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      idUsuario   : 1,
      idPelicula  : peliculaActual.id,
      pelicula    : peliculaActual.nombre,
      resena      : texto,
      calificacion: parseInt(calificacion),
      fecha       : new Date().toISOString().split('T')[0]
    })
  });

  const status = document.getElementById('resena-status');
  status.style.display = 'block';
  status.textContent   = '✅ Reseña guardada en MongoDB';
  document.getElementById('texto-resena').value = '';
}

// ── Escuchar pause/ended del video ────────────────
function registrarEventosVideo() {
  const video = document.getElementById('video-player');

  // Remover listeners anteriores para no duplicarlos
  video.removeEventListener('pause',  onVideoPausa);
  video.removeEventListener('ended',  onVideoTerminado);

  video.addEventListener('pause',  onVideoPausa);
  video.addEventListener('ended',  onVideoTerminado);
}

async function onVideoPausa() {
  if (!sesionActualId) return;
  const video  = document.getElementById('video-player');
  const minuto = Math.floor(video.currentTime / 60);

  await fetch('/reproduccion/actualizar', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      sesion_id : sesionActualId,
      minuto    : minuto,
      completada: false
    })
  });

  console.log(`⏸️ Historial actualizado → pausada en minuto ${minuto}`);
}

async function onVideoTerminado() {
  if (!sesionActualId) return;
  const video  = document.getElementById('video-player');
  const minuto = Math.floor(video.duration / 60);

  await fetch('/reproduccion/actualizar', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      sesion_id : sesionActualId,
      minuto    : minuto,
      completada: true
    })
  });

  console.log(`✅ Historial actualizado → completada`);
}

// ── Detectar y registrar dispositivo ─────────────
async function registrarDispositivo() {
  const ua = navigator.userAgent;

  // Detectar sistema operativo
  let so = 'Desconocido';
  if      (ua.includes('Windows NT 10.0')) so = 'Windows 10';
  else if (ua.includes('Windows NT 11.0')) so = 'Windows 11';
  else if (ua.includes('Mac OS X'))        so = 'macOS';
  else if (ua.includes('Linux'))           so = 'Linux';
  else if (ua.includes('Android'))         so = 'Android';
  else if (ua.includes('iPhone'))          so = 'iOS';

  await fetch('/dispositivo/registrar', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      idUsuario          : 1,
      codigo_dispositivo : 'DEV-WEB-001',
      tipo               : 'PC / Laptop',
      sistema_operativo  : so
    })
  });
}

// ── Cargar al iniciar ─────────────────────────────
document.addEventListener('DOMContentLoaded', cargarCatalogo);
