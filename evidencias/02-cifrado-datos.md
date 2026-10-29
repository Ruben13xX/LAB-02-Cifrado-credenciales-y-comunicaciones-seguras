# Evidencia 02 — Cifrado de información sensible (RFC)

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Proteger el RFC con cifrado simétrico (`pgp_sym_encrypt`), recuperarlo con la clave correcta y observar qué pasa con una clave incorrecta.

## Comando o procedimiento
Script `sql/02-cifrado-datos.sql`. Clave y RFC son ficticios (`CLAVE-DE-PRUEBA`, `LOPA900101ABC`).

## Resultado obtenido
```text
CREATE TABLE clientes_protegidos (
  id BIGSERIAL PRIMARY KEY, nombre VARCHAR(120) NOT NULL, rfc_cifrado BYTEA NOT NULL);
CREATE TABLE
INSERT INTO clientes_protegidos (nombre, rfc_cifrado)
VALUES ('Ana López', pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA'));
INSERT 0 1
--- el RFC ya no aparece en claro ---
SELECT * FROM clientes_protegidos;
 id |  nombre   |                                                                           rfc_cifrado                                                                            
----+-----------+------------------------------------------------------------------------------------------------------------------------------------------------------------------
  1 | Ana López | \xc30d0407030230ff26e52db650f46ad23e0178e7e20564e6f7c25c4b52273336f35f463c6f309e5ac7c36addd92423cb87dd95d12039ba36f41942bf0a1c11ab65f4a1f3f5e3090ebbe276ff07ed15
(1 row)

--- 8.2 recuperar el dato con la clave correcta ---
SELECT id, nombre, pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc FROM clientes_protegidos;
 id |  nombre   |      rfc      
----+-----------+---------------
  1 | Ana López | LOPA900101ABC
(1 row)

--- clave incorrecta (debe fallar) ---
SELECT id, pgp_sym_decrypt(rfc_cifrado, 'OTRA-CLAVE') FROM clientes_protegidos;
psql:sql/02-cifrado-datos.sql:17: ERROR:  Wrong key or corrupt data
--- cifrar dos veces lo mismo da resultados distintos? ---
SELECT pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA') = pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA') AS son_iguales;
 son_iguales 
-------------
 f
(1 row)

--- la clave viaja en el texto de la consulta: se ve en pg_stat_activity ---
SELECT pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc,
       (SELECT query FROM pg_stat_activity WHERE pid = pg_backend_pid()) AS consulta_visible_en_el_servidor
FROM clientes_protegidos;
      rfc      |                                       consulta_visible_en_el_servidor                                       
---------------+-------------------------------------------------------------------------------------------------------------
 LOPA900101ABC | SELECT pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc,                                             +
               |        (SELECT query FROM pg_stat_activity WHERE pid = pg_backend_pid()) AS consulta_visible_en_el_servidor+
               | FROM clientes_protegidos;
(1 row)
```

## Análisis

1. **¿Diferencia entre `crypt()` y `pgp_sym_encrypt()`?** `crypt()` genera un hash unidireccional para *verificar* contraseñas. `pgp_sym_encrypt()` cifra con una clave para poder *recuperar* el dato original después.
2. **¿Cuál permite recuperar el dato?** `pgp_sym_encrypt()` (con `pgp_sym_decrypt()` y la clave correcta).
3. **¿Qué pasa con clave incorrecta?** PostgreSQL responde `ERROR: Wrong key or corrupt data`, no devuelve nada del dato.
4. **¿Qué problema hay con poner la clave en la consulta?** La clave queda escrita en el SQL: en el script, en el historial del cliente, en los logs del servidor y en el repositorio si se sube. Lo comprobé: en la última consulta el texto completo, con `CLAVE-DE-PRUEBA`, aparece en `pg_stat_activity`, o sea que cualquier rol que pueda ver esa vista (o los logs) puede leer la clave.

## Conclusión
El RFC cifrado en la tabla ya no se puede leer a simple vista y solo se recupera con la clave. Pero la seguridad ahora depende de dónde y cómo se guarda esa clave (siguiente evidencia).
