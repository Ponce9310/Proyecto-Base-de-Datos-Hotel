-- ============================================================
-- PROYECTO FINAL: SISTEMA DE GESTION DE HOTEL
-- ASIGNATURA: TALLER DE BASE DE DATOS
-- ============================================================
-- SCRIPT UNIFICADO FINAL
--
-- CONTENIDO:
--   1) 22 TABLAS
--   2) 130 INSERT
--   3) 13 SECUENCIAS
--   4) 19 EJERCICIOS PL/SQL (PRIMERA EVALUACION)
--
-- ORDEN DE EJECUCION:
--
--   1. BASE DE DATOS:
--      Ejecutar la PARTE I completa para crear las tablas,
--      cargar los 130 registros y crear las 13 secuencias.
--
--   2. EJERCICIOS 1 AL 19:
--      Ejecutar y verificar la salida.
--
--      Esta entrega corresponde a la primera evaluacion y
--      considera los ejercicios hasta el manejo de excepciones.
--
--      Los ejercicios posteriores de procedimientos, funciones,
--      package, triggers e integrador corresponden a una etapa posterior.
--
-- IMPORTANTE:
-- Los codigos ejecutables de los dos archivos finales originales
-- se conservan sin modificaciones. Solo se agregan comentarios
-- para organizar este archivo maestro.
--
-- REEJECUCION:
-- El DDL original contiene DROP TABLE, pero no DROP SEQUENCE.
-- Por ello, este archivo esta pensado para una ejecucion desde
-- un esquema limpio. No se debe volver a ejecutar la PARTE I
-- sobre tu BD actual ya poblada, porque las secuencias existentes
-- producirian ORA-00955 al intentar crearlas nuevamente.
-- ============================================================


-- ============================================================
-- PARTE I - BASE DE DATOS
-- ============================================================
-- EJECUTAR ESTA PARTE PARA:
--   * Crear las 22 tablas.
--   * Cargar los 130 INSERT.
--   * Crear las 13 secuencias.
-- ============================================================

-- ============================================================
-- PROYECTO: SISTEMA DE GESTION DE HOTEL
-- ASIGNATURA: TALLER DE BASE DE DATOS
--
-- SCRIPT DE CREACION DE TABLAS
-- Version 3 - Modelo inicial mejorado
--
-- Objetivo:
-- Crear la estructura principal de la base de datos de un hotel,
-- aplicando normalizacion, claves primarias, claves foraneas,
-- restricciones UNIQUE, NOT NULL y CHECK.
--
-- Las reglas que necesitan consultar varias filas, como:
--   * evitar reservas superpuestas
--   * controlar el total pagado
--   * validar cambios de estado
-- se trabajaran posteriormente con PL/SQL.
-- ============================================================


-- ============================================================
-- 1. LIMPIEZA DE TABLAS
-- ============================================================
-- Las secuencias no se eliminan en esta seccion.
-- El script debe ejecutarse desde un esquema limpio cuando se
-- necesite crear nuevamente las 13 secuencias.



-- Esta seccion se utiliza cuando las tablas ya existen.
-- Si se ejecuta por primera vez y las tablas no existen,
-- Oracle mostrara ORA-00942 en estos DROP.
-- En ese caso se pueden comentar temporalmente.

DROP TABLE pago CASCADE CONSTRAINTS;
DROP TABLE cuenta_cobro CASCADE CONSTRAINTS;
DROP TABLE consumo_servicio CASCADE CONSTRAINTS;
DROP TABLE servicio_adicional CASCADE CONSTRAINTS;
DROP TABLE categoria_servicio CASCADE CONSTRAINTS;
DROP TABLE ocupante_estadia CASCADE CONSTRAINTS;
DROP TABLE estadia CASCADE CONSTRAINTS;
DROP TABLE auditoria_reserva CASCADE CONSTRAINTS;
DROP TABLE detalle_reserva CASCADE CONSTRAINTS;
DROP TABLE reserva CASCADE CONSTRAINTS;
DROP TABLE tarifa_habitacion CASCADE CONSTRAINTS;
DROP TABLE temporada CASCADE CONSTRAINTS;
DROP TABLE habitacion CASCADE CONSTRAINTS;
DROP TABLE estado_habitacion CASCADE CONSTRAINTS;
DROP TABLE tipo_habitacion CASCADE CONSTRAINTS;
DROP TABLE empleado CASCADE CONSTRAINTS;
DROP TABLE huesped CASCADE CONSTRAINTS;
DROP TABLE ciudad CASCADE CONSTRAINTS;
DROP TABLE pais CASCADE CONSTRAINTS;
DROP TABLE tipo_documento CASCADE CONSTRAINTS;
DROP TABLE metodo_pago CASCADE CONSTRAINTS;
DROP TABLE estado_reserva CASCADE CONSTRAINTS;


-- ============================================================
-- 2. TABLAS DE APOYO / CATALOGOS
-- ============================================================

CREATE TABLE pais (
    id_pais NUMBER NOT NULL,
    nombre_pais VARCHAR2(50) NOT NULL
);

CREATE TABLE ciudad (
    id_ciudad NUMBER NOT NULL,
    id_pais NUMBER NOT NULL,
    nombre_ciudad VARCHAR2(50) NOT NULL
);

CREATE TABLE tipo_documento (
    id_tipo_doc NUMBER NOT NULL,
    nombre_doc VARCHAR2(50) NOT NULL
);

CREATE TABLE estado_habitacion (
    id_estado_hab NUMBER NOT NULL,
    nombre_estado VARCHAR2(50) NOT NULL
);

CREATE TABLE estado_reserva (
    id_estado_res NUMBER NOT NULL,
    nombre_estado VARCHAR2(50) NOT NULL
);

CREATE TABLE categoria_servicio (
    id_categoria NUMBER NOT NULL,
    nombre_categoria VARCHAR2(50) NOT NULL
);

CREATE TABLE metodo_pago (
    id_metodo_pago NUMBER NOT NULL,
    nombre_metodo VARCHAR2(50) NOT NULL
);

CREATE TABLE temporada (
    id_temporada NUMBER NOT NULL,
    nombre_temporada VARCHAR2(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL
);


-- ============================================================
-- 3. DATOS DEL HUESPED Y EMPLEADO
-- ============================================================

CREATE TABLE huesped (
    id_huesped NUMBER NOT NULL,
    id_tipo_doc NUMBER NOT NULL,
    id_ciudad NUMBER NOT NULL,
    num_doc VARCHAR2(20) NOT NULL,
    nombre_completo VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20) NOT NULL
);

CREATE TABLE empleado (
    id_empleado NUMBER NOT NULL,
    rut_empleado VARCHAR2(20) NOT NULL,
    nombre_completo VARCHAR2(100) NOT NULL,
    cargo VARCHAR2(50) NOT NULL
);


-- ============================================================
-- 4. HABITACIONES Y TARIFAS
-- ============================================================

CREATE TABLE tipo_habitacion (
    id_tipo_hab NUMBER NOT NULL,
    nombre_tipo VARCHAR2(50) NOT NULL,
    capacidad_max NUMBER NOT NULL
);

CREATE TABLE habitacion (
    id_habitacion NUMBER NOT NULL,
    id_tipo_hab NUMBER NOT NULL,
    id_estado_hab NUMBER NOT NULL,
    numero_hab VARCHAR2(10) NOT NULL,
    piso NUMBER NOT NULL
);

CREATE TABLE tarifa_habitacion (
    id_tarifa NUMBER NOT NULL,
    id_tipo_hab NUMBER NOT NULL,
    id_temporada NUMBER NOT NULL,
    precio_noche NUMBER NOT NULL
);


-- ============================================================
-- 5. RESERVAS Y ESTADIAS
-- ============================================================

CREATE TABLE reserva (
    id_reserva NUMBER NOT NULL,
    id_huesped NUMBER NOT NULL,
    id_empleado NUMBER NOT NULL,
    id_estado_res NUMBER NOT NULL,
    fecha_registro DATE DEFAULT SYSDATE NOT NULL
);

CREATE TABLE detalle_reserva (
    id_detalle NUMBER NOT NULL,
    id_reserva NUMBER NOT NULL,
    id_habitacion NUMBER NOT NULL,
    fec_ingreso DATE NOT NULL,
    fec_salida DATE NOT NULL,
    precio_aplicado NUMBER NOT NULL
);

CREATE TABLE estadia (
    id_estadia NUMBER NOT NULL,
    id_detalle NUMBER NOT NULL,
    checkin_real DATE NOT NULL,
    checkout_real DATE
);

CREATE TABLE ocupante_estadia (
    id_ocupante NUMBER NOT NULL,
    id_estadia NUMBER NOT NULL,
    num_doc_ocupante VARCHAR2(50) NOT NULL,
    nombre_ocupante VARCHAR2(100) NOT NULL
);


-- ============================================================
-- 6. AUDITORIA DE RESERVAS
-- ============================================================
-- Guarda el historial de cambios de estado de una reserva.
--
-- id_empleado se agrega desde ahora para saber quien realizo
-- el cambio. Posteriormente un TRIGGER PL/SQL podra llenar
-- esta tabla automaticamente.
-- ============================================================

CREATE TABLE auditoria_reserva (
    id_auditoria NUMBER NOT NULL,
    id_reserva NUMBER NOT NULL,
    id_empleado NUMBER NOT NULL,
    estado_anterior VARCHAR2(50) NOT NULL,
    estado_nuevo VARCHAR2(50) NOT NULL,
    fecha_cambio DATE DEFAULT SYSDATE NOT NULL
);


-- ============================================================
-- 7. SERVICIOS
-- ============================================================

CREATE TABLE servicio_adicional (
    id_servicio NUMBER NOT NULL,
    id_categoria NUMBER NOT NULL,
    nombre_servicio VARCHAR2(100) NOT NULL,
    precio_actual NUMBER NOT NULL
);

CREATE TABLE consumo_servicio (
    id_consumo NUMBER NOT NULL,
    id_estadia NUMBER NOT NULL,
    id_servicio NUMBER NOT NULL,
    cantidad NUMBER NOT NULL,
    precio_cobrado NUMBER NOT NULL
);


-- ============================================================
-- 8. CUENTA Y PAGOS
-- ============================================================

CREATE TABLE cuenta_cobro (
    id_cuenta NUMBER NOT NULL,
    id_estadia NUMBER NOT NULL,
    subtotal_hab NUMBER NOT NULL,
    subtotal_serv NUMBER NOT NULL,
    monto_total NUMBER NOT NULL
);

CREATE TABLE pago (
    id_pago NUMBER NOT NULL,
    id_cuenta NUMBER NOT NULL,
    id_metodo_pago NUMBER NOT NULL,
    monto_pagado NUMBER NOT NULL,
    fecha_pago DATE DEFAULT SYSDATE NOT NULL
);


-- ============================================================
-- 9. CLAVES PRIMARIAS
-- ============================================================

ALTER TABLE pais
    ADD CONSTRAINT pk_pais PRIMARY KEY (id_pais);

ALTER TABLE ciudad
    ADD CONSTRAINT pk_ciudad PRIMARY KEY (id_ciudad);

ALTER TABLE tipo_documento
    ADD CONSTRAINT pk_tipo_doc PRIMARY KEY (id_tipo_doc);

ALTER TABLE estado_habitacion
    ADD CONSTRAINT pk_estado_hab PRIMARY KEY (id_estado_hab);

ALTER TABLE estado_reserva
    ADD CONSTRAINT pk_estado_res PRIMARY KEY (id_estado_res);

ALTER TABLE categoria_servicio
    ADD CONSTRAINT pk_categoria PRIMARY KEY (id_categoria);

ALTER TABLE metodo_pago
    ADD CONSTRAINT pk_metodo_pago PRIMARY KEY (id_metodo_pago);

ALTER TABLE temporada
    ADD CONSTRAINT pk_temporada PRIMARY KEY (id_temporada);

ALTER TABLE huesped
    ADD CONSTRAINT pk_huesped PRIMARY KEY (id_huesped);

ALTER TABLE empleado
    ADD CONSTRAINT pk_empleado PRIMARY KEY (id_empleado);

ALTER TABLE tipo_habitacion
    ADD CONSTRAINT pk_tipo_hab PRIMARY KEY (id_tipo_hab);

ALTER TABLE habitacion
    ADD CONSTRAINT pk_habitacion PRIMARY KEY (id_habitacion);

ALTER TABLE tarifa_habitacion
    ADD CONSTRAINT pk_tarifa PRIMARY KEY (id_tarifa);

ALTER TABLE reserva
    ADD CONSTRAINT pk_reserva PRIMARY KEY (id_reserva);

ALTER TABLE detalle_reserva
    ADD CONSTRAINT pk_detalle PRIMARY KEY (id_detalle);

ALTER TABLE estadia
    ADD CONSTRAINT pk_estadia PRIMARY KEY (id_estadia);

ALTER TABLE ocupante_estadia
    ADD CONSTRAINT pk_ocupante PRIMARY KEY (id_ocupante);

ALTER TABLE auditoria_reserva
    ADD CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria);

ALTER TABLE servicio_adicional
    ADD CONSTRAINT pk_servicio PRIMARY KEY (id_servicio);

ALTER TABLE consumo_servicio
    ADD CONSTRAINT pk_consumo PRIMARY KEY (id_consumo);

ALTER TABLE cuenta_cobro
    ADD CONSTRAINT pk_cuenta PRIMARY KEY (id_cuenta);

ALTER TABLE pago
    ADD CONSTRAINT pk_pago PRIMARY KEY (id_pago);


-- ============================================================
-- 10. RESTRICCIONES UNIQUE
-- ============================================================

-- No repetir el nombre de un pais.
ALTER TABLE pais
    ADD CONSTRAINT uq_pais_nombre
    UNIQUE (nombre_pais);

-- No repetir una ciudad dentro del mismo pais.
ALTER TABLE ciudad
    ADD CONSTRAINT uq_ciudad_pais_nombre
    UNIQUE (id_pais, nombre_ciudad);

-- No repetir tipos de documento.
ALTER TABLE tipo_documento
    ADD CONSTRAINT uq_tipo_doc_nombre
    UNIQUE (nombre_doc);

-- No repetir estados de habitacion.
ALTER TABLE estado_habitacion
    ADD CONSTRAINT uq_estado_hab_nombre
    UNIQUE (nombre_estado);

-- No repetir estados de reserva.
ALTER TABLE estado_reserva
    ADD CONSTRAINT uq_estado_res_nombre
    UNIQUE (nombre_estado);

-- No repetir categorias de servicio.
ALTER TABLE categoria_servicio
    ADD CONSTRAINT uq_categoria_nombre
    UNIQUE (nombre_categoria);

-- No repetir metodos de pago.
ALTER TABLE metodo_pago
    ADD CONSTRAINT uq_metodo_pago_nombre
    UNIQUE (nombre_metodo);

-- No registrar dos veces exactamente la misma temporada.
ALTER TABLE temporada
    ADD CONSTRAINT uq_temporada_periodo
    UNIQUE (nombre_temporada, fecha_inicio, fecha_fin);

-- El documento se identifica por tipo + numero.
ALTER TABLE huesped
    ADD CONSTRAINT uq_huesped_documento
    UNIQUE (id_tipo_doc, num_doc);

-- El RUT del empleado debe ser unico.
ALTER TABLE empleado
    ADD CONSTRAINT uq_empleado_rut
    UNIQUE (rut_empleado);

-- No repetir tipos de habitacion.
ALTER TABLE tipo_habitacion
    ADD CONSTRAINT uq_tipo_hab_nombre
    UNIQUE (nombre_tipo);

-- El numero de habitacion debe ser unico.
ALTER TABLE habitacion
    ADD CONSTRAINT uq_habitacion_numero
    UNIQUE (numero_hab);

-- Un tipo de habitacion tiene una sola tarifa por temporada.
ALTER TABLE tarifa_habitacion
    ADD CONSTRAINT uq_tarifa_tipo_temporada
    UNIQUE (id_tipo_hab, id_temporada);

-- Un detalle de reserva puede generar como maximo una estadia.
ALTER TABLE estadia
    ADD CONSTRAINT uq_estadia_detalle
    UNIQUE (id_detalle);

-- No repetir el nombre de un servicio.
ALTER TABLE servicio_adicional
    ADD CONSTRAINT uq_servicio_nombre
    UNIQUE (nombre_servicio);

-- Una estadia tiene una sola cuenta de cobro.
ALTER TABLE cuenta_cobro
    ADD CONSTRAINT uq_cuenta_estadia
    UNIQUE (id_estadia);


-- ============================================================
-- 11. CLAVES FORANEAS
-- ============================================================

ALTER TABLE ciudad
    ADD CONSTRAINT fk_ciudad_pais
    FOREIGN KEY (id_pais)
    REFERENCES pais (id_pais);

ALTER TABLE huesped
    ADD CONSTRAINT fk_huesped_tipo_doc
    FOREIGN KEY (id_tipo_doc)
    REFERENCES tipo_documento (id_tipo_doc);

ALTER TABLE huesped
    ADD CONSTRAINT fk_huesped_ciudad
    FOREIGN KEY (id_ciudad)
    REFERENCES ciudad (id_ciudad);

ALTER TABLE habitacion
    ADD CONSTRAINT fk_habitacion_tipo
    FOREIGN KEY (id_tipo_hab)
    REFERENCES tipo_habitacion (id_tipo_hab);

ALTER TABLE habitacion
    ADD CONSTRAINT fk_habitacion_estado
    FOREIGN KEY (id_estado_hab)
    REFERENCES estado_habitacion (id_estado_hab);

ALTER TABLE tarifa_habitacion
    ADD CONSTRAINT fk_tarifa_tipo
    FOREIGN KEY (id_tipo_hab)
    REFERENCES tipo_habitacion (id_tipo_hab);

ALTER TABLE tarifa_habitacion
    ADD CONSTRAINT fk_tarifa_temporada
    FOREIGN KEY (id_temporada)
    REFERENCES temporada (id_temporada);

ALTER TABLE reserva
    ADD CONSTRAINT fk_reserva_huesped
    FOREIGN KEY (id_huesped)
    REFERENCES huesped (id_huesped);

ALTER TABLE reserva
    ADD CONSTRAINT fk_reserva_empleado
    FOREIGN KEY (id_empleado)
    REFERENCES empleado (id_empleado);

ALTER TABLE reserva
    ADD CONSTRAINT fk_reserva_estado
    FOREIGN KEY (id_estado_res)
    REFERENCES estado_reserva (id_estado_res);

ALTER TABLE detalle_reserva
    ADD CONSTRAINT fk_detalle_reserva
    FOREIGN KEY (id_reserva)
    REFERENCES reserva (id_reserva);

ALTER TABLE detalle_reserva
    ADD CONSTRAINT fk_detalle_habitacion
    FOREIGN KEY (id_habitacion)
    REFERENCES habitacion (id_habitacion);

ALTER TABLE estadia
    ADD CONSTRAINT fk_estadia_detalle
    FOREIGN KEY (id_detalle)
    REFERENCES detalle_reserva (id_detalle);

ALTER TABLE ocupante_estadia
    ADD CONSTRAINT fk_ocupante_estadia
    FOREIGN KEY (id_estadia)
    REFERENCES estadia (id_estadia);

ALTER TABLE auditoria_reserva
    ADD CONSTRAINT fk_auditoria_reserva
    FOREIGN KEY (id_reserva)
    REFERENCES reserva (id_reserva);

-- Permite saber que empleado realizo el cambio de estado.
ALTER TABLE auditoria_reserva
    ADD CONSTRAINT fk_auditoria_empleado
    FOREIGN KEY (id_empleado)
    REFERENCES empleado (id_empleado);

ALTER TABLE servicio_adicional
    ADD CONSTRAINT fk_servicio_categoria
    FOREIGN KEY (id_categoria)
    REFERENCES categoria_servicio (id_categoria);

ALTER TABLE consumo_servicio
    ADD CONSTRAINT fk_consumo_estadia
    FOREIGN KEY (id_estadia)
    REFERENCES estadia (id_estadia);

ALTER TABLE consumo_servicio
    ADD CONSTRAINT fk_consumo_servicio
    FOREIGN KEY (id_servicio)
    REFERENCES servicio_adicional (id_servicio);

ALTER TABLE cuenta_cobro
    ADD CONSTRAINT fk_cuenta_estadia
    FOREIGN KEY (id_estadia)
    REFERENCES estadia (id_estadia);

ALTER TABLE pago
    ADD CONSTRAINT fk_pago_cuenta
    FOREIGN KEY (id_cuenta)
    REFERENCES cuenta_cobro (id_cuenta);

ALTER TABLE pago
    ADD CONSTRAINT fk_pago_metodo
    FOREIGN KEY (id_metodo_pago)
    REFERENCES metodo_pago (id_metodo_pago);


-- ============================================================
-- 12. RESTRICCIONES CHECK
-- ============================================================

-- Una habitacion debe tener capacidad positiva.
ALTER TABLE tipo_habitacion
    ADD CONSTRAINT ck_tipo_hab_capacidad
    CHECK (capacidad_max > 0);

-- Una tarifa no puede tener precio negativo.
ALTER TABLE tarifa_habitacion
    ADD CONSTRAINT ck_tarifa_precio
    CHECK (precio_noche >= 0);

-- La temporada debe tener las fechas en orden.
ALTER TABLE temporada
    ADD CONSTRAINT ck_temporada_fechas
    CHECK (fecha_fin > fecha_inicio);

-- La salida debe ser posterior al ingreso.
ALTER TABLE detalle_reserva
    ADD CONSTRAINT ck_detalle_fechas
    CHECK (fec_salida > fec_ingreso);

-- El precio aplicado a una reserva no puede ser negativo.
ALTER TABLE detalle_reserva
    ADD CONSTRAINT ck_detalle_precio
    CHECK (precio_aplicado >= 0);

-- El precio actual de un servicio no puede ser negativo.
ALTER TABLE servicio_adicional
    ADD CONSTRAINT ck_servicio_precio
    CHECK (precio_actual >= 0);

-- La cantidad consumida debe ser mayor que cero.
ALTER TABLE consumo_servicio
    ADD CONSTRAINT ck_consumo_cantidad
    CHECK (cantidad > 0);

-- El precio cobrado por un consumo no puede ser negativo.
ALTER TABLE consumo_servicio
    ADD CONSTRAINT ck_consumo_precio
    CHECK (precio_cobrado >= 0);

-- Los valores de la cuenta no pueden ser negativos.
ALTER TABLE cuenta_cobro
    ADD CONSTRAINT ck_cuenta_subtotal_hab
    CHECK (subtotal_hab >= 0);

ALTER TABLE cuenta_cobro
    ADD CONSTRAINT ck_cuenta_subtotal_serv
    CHECK (subtotal_serv >= 0);

ALTER TABLE cuenta_cobro
    ADD CONSTRAINT ck_cuenta_total
    CHECK (monto_total >= 0);

-- Un pago debe tener un monto mayor que cero.
ALTER TABLE pago
    ADD CONSTRAINT ck_pago_monto
    CHECK (monto_pagado > 0);

-- El checkout puede ser NULL mientras la estadia siga activa.
-- Si existe, no puede ser anterior al checkin.
ALTER TABLE estadia
    ADD CONSTRAINT ck_estadia_fechas
    CHECK (
        checkout_real IS NULL
        OR checkout_real >= checkin_real
    );


-- ============================================================
-- 12. DATOS INICIALES
-- ============================================================
-- EXACTAMENTE 130 INSERT
-- Los datos se cargan respetando primero las tablas padre y
-- posteriormente las tablas que dependen de ellas.
-- ============================================================

-- ------------------------------------------------------------
-- PAIS (3)
-- ------------------------------------------------------------
INSERT INTO pais VALUES (1, 'Peru');
INSERT INTO pais VALUES (2, 'Chile');
INSERT INTO pais VALUES (3, 'Argentina');

-- ------------------------------------------------------------
-- CIUDAD (6)
-- ------------------------------------------------------------
INSERT INTO ciudad VALUES (1, 1, 'Lima');
INSERT INTO ciudad VALUES (2, 1, 'Arequipa');
INSERT INTO ciudad VALUES (3, 1, 'Cusco');
INSERT INTO ciudad VALUES (4, 2, 'Santiago');
INSERT INTO ciudad VALUES (5, 2, 'Valparaiso');
INSERT INTO ciudad VALUES (6, 3, 'Buenos Aires');

-- ------------------------------------------------------------
-- TIPO DOCUMENTO (3)
-- ------------------------------------------------------------
INSERT INTO tipo_documento VALUES (1, 'DNI');
INSERT INTO tipo_documento VALUES (2, 'Pasaporte');
INSERT INTO tipo_documento VALUES (3, 'Carnet de Extranjeria');

-- ------------------------------------------------------------
-- ESTADO HABITACION (3)
-- ------------------------------------------------------------
INSERT INTO estado_habitacion VALUES (1, 'Disponible');
INSERT INTO estado_habitacion VALUES (2, 'Ocupada');
INSERT INTO estado_habitacion VALUES (3, 'Mantenimiento');

-- ------------------------------------------------------------
-- ESTADO RESERVA (4)
-- ------------------------------------------------------------
INSERT INTO estado_reserva VALUES (1, 'Pendiente');
INSERT INTO estado_reserva VALUES (2, 'Confirmada');
INSERT INTO estado_reserva VALUES (3, 'Cancelada');
INSERT INTO estado_reserva VALUES (4, 'Finalizada');

-- ------------------------------------------------------------
-- CATEGORIA SERVICIO (3)
-- ------------------------------------------------------------
INSERT INTO categoria_servicio VALUES (1, 'Alimentos');
INSERT INTO categoria_servicio VALUES (2, 'Bebidas');
INSERT INTO categoria_servicio VALUES (3, 'Lavanderia');

-- ------------------------------------------------------------
-- METODO PAGO (3)
-- ------------------------------------------------------------
INSERT INTO metodo_pago VALUES (1, 'Efectivo');
INSERT INTO metodo_pago VALUES (2, 'Tarjeta');
INSERT INTO metodo_pago VALUES (3, 'Transferencia');

-- ------------------------------------------------------------
-- TEMPORADA (3)
-- ------------------------------------------------------------
INSERT INTO temporada VALUES (1, 'Baja 2026', DATE '2026-03-01', DATE '2026-06-30');
INSERT INTO temporada VALUES (2, 'Alta 2026', DATE '2026-07-01', DATE '2026-12-20');
INSERT INTO temporada VALUES (3, 'Festiva 2026', DATE '2026-12-21', DATE '2026-12-31');

-- ------------------------------------------------------------
-- HUESPED (10)
-- ------------------------------------------------------------
INSERT INTO huesped VALUES (1, 1, 1, '70000001', 'Ana Torres', '999111111');
INSERT INTO huesped VALUES (2, 1, 4, '70000002', 'Bruno Salazar', '999111112');
INSERT INTO huesped VALUES (3, 2, 2, 'P1000003', 'Carla Mendoza', '999111113');
INSERT INTO huesped VALUES (4, 1, 3, '70000004', 'Diego Rojas', '999111114');
INSERT INTO huesped VALUES (5, 3, 5, 'CE500005', 'Elena Vargas', '999111115');
INSERT INTO huesped VALUES (6, 1, 1, '70000006', 'Fabian Castro', '999111116');
INSERT INTO huesped VALUES (7, 2, 6, 'P1000007', 'Gabriela Ruiz', '999111117');
INSERT INTO huesped VALUES (8, 1, 2, '70000008', 'Hector Paredes', '999111118');
INSERT INTO huesped VALUES (9, 1, 4, '70000009', 'Irene Flores', '999111119');
INSERT INTO huesped VALUES (10, 3, 3, 'CE500010', 'Javier Molina', '999111120');

-- ------------------------------------------------------------
-- EMPLEADO (5)
-- ------------------------------------------------------------
INSERT INTO empleado VALUES (1, 'EMP-001', 'Luis Herrera', 'Recepcionista');
INSERT INTO empleado VALUES (2, 'EMP-002', 'Maria Soto', 'Recepcionista');
INSERT INTO empleado VALUES (3, 'EMP-003', 'Carlos Vega', 'Administrador');
INSERT INTO empleado VALUES (4, 'EMP-004', 'Paula Reyes', 'Encargada de reservas');
INSERT INTO empleado VALUES (5, 'EMP-005', 'Sergio Leon', 'Supervisor');

-- ------------------------------------------------------------
-- TIPO HABITACION (4)
-- ------------------------------------------------------------
INSERT INTO tipo_habitacion VALUES (1, 'Individual', 1);
INSERT INTO tipo_habitacion VALUES (2, 'Doble', 2);
INSERT INTO tipo_habitacion VALUES (3, 'Familiar', 4);
INSERT INTO tipo_habitacion VALUES (4, 'Suite', 3);

-- ------------------------------------------------------------
-- HABITACION (10)
-- ------------------------------------------------------------
INSERT INTO habitacion VALUES (1, 1, 1, '101', 1);
INSERT INTO habitacion VALUES (2, 1, 1, '102', 1);
INSERT INTO habitacion VALUES (3, 2, 1, '201', 2);
INSERT INTO habitacion VALUES (4, 2, 2, '202', 2);
INSERT INTO habitacion VALUES (5, 3, 1, '301', 3);
INSERT INTO habitacion VALUES (6, 3, 1, '302', 3);
INSERT INTO habitacion VALUES (7, 4, 1, '401', 4);
INSERT INTO habitacion VALUES (8, 2, 3, '203', 2);
INSERT INTO habitacion VALUES (9, 1, 1, '103', 1);
INSERT INTO habitacion VALUES (10, 3, 2, '303', 3);

-- ------------------------------------------------------------
-- TARIFA HABITACION (8)
-- ------------------------------------------------------------
INSERT INTO tarifa_habitacion VALUES (1, 1, 1, 80000);
INSERT INTO tarifa_habitacion VALUES (2, 1, 2, 95000);
INSERT INTO tarifa_habitacion VALUES (3, 2, 1, 110000);
INSERT INTO tarifa_habitacion VALUES (4, 2, 2, 135000);
INSERT INTO tarifa_habitacion VALUES (5, 3, 1, 150000);
INSERT INTO tarifa_habitacion VALUES (6, 3, 2, 180000);
INSERT INTO tarifa_habitacion VALUES (7, 4, 1, 220000);
INSERT INTO tarifa_habitacion VALUES (8, 4, 2, 260000);

-- ------------------------------------------------------------
-- RESERVA (12)
-- ------------------------------------------------------------
INSERT INTO reserva VALUES (1, 1, 1, 2, DATE '2026-08-01');
INSERT INTO reserva VALUES (2, 2, 2, 2, DATE '2026-08-02');
INSERT INTO reserva VALUES (3, 3, 1, 1, DATE '2026-08-03');
INSERT INTO reserva VALUES (4, 4, 3, 4, DATE '2026-07-20');
INSERT INTO reserva VALUES (5, 5, 4, 3, DATE '2026-08-05');
INSERT INTO reserva VALUES (6, 6, 2, 2, DATE '2026-08-06');
INSERT INTO reserva VALUES (7, 7, 5, 1, DATE '2026-08-07');
INSERT INTO reserva VALUES (8, 8, 1, 2, DATE '2026-08-08');
INSERT INTO reserva VALUES (9, 9, 4, 2, DATE '2026-08-09');
INSERT INTO reserva VALUES (10, 10, 3, 4, DATE '2026-07-25');
INSERT INTO reserva VALUES (11, 1, 2, 2, DATE '2026-08-10');
INSERT INTO reserva VALUES (12, 2, 5, 1, DATE '2026-08-11');

-- ------------------------------------------------------------
-- DETALLE RESERVA (12)
-- ------------------------------------------------------------
INSERT INTO detalle_reserva VALUES (1, 1, 1, DATE '2026-08-15', DATE '2026-08-17', 95000);
INSERT INTO detalle_reserva VALUES (2, 2, 3, DATE '2026-08-18', DATE '2026-08-20', 135000);
INSERT INTO detalle_reserva VALUES (3, 3, 5, DATE '2026-09-01', DATE '2026-09-04', 180000);
INSERT INTO detalle_reserva VALUES (4, 4, 6, DATE '2026-07-21', DATE '2026-07-23', 180000);
INSERT INTO detalle_reserva VALUES (5, 5, 7, DATE '2026-08-25', DATE '2026-08-27', 260000);
INSERT INTO detalle_reserva VALUES (6, 6, 2, DATE '2026-09-05', DATE '2026-09-08', 95000);
INSERT INTO detalle_reserva VALUES (7, 7, 9, DATE '2026-09-10', DATE '2026-09-12', 95000);
INSERT INTO detalle_reserva VALUES (8, 8, 4, DATE '2026-09-15', DATE '2026-09-18', 135000);
INSERT INTO detalle_reserva VALUES (9, 9, 1, DATE '2026-09-20', DATE '2026-09-22', 95000);
INSERT INTO detalle_reserva VALUES (10, 10, 6, DATE '2026-07-26', DATE '2026-07-29', 180000);
INSERT INTO detalle_reserva VALUES (11, 11, 3, DATE '2026-10-01', DATE '2026-10-03', 135000);
INSERT INTO detalle_reserva VALUES (12, 12, 5, DATE '2026-10-05', DATE '2026-10-08', 180000);

-- ------------------------------------------------------------
-- ESTADIA (8)
-- ------------------------------------------------------------
INSERT INTO estadia VALUES (1, 1, DATE '2026-08-15', DATE '2026-08-17');
INSERT INTO estadia VALUES (2, 2, DATE '2026-08-18', DATE '2026-08-20');
INSERT INTO estadia VALUES (3, 4, DATE '2026-07-21', DATE '2026-07-23');
INSERT INTO estadia VALUES (4, 6, DATE '2026-09-05', NULL);
INSERT INTO estadia VALUES (5, 7, DATE '2026-09-10', DATE '2026-09-12');
INSERT INTO estadia VALUES (6, 10, DATE '2026-07-26', DATE '2026-07-29');
INSERT INTO estadia VALUES (7, 11, DATE '2026-10-01', NULL);
INSERT INTO estadia VALUES (8, 12, DATE '2026-10-05', DATE '2026-10-08');

-- ------------------------------------------------------------
-- OCUPANTE ESTADIA (8)
-- ------------------------------------------------------------
INSERT INTO ocupante_estadia VALUES (1, 1, '70010001', 'Ana Torres');
INSERT INTO ocupante_estadia VALUES (2, 2, '70010002', 'Bruno Salazar');
INSERT INTO ocupante_estadia VALUES (3, 3, '70010003', 'Diego Rojas');
INSERT INTO ocupante_estadia VALUES (4, 4, '70010004', 'Fabian Castro');
INSERT INTO ocupante_estadia VALUES (5, 5, '70010005', 'Gabriela Ruiz');
INSERT INTO ocupante_estadia VALUES (6, 6, '70010006', 'Javier Molina');
INSERT INTO ocupante_estadia VALUES (7, 7, '70010007', 'Carla Mendoza');
INSERT INTO ocupante_estadia VALUES (8, 8, '70010008', 'Elena Vargas');

-- ------------------------------------------------------------
-- AUDITORIA RESERVA (5)
-- id_empleado queda registrado en cada auditoria.
-- ------------------------------------------------------------
INSERT INTO auditoria_reserva VALUES (1, 1, 1, 'Pendiente', 'Confirmada', DATE '2026-08-01');
INSERT INTO auditoria_reserva VALUES (2, 4, 3, 'Pendiente', 'Confirmada', DATE '2026-07-20');
INSERT INTO auditoria_reserva VALUES (3, 5, 4, 'Confirmada', 'Cancelada', DATE '2026-08-05');
INSERT INTO auditoria_reserva VALUES (4, 8, 1, 'Pendiente', 'Confirmada', DATE '2026-08-08');
INSERT INTO auditoria_reserva VALUES (5, 10, 3, 'Confirmada', 'Finalizada', DATE '2026-07-29');

-- ------------------------------------------------------------
-- SERVICIO ADICIONAL (5)
-- ------------------------------------------------------------
INSERT INTO servicio_adicional VALUES (1, 1, 'Desayuno', 25000);
INSERT INTO servicio_adicional VALUES (2, 1, 'Almuerzo', 35000);
INSERT INTO servicio_adicional VALUES (3, 2, 'Bebida', 8000);
INSERT INTO servicio_adicional VALUES (4, 3, 'Lavado de ropa', 20000);
INSERT INTO servicio_adicional VALUES (5, 2, 'Agua embotellada', 5000);

-- ------------------------------------------------------------
-- CONSUMO SERVICIO (7)
-- ------------------------------------------------------------
INSERT INTO consumo_servicio VALUES (1, 1, 1, 2, 25000);
INSERT INTO consumo_servicio VALUES (2, 1, 3, 3, 8000);
INSERT INTO consumo_servicio VALUES (3, 2, 2, 1, 35000);
INSERT INTO consumo_servicio VALUES (4, 3, 1, 2, 25000);
INSERT INTO consumo_servicio VALUES (5, 5, 4, 1, 20000);
INSERT INTO consumo_servicio VALUES (6, 6, 1, 2, 25000);
INSERT INTO consumo_servicio VALUES (7, 8, 5, 2, 5000);

-- ------------------------------------------------------------
-- CUENTA COBRO (5)
-- ------------------------------------------------------------
INSERT INTO cuenta_cobro VALUES (1, 1, 190000, 74000, 264000);
INSERT INTO cuenta_cobro VALUES (2, 2, 270000, 35000, 305000);
INSERT INTO cuenta_cobro VALUES (3, 3, 360000, 50000, 410000);
INSERT INTO cuenta_cobro VALUES (4, 5, 190000, 40000, 230000);
INSERT INTO cuenta_cobro VALUES (5, 6, 540000, 50000, 590000);

-- ------------------------------------------------------------
-- PAGO (3)
-- ------------------------------------------------------------
INSERT INTO pago VALUES (1, 1, 2, 100000, DATE '2026-08-16');
INSERT INTO pago VALUES (2, 2, 3, 150000, DATE '2026-08-19');
INSERT INTO pago VALUES (3, 5, 1, 200000, DATE '2026-07-28');

-- ============================================================
-- CONTROL DE CANTIDAD
-- ============================================================
-- Distribucion: 3+6+3+3+4+3+3+3+10+5+4+10+8+12+12+8+8+5+5+7+5+3 = 130
-- ============================================================

-- ============================================================
-- 13. SECUENCIAS
-- ============================================================
-- Se utilizan en las tablas donde el hotel generara nuevos
-- registros durante su funcionamiento.
--
-- Cada secuencia comienza despues del ultimo ID utilizado
-- por los 130 INSERT iniciales.
-- ============================================================

CREATE SEQUENCE seq_huesped
    START WITH 11
    INCREMENT BY 1;

CREATE SEQUENCE seq_empleado
    START WITH 6
    INCREMENT BY 1;

CREATE SEQUENCE seq_habitacion
    START WITH 11
    INCREMENT BY 1;

CREATE SEQUENCE seq_tarifa
    START WITH 9
    INCREMENT BY 1;

CREATE SEQUENCE seq_reserva
    START WITH 13
    INCREMENT BY 1;

CREATE SEQUENCE seq_detalle_reserva
    START WITH 13
    INCREMENT BY 1;

CREATE SEQUENCE seq_estadia
    START WITH 9
    INCREMENT BY 1;

CREATE SEQUENCE seq_ocupante_estadia
    START WITH 9
    INCREMENT BY 1;

CREATE SEQUENCE seq_auditoria
    START WITH 6
    INCREMENT BY 1;

CREATE SEQUENCE seq_servicio
    START WITH 6
    INCREMENT BY 1;

CREATE SEQUENCE seq_consumo
    START WITH 8
    INCREMENT BY 1;

CREATE SEQUENCE seq_cuenta
    START WITH 6
    INCREMENT BY 1;

CREATE SEQUENCE seq_pago
    START WITH 4
    INCREMENT BY 1;

COMMIT;

-- ============================================================
-- 14. REGLAS QUE QUEDAN PARA LA ETAPA DE PL/SQL
-- ============================================================
-- Estas reglas se implementaran posteriormente con PL/SQL:
-- 1. No permitir reservas superpuestas.
-- 2. No permitir check-in de una reserva cancelada.
-- 3. No permitir checkout sin check-in.
-- 4. Controlar que los pagos no superen la cuenta.
-- 5. Calcular y controlar montos de las cuentas.
-- 6. Auditar automaticamente cambios de estado.
-- 7. Registrar el empleado responsable en la auditoria.
-- ============================================================

-- ============================================================
-- FIN DE LA PARTE I - BASE DE DATOS
-- ============================================================


-- ============================================================
-- PARTE II - EJERCICIOS PL/SQL
-- ============================================================
-- A partir de aqui comienzan los 19 ejercicios de la primera evaluacion.
--
-- PASO 1: Ejecutar los ejercicios 1 al 19.
-- Esta entrega corresponde a la primera evaluacion.
-- ============================================================

-- ============================================================
-- PROYECTO: SISTEMA DE GESTION DE HOTEL
-- ETAPA: 19 EJERCICIOS PL/SQL - PRIMERA EVALUACION
-- ============================================================
-- Base de referencia:
-- 22 tablas + 130 INSERT + 13 secuencias
--
-- Orden de los ejercicios de esta entrega:
-- 1-3   Bloques anonimos
-- 4-5   RECORD
-- 6-7   VARRAY
-- 8-9   Cursores sin parametros
-- 10-11 Cursores con parametros
-- 12-13 LOOP
-- 14-15 LOOP anidado
-- 16    Cursor complejo
-- 17    Excepcion Oracle
-- 18-19 Excepciones propias
--
-- Los ejercicios 20 al 26 corresponden a una etapa posterior
-- del proyecto y no forman parte de esta entrega.
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- 1. BLOQUE ANONIMO - INICIO DEL SISTEMA
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hotel: sistema iniciado correctamente.');
    DBMS_OUTPUT.PUT_LINE('Primer ejercicio PL/SQL ejecutado.');
END;
/

-- Explicacion:
-- Un bloque anonimo ejecuta una logica puntual y no queda guardado
-- como objeto permanente en la base de datos.

-- ============================================================
-- 2. BLOQUE ANONIMO - CONSULTAR UN HUESPED
-- ============================================================
DECLARE
    v_nombre huesped.nombre_completo%TYPE;
BEGIN
    SELECT nombre_completo
    INTO v_nombre
    FROM huesped
    WHERE id_huesped = 1;

    DBMS_OUTPUT.PUT_LINE('Huesped: ' || v_nombre);
END;
/

-- Explicacion:
-- Se usa para realizar una consulta puntual y mostrar el resultado.

-- ============================================================
-- 3. BLOQUE ANONIMO - CALCULAR NOCHES
-- ============================================================
DECLARE
    v_ingreso DATE;
    v_salida  DATE;
    v_noches  NUMBER;
BEGIN
    SELECT fec_ingreso, fec_salida
    INTO v_ingreso, v_salida
    FROM detalle_reserva
    WHERE id_detalle = 1;

    v_noches := v_salida - v_ingreso;

    DBMS_OUTPUT.PUT_LINE('Noches de la reserva: ' || v_noches);
END;
/

-- Explicacion:
-- Calcula un dato temporal sin crear un procedimiento ni funcion.

-- ============================================================
-- 4. RECORD - INFORMACION DE UN HUESPED
-- ============================================================
DECLARE
    TYPE t_huesped IS RECORD (
        nombre   huesped.nombre_completo%TYPE,
        telefono huesped.telefono%TYPE
    );

    r_huesped t_huesped;
BEGIN
    SELECT nombre_completo, telefono
    INTO r_huesped.nombre, r_huesped.telefono
    FROM huesped
    WHERE id_huesped = 1;

    DBMS_OUTPUT.PUT_LINE('Nombre: ' || r_huesped.nombre);
    DBMS_OUTPUT.PUT_LINE('Telefono: ' || r_huesped.telefono);
END;
/

-- Explicacion:
-- RECORD agrupa varios valores que pertenecen a una misma fila.

-- ============================================================
-- 5. RECORD - INFORMACION DE UNA RESERVA
-- ============================================================
DECLARE
    TYPE t_reserva IS RECORD (
        id_reserva  reserva.id_reserva%TYPE,
        id_huesped  reserva.id_huesped%TYPE,
        id_empleado reserva.id_empleado%TYPE,
        estado      estado_reserva.nombre_estado%TYPE
    );

    r_reserva t_reserva;
BEGIN
    SELECT r.id_reserva,
           r.id_huesped,
           r.id_empleado,
           e.nombre_estado
    INTO r_reserva.id_reserva,
         r_reserva.id_huesped,
         r_reserva.id_empleado,
         r_reserva.estado
    FROM reserva r
    JOIN estado_reserva e
      ON e.id_estado_res = r.id_estado_res
    WHERE r.id_reserva = 1;

    DBMS_OUTPUT.PUT_LINE('Reserva: ' || r_reserva.id_reserva);
    DBMS_OUTPUT.PUT_LINE('Huesped: ' || r_reserva.id_huesped);
    DBMS_OUTPUT.PUT_LINE('Empleado: ' || r_reserva.id_empleado);
    DBMS_OUTPUT.PUT_LINE('Estado: ' || r_reserva.estado);
END;
/

-- Explicacion:
-- RECORD sirve cuando queremos manejar como una unidad los datos
-- de una fila o de una consulta que representa un solo registro.

-- ============================================================
-- 6. VARRAY - LISTA DE ESTADOS DE RESERVA
-- ============================================================
DECLARE
    TYPE t_estados IS VARRAY(4) OF VARCHAR2(30);

    v_estados t_estados := t_estados(
        'Pendiente',
        'Confirmada',
        'Cancelada',
        'Finalizada'
    );
BEGIN
    FOR i IN 1 .. v_estados.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(i || '. ' || v_estados(i));
    END LOOP;
END;
/

-- Explicacion:
-- VARRAY almacena una lista ordenada y de tamano limitado.
-- Es util para un conjunto pequeno de valores.

-- ============================================================
-- 7. VARRAY - SERVICIOS DE UNA CATEGORIA
-- ============================================================
DECLARE
    TYPE t_servicios IS VARRAY(5) OF VARCHAR2(100);

    v_servicios t_servicios;
BEGIN
    SELECT nombre_servicio
    BULK COLLECT INTO v_servicios
    FROM servicio_adicional
    WHERE id_categoria = 1
    ORDER BY id_servicio;

    FOR i IN 1 .. v_servicios.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Servicio: ' || v_servicios(i));
    END LOOP;
END;
/

-- Explicacion:
-- Aqui usamos VARRAY para guardar una lista pequena de servicios.
-- El limite de 5 es suficiente para nuestros datos actuales.

-- ============================================================
-- 8. CURSOR SIN PARAMETROS - HUESPEDES
-- ============================================================
DECLARE
    CURSOR c_huespedes IS
        SELECT id_huesped, nombre_completo
        FROM huesped
        ORDER BY id_huesped;

    v_id     huesped.id_huesped%TYPE;
    v_nombre huesped.nombre_completo%TYPE;
BEGIN
    OPEN c_huespedes;

    LOOP
        FETCH c_huespedes INTO v_id, v_nombre;
        EXIT WHEN c_huespedes%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(v_id || ' - ' || v_nombre);
    END LOOP;

    CLOSE c_huespedes;
END;
/

-- Explicacion:
-- Un cursor sin parametros recorre el resultado fijo de una consulta.

-- ============================================================
-- 9. CURSOR SIN PARAMETROS - RESERVAS
-- ============================================================
DECLARE
    CURSOR c_reservas IS
        SELECT r.id_reserva,
               h.nombre_completo,
               e.nombre_estado
        FROM reserva r
        JOIN huesped h
          ON h.id_huesped = r.id_huesped
        JOIN estado_reserva e
          ON e.id_estado_res = r.id_estado_res
        ORDER BY r.id_reserva;
BEGIN
    FOR registro IN c_reservas LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Reserva ' || registro.id_reserva ||
            ' - ' || registro.nombre_completo ||
            ' - ' || registro.nombre_estado
        );
    END LOOP;
END;
/

-- Explicacion:
-- Este cursor permite recorrer todas las reservas y mostrar su estado.

-- ============================================================
-- 10. CURSOR CON PARAMETROS - RESERVAS DE UN HUESPED
-- ============================================================
DECLARE
    CURSOR c_reservas(p_id_huesped NUMBER) IS
        SELECT id_reserva, id_estado_res
        FROM reserva
        WHERE id_huesped = p_id_huesped
        ORDER BY id_reserva;
BEGIN
    FOR registro IN c_reservas(1) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Reserva: ' || registro.id_reserva ||
            ' - Estado ID: ' || registro.id_estado_res
        );
    END LOOP;
END;
/

-- Explicacion:
-- El parametro permite reutilizar el mismo cursor para distintos huespedes.

-- ============================================================
-- 11. CURSOR CON PARAMETROS - HABITACIONES POR TIPO
-- ============================================================
DECLARE
    CURSOR c_habitaciones(p_tipo NUMBER) IS
        SELECT numero_hab, piso
        FROM habitacion
        WHERE id_tipo_hab = p_tipo
        ORDER BY numero_hab;
BEGIN
    FOR registro IN c_habitaciones(2) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Habitacion: ' || registro.numero_hab ||
            ' - Piso: ' || registro.piso
        );
    END LOOP;
END;
/

-- Explicacion:
-- Permite consultar habitaciones filtrando por el tipo recibido.

-- ============================================================
-- 12. LOOP - RECORRER TARIFAS
-- ============================================================
DECLARE
    v_id     tarifa_habitacion.id_tarifa%TYPE := 1;
    v_precio tarifa_habitacion.precio_noche%TYPE;
BEGIN
    LOOP
        SELECT precio_noche
        INTO v_precio
        FROM tarifa_habitacion
        WHERE id_tarifa = v_id;

        DBMS_OUTPUT.PUT_LINE(
            'Tarifa ' || v_id || ': ' || v_precio
        );

        v_id := v_id + 1;

        EXIT WHEN v_id > 8;
    END LOOP;
END;
/

-- Explicacion:
-- LOOP repite una operacion hasta que una condicion indica que debe salir.

-- ============================================================
-- 13. LOOP - RECORRER NOCHES
-- ============================================================
DECLARE
    v_noches NUMBER;
    v_dia    NUMBER := 1;
BEGIN
    SELECT fec_salida - fec_ingreso
    INTO v_noches
    FROM detalle_reserva
    WHERE id_detalle = 1;

    LOOP
        DBMS_OUTPUT.PUT_LINE('Noche ' || v_dia);

        v_dia := v_dia + 1;

        EXIT WHEN v_dia > v_noches;
    END LOOP;
END;
/

-- Explicacion:
-- El LOOP permite repetir una accion una cantidad determinada de veces.

-- ============================================================
-- 14. LOOP ANIDADO - TIPOS Y HABITACIONES
-- ============================================================
DECLARE
    v_hay_habitaciones BOOLEAN;
BEGIN
    FOR tipo IN (
        SELECT id_tipo_hab, nombre_tipo
        FROM tipo_habitacion
        ORDER BY id_tipo_hab
    ) LOOP

        DBMS_OUTPUT.PUT_LINE('Tipo: ' || tipo.nombre_tipo);

        v_hay_habitaciones := FALSE;

        FOR hab IN (
            SELECT numero_hab
            FROM habitacion
            WHERE id_tipo_hab = tipo.id_tipo_hab
            ORDER BY numero_hab
        ) LOOP

            v_hay_habitaciones := TRUE;

            DBMS_OUTPUT.PUT_LINE(
                '  Habitacion: ' || hab.numero_hab
            );
        END LOOP;

        IF NOT v_hay_habitaciones THEN
            DBMS_OUTPUT.PUT_LINE(
                '  Sin habitaciones registradas.'
            );
        END IF;

    END LOOP;
END;
/

-- Explicacion:
-- Un LOOP anidado es un recorrido dentro de otro recorrido.
-- Aqui recorremos tipos y, dentro de cada uno, sus habitaciones.

-- ============================================================
-- 15. LOOP ANIDADO - ESTADIAS Y SERVICIOS
-- ============================================================
BEGIN
    FOR est IN (
        SELECT id_estadia
        FROM estadia
        ORDER BY id_estadia
    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            'Estadia: ' || est.id_estadia
        );

        FOR consumo IN (
            SELECT s.nombre_servicio, c.cantidad
            FROM consumo_servicio c
            JOIN servicio_adicional s
              ON s.id_servicio = c.id_servicio
            WHERE c.id_estadia = est.id_estadia
            ORDER BY c.id_consumo
        ) LOOP

            DBMS_OUTPUT.PUT_LINE(
                '  ' || consumo.nombre_servicio ||
                ' - Cantidad: ' || consumo.cantidad
            );
        END LOOP;

    END LOOP;
END;
/

-- Explicacion:
-- Sirve para recorrer una relacion padre-hijo:
-- una estadia puede tener varios consumos.

-- ============================================================
-- 16. CURSOR COMPLEJO - DISPONIBILIDAD DE HABITACIONES
-- ============================================================
DECLARE
    CURSOR c_disponibilidad(
        p_ingreso DATE,
        p_salida  DATE
    ) IS
        SELECT h.id_habitacion,
               h.numero_hab,
               t.nombre_tipo,
               h.piso
        FROM habitacion h
        JOIN tipo_habitacion t
          ON t.id_tipo_hab = h.id_tipo_hab
        JOIN estado_habitacion eh
          ON eh.id_estado_hab = h.id_estado_hab
        WHERE eh.nombre_estado = 'Disponible'
          AND NOT EXISTS (
              SELECT 1
              FROM detalle_reserva d
              JOIN reserva r
                ON r.id_reserva = d.id_reserva
              JOIN estado_reserva er
                ON er.id_estado_res = r.id_estado_res
              WHERE d.id_habitacion = h.id_habitacion
                AND er.nombre_estado IN ('Pendiente', 'Confirmada')
                AND d.fec_ingreso < p_salida
                AND d.fec_salida > p_ingreso
          )
        ORDER BY h.numero_hab;
BEGIN
    FOR registro IN c_disponibilidad(
        DATE '2026-11-01',
        DATE '2026-11-03'
    ) LOOP

        DBMS_OUTPUT.PUT_LINE(
            'Disponible: ' || registro.numero_hab ||
            ' - ' || registro.nombre_tipo ||
            ' - Piso ' || registro.piso
        );

    END LOOP;
END;
/

-- Explicacion:
-- Es un cursor mas completo porque cruza varias tablas y aplica
-- una regla de negocio: evitar reservas superpuestas.

-- ============================================================
-- 17. EXCEPCION ORACLE - NO_DATA_FOUND
-- ============================================================
DECLARE
    v_nombre huesped.nombre_completo%TYPE;
BEGIN
    SELECT nombre_completo
    INTO v_nombre
    FROM huesped
    WHERE id_huesped = 999;

    DBMS_OUTPUT.PUT_LINE(v_nombre);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'No existe un huesped con ese ID.'
        );
END;
/

-- Explicacion:
-- NO_DATA_FOUND aparece cuando SELECT INTO no encuentra ninguna fila.

-- ============================================================
-- 18. EXCEPCION PROPIA - PAGO MAYOR QUE LA CUENTA
-- ============================================================
DECLARE
    e_pago_excesivo EXCEPTION;

    v_total  cuenta_cobro.monto_total%TYPE;
    v_pagado NUMBER;
BEGIN
    SELECT monto_total
    INTO v_total
    FROM cuenta_cobro
    WHERE id_cuenta = 1;

    SELECT NVL(SUM(monto_pagado), 0)
    INTO v_pagado
    FROM pago
    WHERE id_cuenta = 1;

    IF v_pagado > v_total THEN
        RAISE e_pago_excesivo;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Pago controlado correctamente. ' ||
        'Pagado: ' || v_pagado ||
        ' / Total: ' || v_total
    );

EXCEPTION
    WHEN e_pago_excesivo THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error: los pagos superan el total de la cuenta.'
        );
END;
/

-- Explicacion:
-- Una excepcion propia permite crear una regla especifica
-- para el negocio.

-- ============================================================
-- 19. EXCEPCION PROPIA - RESERVA CANCELADA
-- ============================================================
DECLARE
    e_reserva_cancelada EXCEPTION;
    v_estado             estado_reserva.nombre_estado%TYPE;
BEGIN
    SELECT e.nombre_estado
    INTO v_estado
    FROM reserva r
    JOIN estado_reserva e
      ON e.id_estado_res = r.id_estado_res
    WHERE r.id_reserva = 5;

    IF v_estado = 'Cancelada' THEN
        RAISE e_reserva_cancelada;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'La reserva puede continuar al proceso de check-in.'
    );

EXCEPTION
    WHEN e_reserva_cancelada THEN
        DBMS_OUTPUT.PUT_LINE(
            'No se puede realizar check-in: la reserva esta cancelada.'
        );
END;
/

-- Explicacion:
-- Esta excepcion representa directamente una regla de negocio
-- del hotel.

