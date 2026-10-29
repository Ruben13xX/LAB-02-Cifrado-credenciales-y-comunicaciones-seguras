# LAB-02 — Cifrado, credenciales y comunicaciones seguras

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## 1. Introducción
Tener roles y permisos bien configurados no basta: si las contraseñas están en texto claro, los datos sensibles sin cifrar, las claves dentro de scripts, las conexiones sin validar o los respaldos sin protección, la información se puede exponer igual. En esta práctica trabajé tres frentes con PostgreSQL: **credenciales** (hash), **datos sensibles** (cifrado con `pgcrypto`) y **comunicaciones** (TLS), además de la **gestión de claves**.

## 2. Protección de credenciales
- **Texto claro:** la contraseña se guarda tal cual (`usuarios_insegura`); quien lee la tabla la ve.
- **Hash:** transformación unidireccional con sal aleatoria (`crypt()` + `gen_salt('bf')`). No se puede revertir; se verifica recalculando y comparando. Dos hashes de la misma contraseña salen distintos por la sal.
- **Cifrado:** transformación reversible con una clave (`pgp_sym_encrypt` / `pgp_sym_decrypt`). Sirve para datos que hay que recuperar, no para contraseñas.

Detalle y salidas en `evidencias/01-credenciales.md`.

## 3. Protección de datos sensibles
Cifré el **RFC** de los clientes con `pgp_sym_encrypt`, porque es un identificador fiscal que no debería quedar legible para quien consulte la tabla. Se recupera con `pgp_sym_decrypt` y la clave correcta; con otra clave sale `Wrong key or corrupt data`. Detalle en `evidencias/02-cifrado-datos.md`.

## 4. TLS
TLS protege los datos **en tránsito** (confidencialidad, integridad y autenticación del servidor). Verifiqué en PostgreSQL con `SHOW ssl`, `SHOW ssl_min_protocol_version` y `pg_stat_ssl` que la sesión usa **TLSv1.3** con `TLS_AES_256_GCM_SHA384`, y probé `disable`, `require`, `verify-ca` y `verify-full` (incluyendo casos que fallan). Detalle en `evidencias/04-tls.md`.

## 5. Gestión de claves
Las claves no deben guardarse junto con los scripts ni en Git: quedan en el historial, en clones y en respaldos, y quien las obtenga puede descifrar todo. En la práctica vi además que la clave puesta en la consulta se puede leer en `pg_stat_activity`. Deben vivir en un gestor de claves, con acceso mínimo y rotación. Ver `evidencias/03-gestion-claves.md` y `evidencias/10-politica-claves.md`.

## 6. Resultados
| Actividad | Resultado |
|---|---|
| 1. Credenciales | Contraseña en claro visible; con `crypt()` solo se guarda el hash; verificación correcta = `t`, incorrecta = `f` |
| 2. Cifrado | RFC cifrado en `BYTEA`; se recupera con la clave; clave incorrecta da error |
| 3. Claves | Archivo de mala práctica creado, ejecutado y **eliminado** antes de la entrega |
| 4 y 5. TLS | `ssl = t`, TLSv1.3, `TLS_AES_256_GCM_SHA384` con `require`/`verify-*`; `disable` conecta sin TLS |
| 6. `verify-full` | Funciona con `localhost`; falla con `127.0.0.1` por no coincidir el nombre |
| 7. Comparación | Tabla en `evidencias/07-comparacion.md` |
| 8. Escenario | Análisis en `evidencias/08-analisis-escenario.md` |
| 9. Revisión de secretos | `evidencias/09-revision-secretos.md` (extra) |
| 10. Política de claves | 8 reglas en `evidencias/10-politica-claves.md` |

## 7. Problemas encontrados
- **`SHOW ssl_min_protocol_version` con permission denied:** con un usuario normal no se puede ver (hace falta `pg_read_all_settings`); lo ejecuté con el administrador.
- **`verify-ca` sin certificado de la CA falla:** el cliente pide `sslrootcert` o `~/.postgresql/root.crt`.
- **`verify-full` con IP falla:** el certificado era para `localhost` y no para `127.0.0.1`.
- **`sslmode=disable` sí conecta:** `SHOW ssl = on` solo dice que el servidor soporta TLS; no obliga a usarlo (eso se haría con `hostssl` en `pg_hba.conf`; no lo configuré).
- **Costo bajo de bcrypt por defecto:** `gen_salt('bf')` usa costo 06; con `gen_salt('bf', 12)` es más costoso de atacar.
- **Entorno:** el TLS lo probé en un PostgreSQL local con una CA de laboratorio que generé con `openssl`. No es un servidor de producción ni uso el dominio del curso; si en tu entorno cambia el host o el certificado, vuelve a correr los comandos y captura tu propia salida.

## 8. Conclusiones
Aprendí que cada mecanismo resuelve un problema distinto: hash para credenciales, cifrado para datos que se deben recuperar, TLS para el tránsito y gestión de claves para que todo lo anterior sirva. En producción aplicaría: contraseñas con Argon2id/bcrypt desde la aplicación, cifrado de datos sensibles con claves en un KMS, TLS con `verify-full` y `hostssl` obligatorio, respaldos cifrados, revisión de secretos antes de cada commit y mínimo privilegio.

---

## 9. Preguntas de reflexión

1. **¿Por qué una contraseña no debe almacenarse como texto claro?** Porque cualquier lectura de la tabla, un respaldo o un log entrega la credencial lista para usarse, y como se reutiliza en otros servicios el daño se extiende.
2. **¿Por qué un hash no es equivalente a un cifrado?** El hash es unidireccional y no usa una clave para revertirse; el cifrado es reversible con la clave. Con el hash solo se verifica; con el cifrado se recupera el dato.
3. **¿Por qué el cifrado de una columna no sustituye al control de acceso?** Porque quien tiene la clave, como la aplicación, obtiene el dato completo, y el cifrado no decide quién puede consultar, modificar o borrar. Son capas que se complementan.
4. **¿Por qué TLS no sustituye a la autorización de PostgreSQL?** TLS protege el canal, pero un usuario que ya está autenticado puede ver lo que sus privilegios permitan. TLS no decide quién puede qué.
5. **¿Qué ocurriría si se pierde la clave de cifrado?** Los datos cifrados quedan irrecuperables (se pierde la disponibilidad). Por eso hay que respaldar las claves de forma segura y por separado.
6. **¿Y si la clave se publica en GitLab?** Se considera comprometida: quien obtenga los datos cifrados puede descifrarlos, y sigue en el historial y en las copias. Hay que revocarla, rotarla, volver a cifrar y limpiar lo posible, como incidente.
7. **¿Por qué un repositorio privado no es un almacén de secretos?** Porque tiene muchos miembros, clones, forks, CI y respaldos con acceso; el historial es permanente; y no está pensado para rotar, auditar ni controlar el uso de secretos. Reduce la exposición, pero no la elimina.
8. **¿Diferencia entre proteger información almacenada y en transmisión?** Lo almacenado se protege con cifrado de datos, de columnas o de respaldos; la transmisión se protege con TLS. Uno no cubre al otro.
9. **¿Por qué la gestión de claves es tan importante como el algoritmo?** Porque un algoritmo fuerte no sirve si la clave se expone, se pierde o nunca se rota: la seguridad real depende del secreto.
10. **¿Qué mecanismo adicional pondría para proteger los respaldos?** Cifrar cada respaldo (por ejemplo con `gpg` o `age`, o cifrado del almacenamiento) con claves guardadas aparte, almacenarlos con acceso restringido, retención definida y pruebas de restauración.

## 10. Verificación final (sección 18)
- **Credenciales: ¿cifrar o derivación de claves?** Derivación de claves para contraseñas (hash con sal y costo), no cifrado reversible.
- **Datos sensibles: ¿diferencia entre enmascaramiento, seudonimización y cifrado?** El enmascaramiento oculta la visualización del dato; la seudonimización sustituye el identificador por un token y guarda aparte cómo revertirlo; el cifrado transforma el dato para que solo se lea con la clave.
- **Comunicaciones: ¿qué problema resuelve TLS?** Protege la comunicación cliente-servidor: confidencialidad, integridad y autenticación del servidor.
- **Claves: ¿dónde se almacena una clave en un entorno real?** En un gestor de secretos o de claves (KMS, Vault o HSM), separada de los datos y del código.
- **Repositorio: ¿es correcto subir una contraseña o clave real a GitLab aunque sea privado?** **No.** Un repositorio privado reduce la exposición, pero no convierte un secreto en información apropiada para almacenar dentro del código.