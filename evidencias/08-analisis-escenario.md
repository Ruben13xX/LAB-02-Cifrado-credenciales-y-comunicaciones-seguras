# Evidencia 08 — Análisis de un escenario de seguridad

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Analizar una base con roles bien configurados pero con varias fallas criptográficas y de manejo de secretos.

## Procedimiento
Análisis del escenario de la Actividad 8 con lo visto en el laboratorio.

## Respuestas

**Pregunta 1 — ¿Cuáles son los principales riesgos?**
- **Contraseñas en texto claro:** cualquier lectura (SQL, respaldo, log) entrega credenciales utilizables, y mucha gente las reutiliza en otros sitios.
- **RFC en texto claro:** identificador fiscal expuesto, riesgo de suplantación y de cruce con otras fuentes.
- **Conexiones sin validación del servidor:** se puede cifrar el tráfico y aun así hablar con un servidor falso (ataque de intermediario), porque no se verifica la identidad.
- **Claves criptográficas en archivos SQL:** quien vea el script o el repositorio puede descifrar los datos protegidos; además quedan en el historial de Git.
- **Respaldos sin protección:** un archivo robado o mal compartido expone todo sin pasar por roles ni permisos.
- **Información financiera y datos personales (nombre, correo):** el escenario no dice cómo se protegen, así que habría que clasificarlos y definir controles.

**Pregunta 2 — ¿Qué mecanismo usaría para cada elemento?**

| Elemento | Mecanismo |
|---|---|
| Nombre, correo | Control de acceso, y enmascaramiento/seudonimización según el área (LAB-01) |
| Contraseña | Hash con Argon2id/scrypt/bcrypt (con costo adecuado) |
| RFC | Cifrado, con clave en gestor de claves y acceso restringido |
| Información financiera | Cifrado, mínimo privilegio y auditoría de accesos |
| Claves criptográficas | Gestión de claves (KMS/Vault/HSM), fuera de scripts y repositorios, con rotación |
| Conexiones | TLS con `verify-full` y, en el servidor, `hostssl` en `pg_hba.conf` |
| Respaldos | Cifrado del respaldo, almacenamiento con acceso restringido y pruebas de restauración |

**Pregunta 3 — ¿Cuál es el más crítico y por qué?**
Para mí, las **claves en archivos SQL**. Es una falla de raíz: si la clave está expuesta, todo lo que se cifró con ella queda recuperable, y además ya pudo copiarse a clones e historial, así que no se arregla borrando una línea. Las contraseñas en texto claro también son gravísimas y podrían discutirse como igual de críticas, porque no requieren ni una clave; pero aquí la falla anula una protección que se supone que ya existía.

**Pregunta 4 — ¿Tener bien usuarios y permisos elimina estos riesgos?**
No. Los roles controlan quién puede consultar *a través de PostgreSQL*, pero no protegen un respaldo robado, el tráfico en la red, un script con una clave, ni el contenido de las tablas si alguien llega al disco o al respaldo. Hace falta defensa en capas: control de acceso, cifrado, TLS, gestión de claves y manejo seguro de secretos.

## Conclusión
Los permisos son necesarios, pero no suficientes: cada riesgo del escenario necesita su propio control.
