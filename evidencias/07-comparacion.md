# Evidencia 07 — Protección en reposo vs. protección en tránsito

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Relacionar cada situación con el mecanismo adecuado y lo que realmente protege.

## Procedimiento
Análisis a partir de lo practicado en las evidencias 01 a 04.

## Resultado

| Situación | Mecanismo apropiado | ¿Qué protege? |
|---|---|---|
| Contraseña de usuario | Hash con derivación de claves para contraseñas (Argon2id, scrypt o bcrypt con costo adecuado). En la práctica: `crypt()` con `gen_salt('bf')` | Que una lectura o filtración de la tabla no entregue la contraseña. Dato **en reposo**, sin posibilidad de recuperarlo |
| RFC almacenado en una tabla | Cifrado simétrico (`pgp_sym_encrypt`) con la clave guardada aparte, solo si hay justificación para recuperarlo | Confidencialidad del dato **en reposo** frente a quien lea la tabla sin tener la clave |
| Consulta enviada desde un cliente al servidor | TLS, preferentemente con `sslmode=verify-full` | Datos **en tránsito**: confidencialidad, integridad y autenticación del servidor |
| Respaldo de una base de datos | Cifrado del respaldo (por ejemplo con `gpg`/`age` o cifrado del almacenamiento) y control de acceso al archivo | Datos **en reposo** en archivos que están fuera de los controles de roles de PostgreSQL |
| Clave criptográfica | Gestión de claves: gestor de secretos o KMS/HSM, acceso mínimo, rotación, separada de datos y código | El secreto que protege a todo lo demás; si se pierde o se expone, se pierde la protección |

## Análisis
Ningún mecanismo cubre todo: TLS no protege lo almacenado, el cifrado de columnas no protege el canal, y nada de esto funciona si la clave se expone.

## Conclusión
Hay que combinar mecanismos según el riesgo: hash para credenciales, cifrado para datos que deben recuperarse, TLS para el tránsito, cifrado de respaldos y gestión de claves.
