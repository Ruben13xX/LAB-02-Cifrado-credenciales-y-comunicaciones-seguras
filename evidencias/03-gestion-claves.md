# Evidencia 03 — El problema de la gestión de claves

**Alumno:** Monzon Garcia Jesus Ruben
**Materia:** Gestión de Seguridad y Fundamentos de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16.15 
**Tema:** 2.4 Cifrado, credenciales y protección de las comunicaciones

## Objetivo
Identificar por qué dejar una clave dentro de un script es una mala práctica y qué consecuencias tendría con una clave real.

## Comando o procedimiento
1. Creé el archivo temporal `sql/ejemplo-mala-practica.sql` con una sola consulta (clave ficticia).
2. Lo ejecuté para comprobar que funciona.
3. **Lo eliminé** antes del commit, como pide el lab (no forma parte de la entrega final).

## Resultado obtenido
Contenido del archivo y ejecución:
```text
 pgp_sym_decrypt 
-----------------
 LOPA900101ABC
(1 row)
```

Dato complementario de la evidencia 02: la clave literal queda visible en `pg_stat_activity` mientras se ejecuta la consulta.

## Análisis

**¿Qué pasaría si fuera una clave real y el archivo se publicara en Git?**
- Cualquiera con acceso al repositorio tendría la clave. Si además consigue los datos cifrados (la base, un respaldo o un volcado), puede descifrar **todos** los RFC, no solo uno, porque es la misma clave para todo.
- Borrar la línea en un commit posterior no sirve: la clave sigue en el historial y en los clones y forks que ya existan.
- Habría que tratarlo como incidente: revocar la clave, generar una nueva, volver a cifrar todos los datos y limpiar o rotar lo que se pueda del historial.
- El repositorio privado reduce la exposición, pero no cambia nada de esto: más personas con acceso, CI, copias locales y respaldos pueden contener la clave.

**Cómo se debería hacer en un entorno real:** la clave vive en un gestor de secretos o de claves (KMS, Vault, HSM), separada de los datos y del código, y se entrega a la aplicación en tiempo de ejecución con permisos mínimos. Nunca se escribe en el SQL del repositorio.

## Conclusión
Cifrar los datos es solo la mitad: si la clave queda junto al código o junto a los datos, el cifrado deja de proteger. La gestión de claves es tan importante como el algoritmo.
