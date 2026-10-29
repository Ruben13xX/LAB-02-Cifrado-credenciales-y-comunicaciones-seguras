# Evidencia 10 — Política mínima de protección de claves

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Definir reglas propias para gestionar claves criptográficas.

## Política (8 reglas)

1. **Generación.** Las claves se generan con generadores criptográficos aleatorios (no con frases inventadas a mano), con la longitud y el algoritmo que defina la organización, y cada propósito usa una clave distinta (por ejemplo, una para RFC y otra para respaldos).
2. **Almacenamiento.** Las claves se guardan en un gestor de secretos o de claves (KMS, Vault o HSM), nunca en tablas junto con los datos que protegen, ni en scripts, archivos de configuración, repositorios o documentos.
3. **Acceso.** Solo las cuentas de servicio y las personas que lo necesitan pueden usar o leer una clave, con mínimo privilegio y registro de cada acceso. Quien administra las claves no debería ser quien consulta los datos de negocio.
4. **Rotación.** Se rotan en un calendario definido y de inmediato si hay sospecha de exposición; al rotar, los datos se vuelven a cifrar con la clave nueva y se conserva la anterior solo el tiempo necesario para descifrar lo pendiente.
5. **Respaldo.** Se respalda cada clave por separado de los respaldos de datos, cifrada y con acceso restringido, y se prueba la recuperación; perder una clave significa perder los datos cifrados.
6. **Revocación.** Existe un procedimiento para desactivar una clave comprometida o de alguien que dejó la organización, y para dejar de usarla en las aplicaciones.
7. **Exposición accidental.** Si una clave aparece en un repositorio, log o captura, se trata como comprometida: se revoca, se rota, se vuelve a cifrar lo necesario, se limpia lo que se pueda del historial y se documenta el incidente. No basta con borrar el archivo.
8. **Eliminación.** Cuando una clave deja de usarse y ya no hay datos que dependan de ella, se destruye de forma segura y se registra la fecha y quién lo autorizó.

## Análisis
Las reglas cubren el ciclo de vida completo (generar, guardar, usar, rotar, respaldar, revocar, responder a incidentes y destruir). Lo que estas reglas evitan es lo que vimos en la práctica: la clave `CLAVE-DE-PRUEBA` escrita en el SQL y visible en `pg_stat_activity`.

## Conclusión
Una política de claves es lo que convierte al cifrado en una protección real: el algoritmo puede ser bueno y aun así fallar si la clave se maneja mal.
