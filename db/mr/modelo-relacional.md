# Modelo relacional (MR) — Gestión de Estudios

Motor objetivo: **PostgreSQL**. Esquema lógico en **tercera forma normal (3FN)** para las entidades principales; columnas `calificacion_promedio` y `total_valoraciones` en `cliente` son **denormalización controlada** para lectura rápida, mantenidas por trigger a partir de `valoracion_cliente`.

## Convención

- **propuesta** = fila de convocatoria (no “presupuesto del estudio” en sentido clásico).
- Claves primarias: **UUID** (`gen_random_uuid()`).

## Tablas

### usuario

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| email | VARCHAR(320) | NO | UK | |
| password_hash | VARCHAR(255) | NO | | Argon2/bcrypt/etc. |
| nombre | VARCHAR(200) | YES | | |
| puede_cliente | BOOLEAN | NO | | DEFAULT false |
| puede_trabajador | BOOLEAN | NO | | DEFAULT false |
| creado_en | TIMESTAMPTZ | NO | | DEFAULT now() |

**Índices:** `UNIQUE (email)`.

---

### cliente

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| nombre | VARCHAR(300) | NO | | |
| slug | VARCHAR(120) | NO | UK | |
| calificacion_promedio | NUMERIC(3,2) | YES | | Media; trigger |
| total_valoraciones | INTEGER | NO | | DEFAULT 0; trigger |
| creado_en | TIMESTAMPTZ | NO | | DEFAULT now() |

**Índices:** `UNIQUE (slug)`.

---

### usuario_cliente

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| usuario_id | UUID | NO | PK, FK → usuario(id) ON DELETE CASCADE | |
| cliente_id | UUID | NO | PK, FK → cliente(id) ON DELETE CASCADE | |

**Índices:** `PRIMARY KEY (usuario_id, cliente_id)`; índice en `cliente_id` para búsquedas inversas.

---

### trabajador

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| usuario_id | UUID | NO | UK, FK → usuario(id) ON DELETE CASCADE | |
| bio | TEXT | YES | | |
| portfolio_publico | BOOLEAN | NO | | DEFAULT true |
| creado_en | TIMESTAMPTZ | NO | | DEFAULT now() |

**Índices:** `UNIQUE (usuario_id)`.

---

### propuesta

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| cliente_id | UUID | NO | FK → cliente(id) ON DELETE RESTRICT | |
| titulo | VARCHAR(500) | NO | | |
| descripcion | TEXT | YES | | |
| requisitos | TEXT | YES | | |
| presupuesto_estimado | NUMERIC(14,2) | YES | | Referencia cliente |
| moneda | CHAR(3) | NO | | DEFAULT 'USD' |
| estado | estado_propuesta | NO | | ENUM en SQL |
| publicada_en | TIMESTAMPTZ | YES | | |
| cierra_en | TIMESTAMPTZ | YES | | |
| creado_en | TIMESTAMPTZ | NO | | |
| actualizado_en | TIMESTAMPTZ | YES | | |

**Índices:** `(cliente_id)`, `(estado)` según listados.

---

### postulacion

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| propuesta_id | UUID | NO | FK → propuesta(id) ON DELETE CASCADE | |
| trabajador_id | UUID | NO | FK → trabajador(id) ON DELETE CASCADE | |
| mensaje | TEXT | YES | | |
| oferta_monto | NUMERIC(14,2) | YES | | |
| estado | estado_postulacion | NO | | |
| creado_en | TIMESTAMPTZ | NO | | |

**Índices:** `UNIQUE (propuesta_id, trabajador_id)`; `(propuesta_id)`; `(trabajador_id)`.

---

### linea_postulacion

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| postulacion_id | UUID | NO | FK → postulacion(id) ON DELETE CASCADE | |
| descripcion | VARCHAR(500) | NO | | |
| cantidad | NUMERIC(12,3) | YES | | |
| precio_unitario | NUMERIC(14,2) | YES | | |
| orden | INTEGER | NO | | DEFAULT 0 |

**Índices:** `(postulacion_id)`.

**Normalización:** líneas dependen solo de la postulación (1NF/2FN/3FN).

---

### proyecto

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| cliente_id | UUID | NO | FK → cliente(id) ON DELETE RESTRICT | |
| propuesta_id | UUID | YES | FK → propuesta(id) ON DELETE SET NULL | Origen convocatoria |
| postulacion_id | UUID | YES | UK, FK → postulacion(id) ON DELETE SET NULL | Adjudicación |
| titulo | VARCHAR(500) | NO | | |
| descripcion | TEXT | YES | | |
| estado | estado_proyecto | NO | | |
| creado_en | TIMESTAMPTZ | NO | | |

**Índices:** `UNIQUE (postulacion_id)` donde no nulo (PostgreSQL permite varios NULL en UNIQUE — un solo proyecto por postulación adjudicada); `(cliente_id)`.

---

### item_portfolio

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| trabajador_id | UUID | NO | FK → trabajador(id) ON DELETE CASCADE | |
| titulo | VARCHAR(300) | NO | | |
| descripcion | TEXT | YES | | |
| orden | INTEGER | NO | | DEFAULT 0 |
| activo | BOOLEAN | NO | | DEFAULT true |

**Índices:** `(trabajador_id, orden)`.

---

### medio_portfolio

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| item_portfolio_id | UUID | NO | FK → item_portfolio(id) ON DELETE CASCADE | |
| tipo_medio | tipo_medio_portfolio | NO | | |
| storage_key | VARCHAR(1024) | YES | | Si es archivo |
| url_externa | VARCHAR(2048) | YES | | Si es enlace |
| nombre_original | VARCHAR(500) | YES | | |
| mime | VARCHAR(200) | YES | | |
| tamano_bytes | BIGINT | YES | | |
| orden | INTEGER | NO | | DEFAULT 0 |

**Restricción de dominio:** al menos uno de `storage_key` o `url_externa` debería estar presente (validación en aplicación o CHECK).

**Índices:** `(item_portfolio_id)`.

---

### valoracion_cliente

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| cliente_id | UUID | NO | FK → cliente(id) ON DELETE CASCADE | |
| trabajador_id | UUID | NO | FK → trabajador(id) ON DELETE CASCADE | |
| proyecto_id | UUID | YES | FK → proyecto(id) ON DELETE SET NULL | |
| puntuacion | SMALLINT | NO | | CHECK 1–5 |
| comentario | TEXT | YES | | |
| creado_en | TIMESTAMPTZ | NO | | |

**Índices:**

- `(cliente_id)` — agregados y trigger.
- **Índice único parcial:** `UNIQUE (trabajador_id, proyecto_id) WHERE proyecto_id IS NOT NULL` — como mucho una valoración por trabajador y proyecto cuando hay contexto de proyecto.

---

### archivo_entregable

| Columna | Tipo | Nulo | Clave | Descripción |
|---------|------|------|-------|-------------|
| id | UUID | NO | PK | |
| proyecto_id | UUID | NO | FK → proyecto(id) ON DELETE CASCADE | |
| tipo | tipo_entregable | NO | | muestra \| final |
| storage_key | VARCHAR(1024) | NO | | |
| nombre_original | VARCHAR(500) | YES | | |
| mime | VARCHAR(200) | YES | | |
| tamano_bytes | BIGINT | YES | | |
| creado_en | TIMESTAMPTZ | NO | | |

**Índices:** `(proyecto_id)`.

---

## Tipos enumerados (dominio)

Definidos en SQL como `CREATE TYPE`:

| Tipo | Valores |
|------|---------|
| estado_propuesta | borrador, publicada, cerrada, adjudicada |
| estado_postulacion | enviada, preseleccionada, aceptada, rechazada, retirada |
| estado_proyecto | borrador, activo, pagado, cerrado |
| tipo_entregable | muestra, final |
| tipo_medio_portfolio | imagen, video, enlace, otro |

---

## Seguridad (vista lógica)

- **Modo Cliente:** filtrar por `cliente_id ∈ usuario_cliente` del usuario autenticado.
- **Modo Trabajador:** propuestas con `estado = publicada` (u otra regla); postulaciones donde `trabajador_id` sea el del usuario; portfolio propio.

---

## Dependencias de borrado (resumen)

- Borrar **usuario** elimina **trabajador** asociado (CASCADE) y filas en **usuario_cliente**.
- Borrar **cliente** está **RESTRICT** si hay **propuesta** o **proyecto**; conviene borrado lógico en producción.
- **postulacion** CASCADE desde **propuesta** o **trabajador** según política (en DDL: CASCADE desde propuesta/trabajador hacia líneas; **proyecto.postulacion_id** SET NULL si se borra postulación).

El script [001_schema.sql](../sql/001_schema.sql) materializa este MR.
