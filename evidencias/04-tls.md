# Evidencia 04 — TLS en PostgreSQL

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Verificar el estado real de TLS en PostgreSQL, comprobar si una sesión usa TLS y entender las diferencias entre `sslmode=disable`, `require`, `verify-ca` y `verify-full`.

## Entorno
PostgreSQL 16.15 en mi máquina de laboratorio (`localhost`, puerto 5432). Para poder probar `verify-ca` y `verify-full` generé con `openssl` una **CA de laboratorio** y un certificado de servidor con nombre `localhost`, y los configuré con `ssl_cert_file` y `ssl_key_file`. Es un entorno de práctica, no producción. La contraseña del usuario de pruebas va en la variable `PGPASSWORD` (no aparece en ningún archivo del repo).

## Comando o procedimiento
Como administrador (socket local), para ver la configuración del servidor:
```text
SHOW ssl;
 ssl 
-----
 on
(1 row)

SHOW ssl_min_protocol_version;
 ssl_min_protocol_version 
--------------------------
 TLSv1.2
(1 row)

SHOW port;
 port 
------
 5432
(1 row)

SHOW listen_addresses;
 listen_addresses 
------------------
 localhost
(1 row)

```

Como usuario normal (`lab02_user`) por TCP con `sql/03-verificacion-tls.sql`, repetido con cada `sslmode`:
```text
##### A) sslmode=disable
$ psql "host=localhost port=5432 dbname=lab02 user=lab02_user sslmode=disable" -f sql/03-verificacion-tls.sql
 ssl 
-----
 on
(1 row)

psql:sql/03-verificacion-tls.sql:3: ERROR:  permission denied to examine "ssl_min_protocol_version"
DETAIL:  Only roles with privileges of the "pg_read_all_settings" role may examine this parameter.
 port 
------
 5432
(1 row)

 listen_addresses 
------------------
 localhost
(1 row)

 inet_client_addr | inet_client_port 
------------------+------------------
 127.0.0.1        |            47468
(1 row)

 ssl | version | cipher 
-----+---------+--------
 f   |         | 
(1 row)


##### B) sslmode=require
$ psql "host=localhost port=5432 dbname=lab02 user=lab02_user sslmode=require" -f sql/03-verificacion-tls.sql
 ssl 
-----
 on
(1 row)

psql:sql/03-verificacion-tls.sql:3: ERROR:  permission denied to examine "ssl_min_protocol_version"
DETAIL:  Only roles with privileges of the "pg_read_all_settings" role may examine this parameter.
 port 
------
 5432
(1 row)

 listen_addresses 
------------------
 localhost
(1 row)

 inet_client_addr | inet_client_port 
------------------+------------------
 127.0.0.1        |            47478
(1 row)

 ssl | version |         cipher         
-----+---------+------------------------
 t   | TLSv1.3 | TLS_AES_256_GCM_SHA384
(1 row)


##### C) sslmode=verify-ca SIN certificado de la CA (debe fallar)
$ psql "host=localhost port=5432 dbname=lab02 user=lab02_user sslmode=verify-ca"
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: root certificate file "~/.postgresql/root.crt" does not exist
Either provide the file, use the system's trusted roots with sslrootcert=system, or change sslmode to disable server certificate verification.

##### D) sslmode=verify-ca con sslrootcert=ca.crt
$ psql "host=localhost port=5432 dbname=lab02 user=lab02_user sslmode=verify-ca sslrootcert=ca.crt"
t|TLSv1.3|TLS_AES_256_GCM_SHA384

##### E) sslmode=verify-full, host=localhost (coincide con el certificado)
$ psql "host=localhost port=5432 dbname=lab02 user=lab02_user sslmode=verify-full sslrootcert=ca.crt"
t|TLSv1.3|TLS_AES_256_GCM_SHA384

##### F) sslmode=verify-full, host=127.0.0.1 (NO coincide con el nombre del certificado; debe fallar)
$ psql "host=127.0.0.1 port=5432 dbname=lab02 user=lab02_user sslmode=verify-full sslrootcert=ca.crt"
psql: error: connection to server at "127.0.0.1", port 5432 failed: server certificate for "localhost" (and 1 other name) does not match host name "127.0.0.1"

##### G) sslmode=require con host=127.0.0.1 (cifra, pero NO valida identidad)
t|TLSv1.3|TLS_AES_256_GCM_SHA384
##### H) Certificado del servidor (resumen)
  subject=CN = localhost
  issuer=CN = CA Laboratorio LAB-02
  X509v3 Subject Alternative Name: 
      DNS:localhost
```

## Resultado y análisis

**Preguntas de la Actividad 5**
1. **¿La conexión actual usa TLS?** Con `sslmode=require` (y también con `verify-ca` y `verify-full`): sí, `ssl = t`. Con `sslmode=disable`: no, `ssl = f`.
2. **¿Versión de TLS?** TLSv1.3.
3. **¿Algoritmo de cifrado?** `TLS_AES_256_GCM_SHA384`.
4. **¿Diferencia entre conexión con TLS y sin TLS?** Sin TLS, consultas y resultados viajan legibles y modificables para quien observe la red. Con TLS el tráfico va cifrado, con integridad y (con certificado validado) con verificación de a qué servidor te conectas.

**Resumen de los `sslmode` probados**

| Prueba | Resultado | Qué demuestra |
|---|---|---|
| `disable` | Conecta, `ssl = f` | El servidor **acepta** conexiones sin TLS: `SHOW ssl = on` no significa que todas las sesiones lo usen |
| `require` | Conecta, TLSv1.3 | Cifra, pero no verifica certificado ni nombre |
| `verify-ca` sin CA | Falla: no existe `root.crt` | Para validar hay que dar la CA en la que se confía |
| `verify-ca` con `sslrootcert` | Conecta, TLSv1.3 | Valida que el certificado lo firmó la CA |
| `verify-full` con `localhost` | Conecta, TLSv1.3 | Valida CA **y** que el nombre coincide |
| `verify-full` con `127.0.0.1` | Falla: el certificado es de `localhost` y no coincide con `127.0.0.1` | Aunque el certificado sea válido, si el nombre no coincide no se confía |
| `require` con `127.0.0.1` | Conecta | `require` no detecta que el nombre no coincide |

## Conclusión
TLS protege los datos en tránsito, pero solo `verify-full` (o `verify-ca` con cuidado) verifica con quién me estoy conectando. `require` cifra, pero no evita conectarme a un servidor falso. TLS tampoco reemplaza la autorización de PostgreSQL (roles y permisos).
