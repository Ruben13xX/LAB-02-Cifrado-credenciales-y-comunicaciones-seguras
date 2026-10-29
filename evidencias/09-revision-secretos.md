# Evidencia 09 — Revisión de secretos antes de GitLab (Actividad 9)

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Revisar todos los archivos antes del commit para confirmar que no hay contraseñas, claves ni tokens reales.

## Comandos ejecutados (desde la carpeta del laboratorio)
```bash
grep -RniE 'password|passwd|secret|token|api_key|clave' .
grep -RnE 'postgresql://|PGPASSWORD=[^<$ ]' .
grep -R "<contraseña real del usuario de pruebas>" .
grep -Rl "BEGIN .*PRIVATE KEY" .
```

## Resultado
- La primera búsqueda dio **111 coincidencias** en 10 archivos (README, evidencias 01 a 10 y los scripts `01-credenciales.sql` y `02-cifrado-datos.sql`). Era esperable: el laboratorio trata justo de contraseñas y claves, y las palabras aparecen en explicaciones.
- Revisé las coincidencias con valores: todos son los **valores ficticios del laboratorio** (`Password123`, `OtraPassword`, `CLAVE-DE-PRUEBA`, `OTRA-CLAVE`).
- `postgresql://` y `PGPASSWORD=` con valor escrito: **sin coincidencias**.
- La contraseña real del usuario de pruebas del servidor local (la que usé para conectar por TLS) **no aparece** en ningún archivo; se pasó solo por variable de entorno.
- No hay llaves privadas en el repositorio. La CA y el certificado del servidor de pruebas se generaron fuera del repo y no se incluyeron.
- El archivo `sql/ejemplo-mala-practica.sql` fue **eliminado** antes de entregar.

## Análisis
`grep` no garantiza detectar todos los secretos (el propio lab lo aclara): solo encuentra los patrones que se le piden. Sirve para crear el hábito de revisar antes de publicar y no sustituye a herramientas de detección de secretos ni a la política de claves.

## Conclusión
No hay secretos reales en el repositorio; solo valores ficticios de laboratorio.
