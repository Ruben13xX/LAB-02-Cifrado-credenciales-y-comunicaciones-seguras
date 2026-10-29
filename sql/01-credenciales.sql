-- LAB-02 | Preparación + Actividad 1: Protección de credenciales
-- Motor: PostgreSQL 16 | 

-- 6. Preparación
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY, nombre VARCHAR(120) NOT NULL, correo VARCHAR(150) NOT NULL,
  telefono VARCHAR(20), rfc VARCHAR(13), edad INTEGER, ciudad VARCHAR(80),
  codigo_postal VARCHAR(10), fecha_alta DATE DEFAULT CURRENT_DATE);
\d clientes
CREATE EXTENSION IF NOT EXISTS pgcrypto;
SELECT extname FROM pg_extension WHERE extname = 'pgcrypto';

-- 7.1 Implementación INCORRECTA
CREATE TABLE usuarios_insegura (
  id BIGSERIAL PRIMARY KEY, usuario VARCHAR(50) NOT NULL, password VARCHAR(100) NOT NULL);
INSERT INTO usuarios_insegura (usuario, password) VALUES ('juan', 'Password123');
SELECT * FROM usuarios_insegura;

-- 7.3 Representación no reversible con crypt() + gen_salt('bf')
\echo '--- crypt() 1ra vez ---'
SELECT crypt('Password123', gen_salt('bf'));
\echo '--- crypt() 2da vez (misma contraseña) ---'
SELECT crypt('Password123', gen_salt('bf'));

-- Observación extra: costo (iteraciones) del salt. El default de 'bf' es bajo (06)
\echo '--- gen_salt(bf) por defecto vs con costo 12 ---'
SELECT gen_salt('bf') AS salt_default, gen_salt('bf', 12) AS salt_costo_12;

-- 7.4 Tabla con credenciales protegidas
CREATE TABLE usuarios_segura (
  id BIGSERIAL PRIMARY KEY, usuario VARCHAR(50) UNIQUE NOT NULL, password_hash TEXT NOT NULL);
INSERT INTO usuarios_segura (usuario, password_hash)
VALUES ('juan', crypt('Password123', gen_salt('bf')));
SELECT * FROM usuarios_segura;

-- 7.5 Verificación de contraseña
\echo '--- contraseña correcta ---'
SELECT usuario, password_hash = crypt('Password123', password_hash) AS contraseña_correcta
FROM usuarios_segura WHERE usuario = 'juan';
\echo '--- contraseña incorrecta ---'
SELECT usuario, password_hash = crypt('OtraPassword', password_hash) AS contraseña_correcta
FROM usuarios_segura WHERE usuario = 'juan';
