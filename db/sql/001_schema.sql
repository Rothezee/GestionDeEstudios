-- Gestión de Estudios — esquema inicial (PostgreSQL)
-- Alineado con db/mer y db/mr. Ejecutar sobre base de datos vacía o migrar con herramientas dedicadas.
-- Si usas MySQL / MariaDB, no ejecutes este archivo: usa 001_schema_mysql.sql (no existe CREATE EXTENSION).

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Dominios enumerados
CREATE TYPE estado_propuesta AS ENUM (
  'borrador',
  'publicada',
  'cerrada',
  'adjudicada'
);

CREATE TYPE estado_postulacion AS ENUM (
  'enviada',
  'preseleccionada',
  'aceptada',
  'rechazada',
  'retirada'
);

CREATE TYPE estado_proyecto AS ENUM (
  'borrador',
  'activo',
  'pagado',
  'cerrado'
);

CREATE TYPE tipo_entregable AS ENUM (
  'muestra',
  'final'
);

CREATE TYPE tipo_medio_portfolio AS ENUM (
  'imagen',
  'video',
  'enlace',
  'otro'
);

-- Tablas base
CREATE TABLE usuario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  email varchar(320) NOT NULL,
  password_hash varchar(255) NOT NULL,
  nombre varchar(200),
  puede_cliente boolean NOT NULL DEFAULT false,
  puede_trabajador boolean NOT NULL DEFAULT false,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT usuario_email_uk UNIQUE (email)
);

CREATE TABLE cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  nombre varchar(300) NOT NULL,
  slug varchar(120) NOT NULL,
  calificacion_promedio numeric(3, 2),
  total_valoraciones integer NOT NULL DEFAULT 0,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cliente_slug_uk UNIQUE (slug)
);

CREATE TABLE usuario_cliente (
  usuario_id uuid NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
  cliente_id uuid NOT NULL REFERENCES cliente (id) ON DELETE CASCADE,
  PRIMARY KEY (usuario_id, cliente_id)
);

CREATE INDEX usuario_cliente_cliente_id_idx ON usuario_cliente (cliente_id);

CREATE TABLE trabajador (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  usuario_id uuid NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
  bio text,
  portfolio_publico boolean NOT NULL DEFAULT true,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT trabajador_usuario_id_uk UNIQUE (usuario_id)
);

CREATE TABLE propuesta (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  cliente_id uuid NOT NULL REFERENCES cliente (id) ON DELETE RESTRICT,
  titulo varchar(500) NOT NULL,
  descripcion text,
  requisitos text,
  presupuesto_estimado numeric(14, 2),
  moneda char(3) NOT NULL DEFAULT 'USD',
  estado estado_propuesta NOT NULL DEFAULT 'borrador',
  publicada_en timestamptz,
  cierra_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz
);

CREATE INDEX propuesta_cliente_id_idx ON propuesta (cliente_id);

CREATE INDEX propuesta_estado_idx ON propuesta (estado);

CREATE TABLE postulacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  propuesta_id uuid NOT NULL REFERENCES propuesta (id) ON DELETE CASCADE,
  trabajador_id uuid NOT NULL REFERENCES trabajador (id) ON DELETE CASCADE,
  mensaje text,
  oferta_monto numeric(14, 2),
  estado estado_postulacion NOT NULL DEFAULT 'enviada',
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT postulacion_propuesta_trabajador_uk UNIQUE (propuesta_id, trabajador_id)
);

CREATE INDEX postulacion_propuesta_id_idx ON postulacion (propuesta_id);

CREATE INDEX postulacion_trabajador_id_idx ON postulacion (trabajador_id);

CREATE TABLE linea_postulacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  postulacion_id uuid NOT NULL REFERENCES postulacion (id) ON DELETE CASCADE,
  descripcion varchar(500) NOT NULL,
  cantidad numeric(12, 3),
  precio_unitario numeric(14, 2),
  orden integer NOT NULL DEFAULT 0
);

CREATE INDEX linea_postulacion_postulacion_id_idx ON linea_postulacion (postulacion_id);

CREATE TABLE proyecto (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  cliente_id uuid NOT NULL REFERENCES cliente (id) ON DELETE RESTRICT,
  propuesta_id uuid REFERENCES propuesta (id) ON DELETE SET NULL,
  postulacion_id uuid REFERENCES postulacion (id) ON DELETE SET NULL,
  titulo varchar(500) NOT NULL,
  descripcion text,
  estado estado_proyecto NOT NULL DEFAULT 'borrador',
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT proyecto_postulacion_id_uk UNIQUE (postulacion_id)
);

CREATE INDEX proyecto_cliente_id_idx ON proyecto (cliente_id);

CREATE INDEX proyecto_propuesta_id_idx ON proyecto (propuesta_id);

CREATE TABLE item_portfolio (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  trabajador_id uuid NOT NULL REFERENCES trabajador (id) ON DELETE CASCADE,
  titulo varchar(300) NOT NULL,
  descripcion text,
  orden integer NOT NULL DEFAULT 0,
  activo boolean NOT NULL DEFAULT true
);

CREATE INDEX item_portfolio_trabajador_orden_idx ON item_portfolio (trabajador_id, orden);

CREATE TABLE medio_portfolio (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  item_portfolio_id uuid NOT NULL REFERENCES item_portfolio (id) ON DELETE CASCADE,
  tipo_medio tipo_medio_portfolio NOT NULL,
  storage_key varchar(1024),
  url_externa varchar(2048),
  nombre_original varchar(500),
  mime varchar(200),
  tamano_bytes bigint,
  orden integer NOT NULL DEFAULT 0,
  CONSTRAINT medio_portfolio_storage_o_url_chk CHECK (
    storage_key IS NOT NULL
    OR url_externa IS NOT NULL
  )
);

CREATE INDEX medio_portfolio_item_id_idx ON medio_portfolio (item_portfolio_id);

CREATE TABLE valoracion_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  cliente_id uuid NOT NULL REFERENCES cliente (id) ON DELETE CASCADE,
  trabajador_id uuid NOT NULL REFERENCES trabajador (id) ON DELETE CASCADE,
  proyecto_id uuid REFERENCES proyecto (id) ON DELETE SET NULL,
  puntuacion smallint NOT NULL,
  comentario text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT valoracion_puntuacion_chk CHECK (
    puntuacion >= 1
    AND puntuacion <= 5
  )
);

CREATE INDEX valoracion_cliente_cliente_id_idx ON valoracion_cliente (cliente_id);

CREATE UNIQUE INDEX valoracion_cliente_trabajador_proyecto_uniq
ON valoracion_cliente (trabajador_id, proyecto_id)
WHERE
  proyecto_id IS NOT NULL;

CREATE TABLE archivo_entregable (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  proyecto_id uuid NOT NULL REFERENCES proyecto (id) ON DELETE CASCADE,
  tipo tipo_entregable NOT NULL,
  storage_key varchar(1024) NOT NULL,
  nombre_original varchar(500),
  mime varchar(200),
  tamano_bytes bigint,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX archivo_entregable_proyecto_id_idx ON archivo_entregable (proyecto_id);

-- FK valoracion_cliente -> proyecto: ya definida arriba (nullable)

-- Trigger: mantener calificacion_promedio y total_valoraciones en cliente
CREATE OR REPLACE FUNCTION refresh_cliente_calificacion ()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  cid uuid;
BEGIN
  cid := COALESCE(NEW.cliente_id, OLD.cliente_id);
  IF cid IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  UPDATE cliente
  SET
    calificacion_promedio = agg.prom,
    total_valoraciones = agg.cnt
  FROM (
    SELECT
      ROUND(AVG(puntuacion)::numeric, 2) AS prom,
      COUNT(*)::integer AS cnt
    FROM
      valoracion_cliente
    WHERE
      cliente_id = cid) agg
WHERE
  cliente.id = cid;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_valoracion_refresh
  AFTER INSERT OR UPDATE OR DELETE ON valoracion_cliente
  FOR EACH ROW
  EXECUTE PROCEDURE refresh_cliente_calificacion ();

COMMENT ON TABLE propuesta IS 'Convocatoria publicada por el cliente (no confundir con presupuesto del estudio en sentido clásico).';

COMMENT ON TABLE postulacion IS 'Relación N:M entre propuesta (convocatoria) y trabajador; a lo más una fila por par.';

COMMIT;
