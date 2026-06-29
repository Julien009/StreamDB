// ── Canvas y contexto ─────────────────────────────
const canvas  = document.getElementById('canvas');
const ctx     = canvas.getContext('2d');
canvas.width  = window.innerWidth;
canvas.height = window.innerHeight;

// ── Partículas ────────────────────────────────────
const particulas = [];
const CANTIDAD   = 200;
const CENTRO_X   = canvas.width  / 2;
const CENTRO_Y   = canvas.height / 2;

const COLORES = ['#ff4d00', '#5500ff', '#ffcc00', '#ff0000', '#ffffff'];

class Particula {
  constructor() { this.reset(); }

  reset() {
    const angulo    = Math.random() * Math.PI * 2;
    const distancia = Math.random() * 600 + 100;
    this.x          = CENTRO_X + Math.cos(angulo) * distancia;
    this.y          = CENTRO_Y + Math.sin(angulo) * distancia;
    this.vx         = (CENTRO_X - this.x) * 0.003;
    this.vy         = (CENTRO_Y - this.y) * 0.003;
    this.radio      = Math.random() * 3 + 1;
    this.color      = COLORES[Math.floor(Math.random() * COLORES.length)];
    this.alpha      = Math.random() * 0.8 + 0.2;
    this.activa     = true;
  }

  actualizar(fase) {
    if (fase === 'colapso') {
      this.vx *= 1.08;
      this.vy *= 1.08;
    }
    this.x += this.vx;
    this.y += this.vy;
    const dx = this.x - CENTRO_X;
    const dy = this.y - CENTRO_Y;
    if (Math.sqrt(dx * dx + dy * dy) < 5) this.activa = false;
  }

  dibujar() {
    ctx.save();
    ctx.globalAlpha = this.alpha;
    ctx.fillStyle   = this.color;
    ctx.shadowBlur  = 10;
    ctx.shadowColor = this.color;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radio, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
}

for (let i = 0; i < CANTIDAD; i++) particulas.push(new Particula());

// ── Loop de animación ─────────────────────────────
let fase = 'microverso';

function animar() {
  ctx.fillStyle = 'rgba(5, 5, 5, 0.15)';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  if (fase !== 'impacto') {
    particulas.forEach(p => {
      if (p.activa) { p.actualizar(fase); p.dibujar(); }
    });
  }
  requestAnimationFrame(animar);
}

animar();

// ── Iniciar animación y sonido al hacer clic ──────
function iniciarIntro() {
  const pantalla = document.getElementById('pantalla-inicio');
  if (pantalla) pantalla.style.display = 'none';

  // Fases
  setTimeout(() => { fase = 'colapso'; }, 1500);
  setTimeout(() => { fase = 'impacto'; }, 2500);

  // Sonido en el momento del impacto
  setTimeout(() => {
    const audio = document.getElementById('impacto');
    if (audio) {
      audio.volume = 0.7;
      audio.play();
    }
    document.body.classList.add('shake');
  }, 2500);

  // Redirigir al home después de 4 segundos
  setTimeout(() => {
    window.location.href = '/home';
  }, 4000);
}

// ── Responsivo ────────────────────────────────────
window.addEventListener('resize', () => {
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
});