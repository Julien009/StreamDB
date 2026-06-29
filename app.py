from flask import Flask, jsonify, request, render_template
from pymongo import MongoClient
import pymssql

app = Flask(__name__)

# ── Conexión SQL Server ───────────────────────────
def conectar_sql():
    conn = pymssql.connect(
        server='192.168.1.4',
        database='PELICULAS_SERIES',
        user='streamdb_user',
        password='StreamDB2026!',
        port=1433
    )
    return conn

# ── Conexión MongoDB ──────────────────────────────
def conectar_mongo():
    import os
    MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://host.docker.internal:27017/')
    client = MongoClient(MONGO_URI)
    return client['StreamDB']
# ── Rutas principales ─────────────────────────────
@app.route('/')
def inicio():
    return render_template('intro.html')

@app.route('/intro')
def intro():
    return render_template('intro.html')

@app.route('/home')
def home():
    return render_template('home.html')

# ══════════════════════════════════════════════════
# RUTAS SQL SERVER
# ══════════════════════════════════════════════════

@app.route('/peliculas')
def peliculas():
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM DimPelicula')
    cols   = [col[0] for col in cursor.description]
    datos  = [dict(zip(cols, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(datos)

@app.route('/peliculas/<int:id>')
def pelicula_por_id(id):
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM DimPelicula WHERE idPelicula = ?', id)
    cols   = [col[0] for col in cursor.description]
    fila   = cursor.fetchone()
    conn.close()
    if fila:
        return jsonify(dict(zip(cols, fila)))
    return jsonify({'error': 'Película no encontrada'}), 404

@app.route('/peliculas/genero/<string:genero>')
def peliculas_por_genero(genero):
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM DimPelicula WHERE Genero = ?', genero)
    cols   = [col[0] for col in cursor.description]
    datos  = [dict(zip(cols, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(datos)

@app.route('/usuarios')
def usuarios():
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM DimUsuario')
    cols   = [col[0] for col in cursor.description]
    datos  = [dict(zip(cols, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(datos)

@app.route('/planes')
def planes():
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM DimPlan')
    cols   = [col[0] for col in cursor.description]
    datos  = [dict(zip(cols, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(datos)

@app.route('/suscripciones')
def suscripciones():
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM FactSuscripcion')
    cols   = [col[0] for col in cursor.description]
    datos  = [dict(zip(cols, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(datos)

@app.route('/eventos')
def eventos():
    conn   = conectar_sql()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM FacEventos')
    cols   = [col[0] for col in cursor.description]
    datos  = [dict(zip(cols, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(datos)

# ══════════════════════════════════════════════════
# RUTAS MONGODB
# ══════════════════════════════════════════════════

@app.route('/resenas')
def resenas():
    db    = conectar_mongo()
    datos = list(db.resenas.find({}, {'_id': 0}))
    return jsonify(datos)

@app.route('/resenas/add', methods=['POST'])
def agregar_resena():
    db   = conectar_mongo()
    data = request.get_json()
    db.resenas.insert_one(data)
    return jsonify({'mensaje': 'Reseña agregada correctamente'})

@app.route('/historial')
def historial():
    db    = conectar_mongo()
    datos = list(db.historial_busquedas.find({}, {'_id': 0}))
    return jsonify(datos)

@app.route('/historial/add', methods=['POST'])
def agregar_historial():
    db   = conectar_mongo()
    data = request.get_json()
    db.historial_busquedas.insert_one(data)
    return jsonify({'mensaje': 'Búsqueda registrada correctamente'})

@app.route('/preferencias')
def preferencias():
    db    = conectar_mongo()
    datos = list(db.preferencias_usuario.find({}, {'_id': 0}))
    return jsonify(datos)

@app.route('/preferencias/add', methods=['POST'])
def agregar_preferencia():
    db   = conectar_mongo()
    data = request.get_json()
    db.preferencias_usuario.insert_one(data)
    return jsonify({'mensaje': 'Preferencia guardada correctamente'})

@app.route('/reproducir', methods=['POST'])
def reproducir():
    db   = conectar_mongo()
    data = request.get_json()
    evento = {
        'idUsuario'  : data.get('idUsuario'),
        'idPelicula' : data.get('idPelicula'),
        'pelicula'   : data.get('pelicula'),
        'dispositivo': data.get('dispositivo', 'Web'),
        'tipo_evento': 'Reproduccion iniciada',
        'fecha'      : data.get('fecha')
    }
    db.eventos_streaming.insert_one(evento)
    return jsonify({'mensaje': 'Evento registrado en MongoDB ✅'})

@app.route('/reproduccion/iniciar', methods=['POST'])
def iniciar_reproduccion():
    db   = conectar_mongo()
    data = request.get_json()

    # ¿Ya existe sesión activa para este usuario + película?
    sesion = db.historial_reproducciones.find_one({
        'idUsuario'               : data.get('idUsuario'),
        'reproduccion.idPelicula' : data.get('idPelicula'),
        'reproduccion.completada' : False
    })

    if sesion:
        # Sesión pausada existente → solo marcarla como activa
        return jsonify({'mensaje': 'Sesión reanudada ▶️', 'sesion_id': str(sesion['_id'])})
    else:
        # Primera vez → insertar documento nuevo
        from datetime import datetime
        nuevo = {
            'idUsuario' : data.get('idUsuario'),
            'usuario'   : data.get('usuario'),
            'fecha'     : datetime.now().strftime('%Y-%m-%d'),
            'reproduccion': {
                'idPelicula'    : data.get('idPelicula'),
                'pelicula'      : data.get('pelicula'),
                'genero'        : data.get('genero', ''),
                'duracion_min'  : data.get('duracion_min', 0),
                'minuto_pausado': 0,
                'completada'    : False,
                'calidad'       : data.get('calidad', '1080p')
            }
        }
        resultado = db.historial_reproducciones.insert_one(nuevo)
        return jsonify({'mensaje': 'Reproducción iniciada ✅', 'sesion_id': str(resultado.inserted_id)})


@app.route('/reproduccion/actualizar', methods=['POST'])
def actualizar_reproduccion():
    from bson import ObjectId
    db   = conectar_mongo()
    data = request.get_json()

    sesion_id  = data.get('sesion_id')
    minuto     = data.get('minuto', 0)
    completada = data.get('completada', False)

    db.historial_reproducciones.update_one(
        {'_id': ObjectId(sesion_id)},
        {'$set': {
            'reproduccion.minuto_pausado': minuto,
            'reproduccion.completada'    : completada
        }}
    )

    estado = 'Completada ✅' if completada else f'Pausada en minuto {minuto} ⏸️'
    return jsonify({'mensaje': f'Historial actualizado → {estado}'})

@app.route('/dispositivo/registrar', methods=['POST'])
def registrar_dispositivo():
    db   = conectar_mongo()
    data = request.get_json()
    from datetime import datetime

    # Evitar duplicados: si ya existe este dispositivo para el usuario, no insertar
    existe = db.dispositivos.find_one({
        'idUsuario'        : data.get('idUsuario'),
        'codigo_dispositivo': data.get('codigo_dispositivo')
    })

    if existe:
        return jsonify({'mensaje': 'Dispositivo ya registrado', 'dispositivo_id': str(existe['_id'])})

    nuevo = {
        'idUsuario'         : data.get('idUsuario'),
        'codigo_dispositivo': data.get('codigo_dispositivo'),
        'tipo'              : data.get('tipo'),
        'sistema_operativo' : data.get('sistema_operativo'),
        'estado'            : 'activo',
        'fecha_registro'    : datetime.now().strftime('%Y-%m-%d')
    }
    resultado = db.dispositivos.insert_one(nuevo)
    return jsonify({'mensaje': 'Dispositivo registrado ✅', 'dispositivo_id': str(resultado.inserted_id)})

# ══════════════════════════════════════════════════
# RUTAS REGISTRO Y SUSCRIPCION
# ══════════════════════════════════════════════════

@app.route('/registro')
def registro():
    return render_template('registro.html')

@app.route('/registro/add', methods=['POST'])
def agregar_usuario():
    conn   = conectar_sql()
    cursor = conn.cursor()
    data   = request.get_json()

    cursor.execute("SELECT ISNULL(MAX(idUsuario),0)+1 FROM DimUsuario")
    next_id = cursor.fetchone()[0]

    cursor.execute(
        "INSERT INTO DimUsuario (idUsuario,Nombre,ApePat,Correo,Distrito,FecAlta) VALUES (%d,%s,%s,%s,%s,%s)",
        (next_id, data['nombre'], data['apepat'], data['correo'], data['distrito'], data['fechaAlta'])
    )

    conn.commit()
    conn.close()
    return jsonify({'mensaje': 'Usuario registrado', 'idUsuario': next_id})

@app.route('/suscripcion')
def suscripcion():
    return render_template('suscripcion.html')

@app.route('/suscripcion/add', methods=['POST'])
def agregar_suscripcion():
    conn   = conectar_sql()
    cursor = conn.cursor()
    data   = request.get_json()

    cursor.execute("SELECT ISNULL(MAX(idSuscrip),0)+1 FROM FactSuscripcion")
    next_id = cursor.fetchone()[0]

    cursor.execute(
        "SELECT TOP 1 Fecha FROM DimCalendario WHERE Fecha <= %s ORDER BY Fecha DESC",
        (data['fechaSusc'],)
    )
    fila_fecha = cursor.fetchone()

    if not fila_fecha:
        cursor.execute("SELECT TOP 1 Fecha FROM DimCalendario ORDER BY Fecha ASC")
        fila_fecha = cursor.fetchone()

    fecha_valida = fila_fecha[0]

    cursor.execute(
        "INSERT INTO FactSuscripcion (idSuscrip,idUsuario,idPlan,FecSuscrip,FlgEstado,MetodoPago) VALUES (%d,%d,%d,%s,1,%s)",
        (next_id, data['idUsuario'], data['idPlan'], fecha_valida, data['metodoPago'])
    )

    conn.commit()
    conn.close()
    return jsonify({'mensaje': 'Suscripción activada', 'idSuscrip': next_id})

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)