\# 🎬 StreamDB - Plataforma de Streaming "PELISXMAX"



Plataforma de streaming estilo Netflix desarrollada como proyecto académico.

Combina una arquitectura de datos híbrida con SQL Server (datos relacionales) y MongoDB (datos flexibles),

expuesta mediante una API REST construida con Flask y containerizada con Docker.



\## 📸 Capturas



\### Pantalla de Inicio

!\[Intro](screenshots/intro.png)



\### Catálogo de Películas

!\[Catálogo](screenshots/catalogo.png)



\### Registro de Usuario

!\[Registro](screenshots/registro.png)



\## 🛠️ Tecnologías utilizadas



| Capa | Tecnología |

|------|-----------|

| Backend | Python 3.14, Flask 3.1 |

| Base de datos relacional | SQL Server 2025 (Star Schema) |

| Base de datos NoSQL | MongoDB |

| Containerización | Docker, Docker Compose |

| Análisis de datos | Power BI |

| Panel administrativo | Excel con VBA y macros |



\## 🗄️ Arquitectura de base de datos



\*\*SQL Server\*\* maneja el modelo dimensional (Star Schema):

\- `DimPelicula`, `DimUsuario`, `DimPlan`, `DimCalendario`, `DimDispositivo`, `DimTipoEvento`

\- `FactSuscripcion`, `FacEventos`



\*\*MongoDB\*\* maneja datos flexibles y de alto volumen:

\- `historial\_reproducciones`, `reseñas`, `preferencias\_usuario`

\- `logs`, `dispositivos`, `eventos\_streaming`



\## 🚀 Instalación y uso



\### Requisitos previos

\- Docker Desktop instalado

\- Git instalado



\### Pasos



1\. Clonar el repositorio:

\\```

git clone https://github.com/Julien009/StreamDB.git

cd StreamDB

\\```



2\. Levantar los contenedores:

\\```

docker-compose up --build

\\```



3\. Abrir en el navegador:

\\```

http://localhost:5000

\\```



\### Nota sobre el video

La plataforma usa un video de muestra para todas las películas del catálogo.

Coloca cualquier archivo `.mp4` en `static/video/` con el nombre `big\_buck\_bunny.mp4`

o actualiza el nombre directamente en `templates/home.html`.



\## 👥 Autores



\- \*\*Walter Garcia\*\* - Desarrollo principal
\- \*\*Katherine Muñoz\*\* - Desarrollo principal

 - Big Data y Data Science

