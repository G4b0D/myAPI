from flask import Flask, jsonify,request,json
from flask_cors import CORS
import cx_Oracle
import config
app = Flask(__name__)
CORS(app)
@app.route('/clientes', methods=['GET'])
def get_clientes():
    try:
        conn = cx_Oracle.connect( config.username,
        config.password,
        config.dsn,
        encoding=config.encoding)
    except Exception as err:
        print('Error connecting: ',err)
    else:
        try:
            cur = conn.cursor()
            sql = """ SELECT * from tbcliente """
            cur.execute(sql)
            columns = [col[0] for col in cur.description]
            cur.rowfactory = lambda *args: dict(zip(columns, args))
            data = cur.fetchall()
            return jsonify(data)
        except Exception as err:
            print('Error executing, ',err)
        else:
            print("Done.")
        finally:
            cur.close()
    finally:
        conn.close()

@app.route('/cantidad', methods=['GET'])
def get_cantidad():
    carrId = request.args.get('cID',type = int)
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            resul = cur.callfunc('checkinventario',int,[carrId])
        except Exception as err:
            print('Error executing: ',err)
        else:
            return str(resul)
        finally:
            cur.close()
    finally:
        conn.close() 

@app.route('/buscarCliente',methods=['POST'])
def buscarCliente():
    cID = request.json['idCliente']
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            resul = cur.callfunc('consultas.checkCliente',str,[cID])
        except Exception as err:
            print('Error executing: ',err)
        else:
            return str(resul)
        finally:
            cur.close()
    finally:
        conn.close()


@app.route('/obtenerCliente', methods=['POST'])
def obtenerCliente():
    cID = request.json['idCliente']
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            refCursor = conn.cursor()
            cur.callproc("consultas.obtenerCliente", [cID, refCursor])
            columns = [col[0] for col in refCursor.description]
            refCursor.rowfactory = lambda *args: dict(zip(columns, args))
            data = refCursor.fetchall()
            return jsonify(data[0])
        except Exception as err:
            print('Error executing: ',err)
        finally:
            cur.close()
    finally:
        conn.close()


@app.route('/agregarCliente',methods=['POST'])
def agregarCliente():
    cedula = request.json['idCliente']
    nombre = request.json['nombre']
    apellido = request.json['apellido']
    email = request.json['correo']
    telefono = request.json['telefono']
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            cur.callproc('insertar_cliente',(int(cedula),nombre,apellido,email,telefono))
            return 'done'
        except cx_Oracle.DatabaseError as exc:
            error, = exc.args
            return("Oracle-Error-Message:", error.message)
        finally:
            cur.close()
    finally:
        conn.close()    


@app.route('/obtenerInventario',methods=['GET'])
def obtenerInventario():
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            refCursor = conn.cursor()
            cur.callproc("obtenerInventario", [refCursor])
            columns = [col[0] for col in refCursor.description]
            refCursor.rowfactory = lambda *args: dict(zip(columns, args))
            data = refCursor.fetchall()
            return jsonify(data)
        except Exception as err:
            print('Error executing: ',err)
        finally:
            cur.close()
    finally:
        conn.close()


@app.route('/obtenerCarro',methods=['POST'])
def obtenerCarro():
    carrId = request.json['idCarro']
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            refCursor = conn.cursor()
            cur.callproc("obtener_carro", [carrId,refCursor])
            columns = [col[0] for col in refCursor.description]
            refCursor.rowfactory = lambda *args: dict(zip(columns, args))
            data = refCursor.fetchall()
            return jsonify(data)
        except Exception as err:
            print('Error executing: ',err)
        finally:
            cur.close()
    finally:
        conn.close()

@app.route('/reservar',methods=['POST'])
def reservar():
    reservaID = request.json['idReserva']
    idCliente = request.json['idCliente']
    monto = request.json['precio']
    placa = request.json['placa']
    metodoPago = request.json['metodo']
    fechaInicio = request.json['fechaIni']
    fechaFinal = request.json['fechaFin']
    try:
        conn = cx_Oracle.connect(config.username,config.password,config.dsn,encoding = config.encoding)
    except Exception as err:
        print('Error conecting: ',err)
    else:
        try:
            cur = conn.cursor()
            cur.callproc("reservar_carro", (int(reservaID),int(idCliente),int(monto),placa,metodoPago,fechaInicio,fechaFinal))
        except Exception as err:
            print('Error executing: ',err)
        else:
            return 'Done'
        finally:
            cur.close()
    finally:
        conn.close()    

@app.route('/obtenerRentas',methods=['GET'])
def obtenerRentas():
    try:
        conn = cx_Oracle.connect( config.username,
        config.password,
        config.dsn,
        encoding=config.encoding)
    except Exception as err:
        print('Error connecting: ',err)
    else:
        try:
            cur = conn.cursor()
            refCursor = conn.cursor()
            cur.callproc("obtenerReservas", [refCursor])
            columns = [col[0] for col in refCursor.description]
            refCursor.rowfactory = lambda *args: dict(zip(columns, args))
            data = refCursor.fetchall()
            return jsonify(data)
        except Exception as err:
            print('Error executing, ',err)
        else:
            print("Done.")
        finally:
            cur.close()
    finally:
        conn.close()    


@app.route('/liberar',methods=['POST'])
def liberar():
    placa = request.json['placa']
    try:
        conn = cx_Oracle.connect( config.username,
        config.password,
        config.dsn,
        encoding=config.encoding)
    except Exception as err:
        print('Error connecting: ',err)
    else:
        try:
            cur = conn.cursor()
            cur.callproc('liberar_carro',[placa])
            return 'Ok'
        except Exception as err:
            print('Error executing, ',err)
        else:
            print("Done.")
        finally:
            cur.close()
    finally:
        conn.close()


if __name__ == '__main__':
  app.run(debug=True)  