-- LAB-02 | Actividades 2 y 3: Cifrado de datos sensibles (RFC) y problema de las claves

CREATE TABLE clientes_protegidos (
  id BIGSERIAL PRIMARY KEY, nombre VARCHAR(120) NOT NULL, rfc_cifrado BYTEA NOT NULL);

INSERT INTO clientes_protegidos (nombre, rfc_cifrado)
VALUES ('Ana López', pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA'));

\echo '--- el RFC ya no aparece en claro ---'
SELECT * FROM clientes_protegidos;

\echo '--- 8.2 recuperar el dato con la clave correcta ---'
SELECT id, nombre, pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc FROM clientes_protegidos;

\echo '--- clave incorrecta (debe fallar) ---'
SELECT id, pgp_sym_decrypt(rfc_cifrado, 'OTRA-CLAVE') FROM clientes_protegidos;

\echo '--- cifrar dos veces lo mismo da resultados distintos? ---'
SELECT pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA') = pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA') AS son_iguales;

\echo '--- la clave viaja en el texto de la consulta: se ve en pg_stat_activity ---'
SELECT pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc,
       (SELECT query FROM pg_stat_activity WHERE pid = pg_backend_pid()) AS consulta_visible_en_el_servidor
FROM clientes_protegidos;
