# Modelo Entidad-Relación (MER) — Gestión de Estudios

## Convención de nombres

En este modelo, **Propuesta** designa la **convocatoria / solicitud publicada por el cliente** (oferta de trabajo o licitación interna). No debe confundirse con un “presupuesto” enviado por el estudio en sentido clásico: el detalle económico del trabajador se modela en **Postulación** (oferta del postulante) y, opcionalmente, en **líneas de postulación**.

## Diagrama MER

```mermaid
erDiagram
  Usuario ||--o| Trabajador : "perfil_profesional"
  Usuario ||--o{ UsuarioCliente : "acceso"
  Cliente ||--o{ UsuarioCliente : "miembros"
  Cliente ||--o{ Propuesta : "publica"
  Cliente ||--o{ Proyecto : "posee"
  Cliente ||--o{ ValoracionCliente : "recibe"
  Propuesta ||--o{ Postulacion : "recibe"
  Trabajador ||--o{ Postulacion : "envia"
  Trabajador ||--o{ ItemPortfolio : "muestra"
  ItemPortfolio ||--o{ MedioPortfolio : "adjunta"
  Trabajador ||--o{ ValoracionCliente : "emite"
  Propuesta ||--o{ Proyecto : "origina"
  Postulacion ||--o| Proyecto : "asigna"
  Proyecto ||--o{ ArchivoEntregable : "incluye"
  Postulacion ||--o{ LineaPostulacion : "detalla"

  Usuario {
    uuid id PK
    string email UK
    string password_hash
    string nombre
    boolean puede_cliente
    boolean puede_trabajador
    timestamptz creado_en
  }

  Cliente {
    uuid id PK
    string nombre
    string slug UK
    numeric calificacion_promedio
    int total_valoraciones
    timestamptz creado_en
  }

  UsuarioCliente {
    uuid usuario_id FK
    uuid cliente_id FK
  }

  Trabajador {
    uuid id PK
    uuid usuario_id FK_UK
    text bio
    boolean portfolio_publico
    timestamptz creado_en
  }

  Propuesta {
    uuid id PK
    uuid cliente_id FK
    string titulo
    text descripcion
    enum estado_publicacion
    timestamptz publicada_en
    timestamptz cierra_en
  }

  Postulacion {
    uuid id PK
    uuid propuesta_id FK
    uuid trabajador_id FK
    text mensaje
    numeric oferta_monto
    enum estado
    timestamptz creado_en
  }

  LineaPostulacion {
    uuid id PK
    uuid postulacion_id FK
    text descripcion
    numeric cantidad
    numeric precio_unitario
  }

  Proyecto {
    uuid id PK
    uuid cliente_id FK
    uuid propuesta_id FK
    uuid postulacion_id FK
    string titulo
    enum estado_proyecto
  }

  ItemPortfolio {
    uuid id PK
    uuid trabajador_id FK
    string titulo
    int orden
    boolean activo
  }

  MedioPortfolio {
    uuid id PK
    uuid item_portfolio_id FK
    string tipo_medio
    string storage_key
    string url_externa
  }

  ValoracionCliente {
    uuid id PK
    uuid cliente_id FK
    uuid trabajador_id FK
    uuid proyecto_id FK
    smallint puntuacion
    text comentario
  }

  ArchivoEntregable {
    uuid id PK
    uuid proyecto_id FK
    enum tipo
    string storage_key
  }
```

## Cardinalidades

| Relación | Cardinalidad | Notas |
|----------|--------------|--------|
| Usuario — Trabajador | 1 : 0..1 | Solo usuarios con perfil trabajador. |
| Usuario — Cliente | N : M | Tabla **UsuarioCliente**. |
| Cliente — Propuesta | 1 : N | Convocatorias del cliente. |
| Propuesta — Trabajador | N : M | Tabla **Postulación**; a lo más una fila por par (propuesta, trabajador). |
| Cliente — Proyecto | 1 : N | Ejecución de trabajo. |
| Propuesta — Proyecto | 1 : N | Origen de la convocatoria (trazabilidad). |
| Postulación — Proyecto | 1 : 0..1 | Proyecto al aceptar una postulación (regla de negocio: típicamente una postulación aceptada genera un proyecto). |
| Trabajador — ItemPortfolio | 1 : N | Entradas del portfolio. |
| ItemPortfolio — MedioPortfolio | 1 : N | Archivos o enlaces por entrada. |
| Cliente — ValoracionCliente | 1 : N | Historial de valoraciones. |
| Trabajador — ValoracionCliente | 1 : N | Valoraciones emitidas. |
| Proyecto — ArchivoEntregable | 1 : N | Entregables muestra/final (README). |

## Diccionario de datos

### Usuario

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | Identificador de cuenta. |
| email | texto | UK | Login; único global. |
| password_hash | texto | | Hash de contraseña (nunca plano). |
| nombre | texto | | Nombre visible. |
| puede_cliente | booleano | | Puede usar modo Cliente en el panel. |
| puede_trabajador | booleano | | Puede usar modo Trabajador en el panel. |
| creado_en | fecha/hora | | Alta de la cuenta. |

### Cliente

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | Marca / organización. |
| nombre | texto | | Denominación (“Marca X”). |
| slug | texto | UK | URL amigable. |
| calificacion_promedio | decimal(3,2) | | Denormalizado; media de valoraciones. |
| total_valoraciones | entero | | Conteo; denormalizado. |
| creado_en | fecha/hora | | |

### UsuarioCliente

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| usuario_id | UUID | PK, FK → Usuario | |
| cliente_id | UUID | PK, FK → Cliente | |

### Trabajador

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| usuario_id | UUID | FK → Usuario, UK | Un perfil trabajador por usuario. |
| bio | texto | | Presentación opcional. |
| portfolio_publico | booleano | | Si el portfolio es visible en listados. |
| creado_en | fecha/hora | | |

### Propuesta (convocatoria)

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| cliente_id | UUID | FK → Cliente | Emisor de la convocatoria. |
| titulo | texto | | |
| descripcion | texto | | |
| requisitos | texto | | Opcional. |
| presupuesto_estimado | decimal | | Opcional; referencia del cliente. |
| moneda | texto(3) | | ISO 4217 sugerido. |
| estado | enum | | borrador, publicada, cerrada, adjudicada. |
| publicada_en | fecha/hora | | |
| cierra_en | fecha/hora | | Cierre de recepción de postulaciones. |
| creado_en | fecha/hora | | |
| actualizado_en | fecha/hora | | |

### Postulacion

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| propuesta_id | UUID | FK → Propuesta | |
| trabajador_id | UUID | FK → Trabajador | |
| mensaje | texto | | Carta de presentación. |
| oferta_monto | decimal | | Opcional. |
| estado | enum | | enviada, preseleccionada, aceptada, rechazada, retirada. |
| creado_en | fecha/hora | | |
| **Restricción** | | UK (propuesta_id, trabajador_id) | Una postulación por par. |

### LineaPostulacion

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| postulacion_id | UUID | FK → Postulacion | |
| descripcion | texto | | |
| cantidad | decimal | | Opcional. |
| precio_unitario | decimal | | |
| orden | entero | | Orden de visualización. |

### Proyecto

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| cliente_id | UUID | FK → Cliente | |
| propuesta_id | UUID | FK → Propuesta, nullable | Convocatoria de origen. |
| postulacion_id | UUID | FK → Postulacion, UK nullable | Postulación adjudicada (si aplica). |
| titulo | texto | | |
| descripcion | texto | | |
| estado | enum | | borrador, activo, pagado, cerrado (entregables finales según README). |
| creado_en | fecha/hora | | |

### ItemPortfolio

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| trabajador_id | UUID | FK → Trabajador | |
| titulo | texto | | |
| descripcion | texto | | |
| orden | entero | | |
| activo | booleano | | |

### MedioPortfolio

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| item_portfolio_id | UUID | FK → ItemPortfolio | |
| tipo_medio | texto/enum | | imagen, video, enlace, otro. |
| storage_key | texto | | Clave en almacenamiento de objetos. |
| url_externa | texto | | Alternativa al archivo subido. |
| nombre_original | texto | | |
| mime | texto | | |
| tamano_bytes | entero largo | | |
| orden | entero | | |

### ValoracionCliente

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| cliente_id | UUID | FK → Cliente | |
| trabajador_id | UUID | FK → Trabajador | Quien valora. |
| proyecto_id | UUID | FK → Proyecto, nullable | Contexto; **índice único parcial** (trabajador_id, proyecto_id) cuando proyecto_id no es nulo para una valoración por proyecto. |
| puntuacion | entero pequeño | | 1–5. |
| comentario | texto | | Opcional. |
| creado_en | fecha/hora | | |

### ArchivoEntregable

| Atributo | Tipo lógico | Clave | Restricciones / notas |
|----------|-------------|-------|------------------------|
| id | UUID | PK | |
| proyecto_id | UUID | FK → Proyecto | |
| tipo | enum | | muestra, final. |
| storage_key | texto | | |
| nombre_original | texto | | |
| mime | texto | | |
| tamano_bytes | entero largo | | |
| creado_en | fecha/hora | | |

## Reglas de negocio (resumen)

- **Modo Cliente:** acceso a datos del `cliente` vinculado vía `UsuarioCliente`; gestión de convocatorias, revisión de postulaciones, proyectos y valoraciones recibidas.
- **Modo Trabajador:** listado de convocatorias publicadas (según política de la app), postulaciones propias, edición del portfolio; emisión de `ValoracionCliente` hacia clientes con los que interactuó.
- **Entregables finales:** visibilidad/descarga de tipo `final` condicionada al `estado` del proyecto (p. ej. pagado/cerrado), alineado al README.
