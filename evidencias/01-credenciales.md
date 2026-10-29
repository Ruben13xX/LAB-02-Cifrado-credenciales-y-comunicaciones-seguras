# Evidencia 01 — Protección de credenciales

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Comprobar por qué no se deben guardar contraseñas en texto claro y cómo guardar solo un hash con sal usando `pgcrypto`.

## Comando o procedimiento
Script `sql/01-credenciales.sql`, ejecutado con `psql -e` (muestra cada consulta junto con su resultado). Contraseña y usuario son ficticios.

## Resultado obtenido
```text
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY, nombre VARCHAR(120) NOT NULL, correo VARCHAR(150) NOT NULL,
  telefono VARCHAR(20), rfc VARCHAR(13), edad INTEGER, ciudad VARCHAR(80),
  codigo_postal VARCHAR(10), fecha_alta DATE DEFAULT CURRENT_DATE);
CREATE TABLE
                                       Table "public.clientes"
    Column     |          Type          | Collation | Nullable |               Default                
---------------+------------------------+-----------+----------+--------------------------------------
 id            | bigint                 |           | not null | nextval('clientes_id_seq'::regclass)
 nombre        | character varying(120) |           | not null | 
 correo        | character varying(150) |           | not null | 
 telefono      | character varying(20)  |           |          | 
 rfc           | character varying(13)  |           |          | 
 edad          | integer                |           |          | 
 ciudad        | character varying(80)  |           |          | 
 codigo_postal | character varying(10)  |           |          | 
 fecha_alta    | date                   |           |          | CURRENT_DATE
Indexes:
    "clientes_pkey" PRIMARY KEY, btree (id)

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION
SELECT extname FROM pg_extension WHERE extname = 'pgcrypto';
 extname  
----------
 pgcrypto
(1 row)

CREATE TABLE usuarios_insegura (
  id BIGSERIAL PRIMARY KEY, usuario VARCHAR(50) NOT NULL, password VARCHAR(100) NOT NULL);
CREATE TABLE
INSERT INTO usuarios_insegura (usuario, password) VALUES ('juan', 'Password123');
INSERT 0 1
SELECT * FROM usuarios_insegura;
 id | usuario |  password   
----+---------+-------------
  1 | juan    | Password123
(1 row)

--- crypt() 1ra vez ---
SELECT crypt('Password123', gen_salt('bf'));
                            crypt                             
--------------------------------------------------------------
 $2a$06$10X6S.vy6hmqQ9tBynmQlOqlSUgiBIaVwoQf.UwqvV6sA3ez62KYK
(1 row)

--- crypt() 2da vez (misma contraseña) ---
SELECT crypt('Password123', gen_salt('bf'));
                            crypt                             
--------------------------------------------------------------
 $2a$06$zSnANSHRjx2OGJKQy3AiXuZeao8G7GWN2PIJbbCSQTP8ThK8ukIUO
(1 row)

--- gen_salt(bf) por defecto vs con costo 12 ---
SELECT gen_salt('bf') AS salt_default, gen_salt('bf', 12) AS salt_costo_12;
         salt_default          |         salt_costo_12         
-------------------------------+-------------------------------
 $2a$06$wO3nTZ2Oq2WiISMoeZgexu | $2a$12$Z.W1iKCEh9ckeBjfOud.eO
(1 row)

CREATE TABLE usuarios_segura (
  id BIGSERIAL PRIMARY KEY, usuario VARCHAR(50) UNIQUE NOT NULL, password_hash TEXT NOT NULL);
CREATE TABLE
INSERT INTO usuarios_segura (usuario, password_hash)
VALUES ('juan', crypt('Password123', gen_salt('bf')));
INSERT 0 1
SELECT * FROM usuarios_segura;
 id | usuario |                        password_hash                         
----+---------+--------------------------------------------------------------
  1 | juan    | $2a$06$RbecIEnjdzlnrNRvFBYXdeMsDVTAJrUDh34Xlj4iw2dYUMQhxplj2
(1 row)

--- contraseña correcta ---
SELECT usuario, password_hash = crypt('Password123', password_hash) AS contraseña_correcta
FROM usuarios_segura WHERE usuario = 'juan';
 usuario | contraseña_correcta 
---------+---------------------
 juan    | t
(1 row)

--- contraseña incorrecta ---
SELECT usuario, password_hash = crypt('OtraPassword', password_hash) AS contraseña_correcta
FROM usuarios_segura WHERE usuario = 'juan';
 usuario | contraseña_correcta 
---------+---------------------
 juan    | f
(1 row)
```

## Análisis

**7.1 ¿Qué ocurriría si alguien obtiene acceso de lectura a `usuarios_insegura`?**
Vería `Password123` tal cual en la columna `password`. Con un simple `SELECT` ya tiene la credencial lista para usarla (y como mucha gente reutiliza contraseñas, probablemente también en otros servicios). Una filtración de la base de datos, de un respaldo o de un log sería directamente una filtración de contraseñas.

**7.3 Preguntas sobre `crypt()` y `gen_salt()`**
1. **¿Son iguales?** No. Mismo texto (`Password123`), pero salieron `$2a$06$10X6S...` y `$2a$06$zSnAN...`.
2. **¿Por qué no?** Porque `gen_salt('bf')` genera una sal aleatoria nueva en cada llamada y esa sal se mezcla con la contraseña antes de calcular el hash.
3. **¿Qué hace `gen_salt()`?** Genera la sal aleatoria e indica el algoritmo (`bf` = Blowfish/bcrypt) y su costo. En el resultado se ve en el prefijo: `$2a$` es bcrypt y `06` es el costo.
4. **¿Qué hace `crypt()`?** Calcula el hash de la contraseña usando la sal que recibe. Al verificar se le pasa el hash guardado como segundo argumento, porque ahí va incluida la sal.
5. **¿Es cifrado reversible?** No. Es un hash unidireccional: no existe una función para recuperar la contraseña original, solo se puede volver a calcular y comparar.

**7.5 Verificación**
1. Con la contraseña correcta salió `t` (true).
2. Con la incorrecta salió `f` (false).
3. No hace falta recuperar la original porque basta con volver a calcular el hash con la misma sal y compararlo con el guardado.
4. El hash no se debe confundir con cifrado porque el cifrado se puede revertir con la clave y el hash no.

## Conclusión
La tabla `usuarios_insegura` expone la credencial; `usuarios_segura` solo guarda el hash con sal y aun así permite verificar el login. Las contraseñas se protegen con derivación/hash, no con cifrado reversible.
