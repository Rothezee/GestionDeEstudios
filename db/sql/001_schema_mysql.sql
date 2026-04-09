-- Gestión de Estudios — esquema inicial (MySQL 8.0+)
-- Misma semántica que 001_schema.sql (PostgreSQL).
-- No uses CREATE EXTENSION: eso es solo PostgreSQL. Aquí UUID() es nativo.
--
-- Requisitos: MySQL 8.0.13+ recomendado (DEFAULT con expresión UUID()).
-- Charset: utf8mb4

SET NAMES utf8mb4;

-- Tipos enumerados como ENUM de columna (MySQL no tiene CREATE TYPE como PostgreSQL)

CREATE TABLE usuario (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  email VARCHAR(320) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  nombre VARCHAR(200),
  puede_cliente TINYINT(1) NOT NULL DEFAULT 0,
  puede_trabajador TINYINT(1) NOT NULL DEFAULT 0,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY usuario_email_uk (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cliente (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  nombre VARCHAR(300) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  calificacion_promedio DECIMAL(3, 2) NULL,
  total_valoraciones INT NOT NULL DEFAULT 0,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY cliente_slug_uk (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usuario_cliente (
  usuario_id CHAR(36) NOT NULL,
  cliente_id CHAR(36) NOT NULL,
  PRIMARY KEY (usuario_id, cliente_id),
  CONSTRAINT fk_uc_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_uc_cliente FOREIGN KEY (cliente_id) REFERENCES cliente (id) ON DELETE CASCADE,
  KEY usuario_cliente_cliente_id_idx (cliente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE trabajador (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  usuario_id CHAR(36) NOT NULL,
  bio TEXT,
  portfolio_publico TINYINT(1) NOT NULL DEFAULT 1,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY trabajador_usuario_id_uk (usuario_id),
  CONSTRAINT fk_trab_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE propuesta (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  cliente_id CHAR(36) NOT NULL,
  titulo VARCHAR(500) NOT NULL,
  descripcion TEXT,
  requisitos TEXT,
  presupuesto_estimado DECIMAL(14, 2) NULL,
  moneda CHAR(3) NOT NULL DEFAULT 'USD',
  estado ENUM ('borrador', 'publicada', 'cerrada', 'adjudicada') NOT NULL DEFAULT 'borrador',
  publicada_en TIMESTAMP NULL,
  cierra_en TIMESTAMP NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NULL,
  CONSTRAINT fk_prop_cliente FOREIGN KEY (cliente_id) REFERENCES cliente (id) ON DELETE RESTRICT,
  KEY propuesta_cliente_id_idx (cliente_id),
  KEY propuesta_estado_idx (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Convocatoria publicada por el cliente (no confundir con presupuesto del estudio en sentido clásico).';

CREATE TABLE postulacion (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  propuesta_id CHAR(36) NOT NULL,
  trabajador_id CHAR(36) NOT NULL,
  mensaje TEXT,
  oferta_monto DECIMAL(14, 2) NULL,
  estado ENUM ('enviada', 'preseleccionada', 'aceptada', 'rechazada', 'retirada') NOT NULL DEFAULT 'enviada',
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY postulacion_propuesta_trabajador_uk (propuesta_id, trabajador_id),
  CONSTRAINT fk_post_prop FOREIGN KEY (propuesta_id) REFERENCES propuesta (id) ON DELETE CASCADE,
  CONSTRAINT fk_post_trab FOREIGN KEY (trabajador_id) REFERENCES trabajador (id) ON DELETE CASCADE,
  KEY postulacion_propuesta_id_idx (propuesta_id),
  KEY postulacion_trabajador_id_idx (trabajador_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Relación N:M entre propuesta (convocatoria) y trabajador; a lo más una fila por par.';

CREATE TABLE linea_postulacion (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  postulacion_id CHAR(36) NOT NULL,
  descripcion VARCHAR(500) NOT NULL,
  cantidad DECIMAL(12, 3) NULL,
  precio_unitario DECIMAL(14, 2) NULL,
  orden INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_linea_post FOREIGN KEY (postulacion_id) REFERENCES postulacion (id) ON DELETE CASCADE,
  KEY linea_postulacion_postulacion_id_idx (postulacion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE proyecto (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  cliente_id CHAR(36) NOT NULL,
  propuesta_id CHAR(36) NULL,
  postulacion_id CHAR(36) NULL,
  titulo VARCHAR(500) NOT NULL,
  descripcion TEXT,
  estado ENUM ('borrador', 'activo', 'pagado', 'cerrado') NOT NULL DEFAULT 'borrador',
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY proyecto_postulacion_id_uk (postulacion_id),
  CONSTRAINT fk_proy_cliente FOREIGN KEY (cliente_id) REFERENCES cliente (id) ON DELETE RESTRICT,
  CONSTRAINT fk_proy_prop FOREIGN KEY (propuesta_id) REFERENCES propuesta (id) ON DELETE SET NULL,
  CONSTRAINT fk_proy_post FOREIGN KEY (postulacion_id) REFERENCES postulacion (id) ON DELETE SET NULL,
  KEY proyecto_cliente_id_idx (cliente_id),
  KEY proyecto_propuesta_id_idx (propuesta_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE item_portfolio (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  trabajador_id CHAR(36) NOT NULL,
  titulo VARCHAR(300) NOT NULL,
  descripcion TEXT,
  orden INT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_item_trab FOREIGN KEY (trabajador_id) REFERENCES trabajador (id) ON DELETE CASCADE,
  KEY item_portfolio_trabajador_orden_idx (trabajador_id, orden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE medio_portfolio (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  item_portfolio_id CHAR(36) NOT NULL,
  tipo_medio ENUM ('imagen', 'video', 'enlace', 'otro') NOT NULL,
  storage_key VARCHAR(1024) NULL,
  url_externa VARCHAR(2048) NULL,
  nombre_original VARCHAR(500) NULL,
  mime VARCHAR(200) NULL,
  tamano_bytes BIGINT NULL,
  orden INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_medio_item FOREIGN KEY (item_portfolio_id) REFERENCES item_portfolio (id) ON DELETE CASCADE,
  CONSTRAINT medio_portfolio_storage_o_url_chk CHECK (
    storage_key IS NOT NULL OR url_externa IS NOT NULL
  ),
  KEY medio_portfolio_item_id_idx (item_portfolio_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE valoracion_cliente (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  cliente_id CHAR(36) NOT NULL,
  trabajador_id CHAR(36) NOT NULL,
  proyecto_id CHAR(36) NULL,
  puntuacion SMALLINT NOT NULL,
  comentario TEXT,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_val_cli FOREIGN KEY (cliente_id) REFERENCES cliente (id) ON DELETE CASCADE,
  CONSTRAINT fk_val_trab FOREIGN KEY (trabajador_id) REFERENCES trabajador (id) ON DELETE CASCADE,
  CONSTRAINT fk_val_proy FOREIGN KEY (proyecto_id) REFERENCES proyecto (id) ON DELETE SET NULL,
  CONSTRAINT valoracion_puntuacion_chk CHECK (puntuacion >= 1 AND puntuacion <= 5),
  KEY valoracion_cliente_cliente_id_idx (cliente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- MySQL no tiene índice único parcial (WHERE proyecto_id IS NOT NULL) como PostgreSQL.
-- Índice único sobre (trabajador_id, proyecto_id): en MySQL varias filas con proyecto_id NULL
-- siguen siendo permitidas (NULL no colisiona en UNIQUE), coherente con el diseño.
CREATE UNIQUE INDEX valoracion_cliente_trabajador_proyecto_uniq ON valoracion_cliente (trabajador_id, proyecto_id);

CREATE TABLE archivo_entregable (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  proyecto_id CHAR(36) NOT NULL,
  tipo ENUM ('muestra', 'final') NOT NULL,
  storage_key VARCHAR(1024) NOT NULL,
  nombre_original VARCHAR(500) NULL,
  mime VARCHAR(200) NULL,
  tamano_bytes BIGINT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_arch_proy FOREIGN KEY (proyecto_id) REFERENCES proyecto (id) ON DELETE CASCADE,
  KEY archivo_entregable_proyecto_id_idx (proyecto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER //

CREATE PROCEDURE refresh_cliente_calificacion (IN p_cliente_id CHAR(36))
BEGIN
  UPDATE cliente c
  SET
    c.calificacion_promedio = (
      SELECT ROUND(AVG(vc.puntuacion), 2)
      FROM valoracion_cliente vc
      WHERE vc.cliente_id = p_cliente_id
    ),
    c.total_valoraciones = (
      SELECT COUNT(*)
      FROM valoracion_cliente vc
      WHERE vc.cliente_id = p_cliente_id
    )
  WHERE c.id = p_cliente_id;
END//

CREATE TRIGGER trg_valoracion_after_insert
AFTER INSERT ON valoracion_cliente
FOR EACH ROW
BEGIN
  CALL refresh_cliente_calificacion (NEW.cliente_id);
END//

CREATE TRIGGER trg_valoracion_after_update
AFTER UPDATE ON valoracion_cliente
FOR EACH ROW
BEGIN
  CALL refresh_cliente_calificacion (NEW.cliente_id);
  IF OLD.cliente_id <> NEW.cliente_id THEN
    CALL refresh_cliente_calificacion (OLD.cliente_id);
  END IF;
END//

CREATE TRIGGER trg_valoracion_after_delete
AFTER DELETE ON valoracion_cliente
FOR EACH ROW
BEGIN
  CALL refresh_cliente_calificacion (OLD.cliente_id);
END//

DELIMITER ;
