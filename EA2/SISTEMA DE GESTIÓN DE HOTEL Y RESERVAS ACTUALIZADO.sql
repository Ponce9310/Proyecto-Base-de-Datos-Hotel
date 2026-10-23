SET SERVEROUTPUT ON;

-- ============================================================
-- PROYECTO FINAL: SISTEMA DE GESTION DE HOTEL
-- ASIGNATURA: TALLER DE BASE DE DATOS
-- ============================================================
--
-- CONTENIDO:
--   PARTE I   - 22 tablas, 148 registros y 13 secuencias.
--   PARTE II  - Ejercicios 1 al 19: bloques anonimos, RECORD, VARRAY,
--               cursores, LOOP y excepciones.
--   PARTE III - Ejercicios 20 al 27: triggers, paquetes, funciones,
--               procedimientos, pruebas y prueba integrada.
--   Cada seccion explica brevemente la regla de negocio que aplica.
--
-- ORDEN DE EJECUCION:
--   Ejecutar el archivo completo, de arriba hacia abajo.
--
-- IMPORTANTE:
--   Este script reconstruye las tablas del hotel y reemplaza los
--   objetos PL/SQL del proyecto. Al ejecutarlo se eliminan los datos
--   anteriores de las tablas del hotel. Las pruebas finales
--   revierten sus propios datos.
--
-- REGLAS DE NEGOCIO DEL HOTEL:
--   1. Una reserva se hace para una sola habitacion (detalle_reserva).
--   2. No puede haber dos reservas activas (Pendiente o Confirmada)
--      de la misma habitacion en fechas que se crucen.
--      Si un huesped sale el dia que otro entra, no hay cruce.
--   3. Una habitacion en mantenimiento no se puede reservar.
--   4. El precio por noche depende del tipo de habitacion y de la
--      temporada en que cae la fecha de ingreso.
--   5. Estados de una reserva: Pendiente -> Confirmada -> Finalizada.
--      Desde Pendiente o Confirmada tambien se puede Cancelar.
--      Una reserva Cancelada o Finalizada ya no cambia de estado.
--   6. El check-in solo se hace con la reserva Confirmada, dentro de
--      sus fechas y con la habitacion Disponible.
--   7. El huesped titular queda registrado como primer ocupante.
--      Los ocupantes no pueden superar la capacidad del tipo de habitacion.
--   8. No se registran consumos despues del check-out.
--   9. La cuenta se genera al hacer check-out:
--      total = alojamiento + consumos.
--  10. Los pagos no pueden superar el saldo pendiente de la cuenta.
--  11. Todo cambio de estado de una reserva queda auditado.
-- ============================================================


-- ============================================================
-- PARTE I - BASE DE DATOS
-- ============================================================

-- ============================================================
-- 1. LIMPIEZA SEGURA DEL PROYECTO
-- Regla de negocio: permite reconstruir el sistema desde cero.
-- ATENCION: elimina los datos anteriores de las tablas del hotel.
-- ============================================================

DECLARE
    PROCEDURE drop_si_existe(p_sql VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            -- Se ignoran solo los errores de "el objeto no existe".
            IF SQLCODE NOT IN (-4043, -4080, -2289, -942) THEN
                RAISE;
            END IF;
    END;
BEGIN
    drop_si_existe('DROP TRIGGER TR_VALIDAR_FECHAS_DETALLE');
    drop_si_existe('DROP TRIGGER TR_VALIDAR_CAMBIO_ESTADO');
    drop_si_existe('DROP TRIGGER TR_AUDITAR_CAMBIO_RESERVA');

    drop_si_existe('DROP PACKAGE PKG_RESERVAS');
    drop_si_existe('DROP PACKAGE PKG_ESTADIAS');
    drop_si_existe('DROP PACKAGE PKG_CUENTAS');

    drop_si_existe('DROP FUNCTION FN_PRECIO_NOCHE');
    drop_si_existe('DROP FUNCTION FN_CALCULAR_NOCHES');
    drop_si_existe('DROP FUNCTION FN_SALDO_CUENTA');
    drop_si_existe('DROP FUNCTION FN_VALOR_ESTADIA');
    drop_si_existe('DROP FUNCTION FN_CONTAR_RESERVAS_PENDIENTES');

    drop_si_existe('DROP PROCEDURE PR_REGISTRAR_RESERVA');
    drop_si_existe('DROP PROCEDURE PR_REGISTRAR_PAGO');
    drop_si_existe('DROP PROCEDURE PR_LISTAR_RESERVAS_PENDIENTES');

    drop_si_existe('DROP SEQUENCE SEQ_HUESPED');
    drop_si_existe('DROP SEQUENCE SEQ_EMPLEADO');
    drop_si_existe('DROP SEQUENCE SEQ_HABITACION');
    drop_si_existe('DROP SEQUENCE SEQ_TARIFA');
    drop_si_existe('DROP SEQUENCE SEQ_RESERVA');
    drop_si_existe('DROP SEQUENCE SEQ_DETALLE_RESERVA');
    drop_si_existe('DROP SEQUENCE SEQ_ESTADIA');
    drop_si_existe('DROP SEQUENCE SEQ_OCUPANTE_ESTADIA');
    drop_si_existe('DROP SEQUENCE SEQ_AUDITORIA');
    drop_si_existe('DROP SEQUENCE SEQ_SERVICIO');
    drop_si_existe('DROP SEQUENCE SEQ_CONSUMO');
    drop_si_existe('DROP SEQUENCE SEQ_CUENTA');
    drop_si_existe('DROP SEQUENCE SEQ_PAGO');

    drop_si_existe('DROP TABLE PAGO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE CUENTA_COBRO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE CONSUMO_SERVICIO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE SERVICIO_ADICIONAL CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE CATEGORIA_SERVICIO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE OCUPANTE_ESTADIA CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE ESTADIA CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE AUDITORIA_RESERVA CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE DETALLE_RESERVA CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE RESERVA CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE TARIFA_HABITACION CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE TEMPORADA CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE HABITACION CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE ESTADO_HABITACION CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE TIPO_HABITACION CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE EMPLEADO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE HUESPED CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE CIUDAD CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE PAIS CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE TIPO_DOCUMENTO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE METODO_PAGO CASCADE CONSTRAINTS PURGE');
    drop_si_existe('DROP TABLE ESTADO_RESERVA CASCADE CONSTRAINTS PURGE');
END;
/


-- ============================================================
-- 2. TABLAS DE APOYO / CATALOGOS
-- Regla de negocio: mantiene catalogos de estados, paises,
-- temporadas y metodos de pago.
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
-- Regla de negocio: identifica a huespedes y empleados que
-- gestionan reservas.
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
-- Regla de negocio: cada habitacion tiene un tipo y su precio
-- depende de la temporada.
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
-- Regla de negocio: relaciona las reservas con habitacion,
-- fechas y estadias.
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
    num_doc_ocupante VARCHAR2(20) NOT NULL,
    nombre_ocupante VARCHAR2(100) NOT NULL
);


-- ============================================================
-- 6. AUDITORIA DE RESERVAS
-- Regla de negocio: conserva cada cambio de estado de una reserva
-- y el empleado responsable de ella.
-- ============================================================
-- Un TRIGGER llena esta tabla automaticamente (ver seccion 20).
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
-- Regla de negocio: registra servicios y consumos con cantidad
-- y precio cobrado.
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
-- Regla de negocio: separa los cargos de alojamiento, los consumos
-- y los pagos recibidos.
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
-- Regla de negocio: cada registro debe tener un identificador unico.
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
-- Regla de negocio: evita duplicados en datos que deben ser unicos.
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

-- Una reserva se hace para una sola habitacion.
ALTER TABLE detalle_reserva
    ADD CONSTRAINT uq_detalle_reserva
    UNIQUE (id_reserva);

-- Un detalle de reserva puede generar como maximo una estadia.
ALTER TABLE estadia
    ADD CONSTRAINT uq_estadia_detalle
    UNIQUE (id_detalle);

-- Un mismo documento no se repite como ocupante de una estadia.
ALTER TABLE ocupante_estadia
    ADD CONSTRAINT uq_ocupante_estadia_doc
    UNIQUE (id_estadia, num_doc_ocupante);

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
-- Regla de negocio: impide relacionar registros con huespedes,
-- reservas o cuentas inexistentes.
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

-- Permite saber que empleado es responsable de la reserva auditada.
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
-- Regla de negocio: rechaza valores invalidos, como montos
-- negativos o fechas incoherentes.
-- ============================================================

-- El RUT debe tener formato 12345678-9 (digito verificador 0-9 o K).
ALTER TABLE empleado
    ADD CONSTRAINT ck_empleado_rut
    CHECK (REGEXP_LIKE(rut_empleado, '^[0-9]{7,8}-[0-9K]$'));

-- Una habitacion debe tener capacidad positiva.
ALTER TABLE tipo_habitacion
    ADD CONSTRAINT ck_tipo_hab_capacidad
    CHECK (capacidad_max > 0);

-- El piso debe ser positivo.
ALTER TABLE habitacion
    ADD CONSTRAINT ck_habitacion_piso
    CHECK (piso > 0);

-- La temporada debe tener las fechas en orden.
ALTER TABLE temporada
    ADD CONSTRAINT ck_temporada_fechas
    CHECK (fecha_fin > fecha_inicio);

-- Una tarifa debe tener precio mayor que cero.
ALTER TABLE tarifa_habitacion
    ADD CONSTRAINT ck_tarifa_precio
    CHECK (precio_noche > 0);

-- La salida debe ser al menos un dia despues del ingreso.
ALTER TABLE detalle_reserva
    ADD CONSTRAINT ck_detalle_fechas
    CHECK (TRUNC(fec_salida) > TRUNC(fec_ingreso));

-- El precio aplicado a una reserva debe ser mayor que cero.
ALTER TABLE detalle_reserva
    ADD CONSTRAINT ck_detalle_precio
    CHECK (precio_aplicado > 0);

-- El checkout puede ser NULL mientras la estadia siga activa.
-- Si existe, no puede ser anterior al checkin.
ALTER TABLE estadia
    ADD CONSTRAINT ck_estadia_fechas
    CHECK (
        checkout_real IS NULL
        OR checkout_real >= checkin_real
    );

-- Una auditoria debe registrar un cambio real de estado.
ALTER TABLE auditoria_reserva
    ADD CONSTRAINT ck_auditoria_estados
    CHECK (estado_anterior <> estado_nuevo);

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

-- El total de la cuenta siempre es alojamiento + consumos.
ALTER TABLE cuenta_cobro
    ADD CONSTRAINT ck_cuenta_total_suma
    CHECK (monto_total = subtotal_hab + subtotal_serv);

-- Un pago debe tener un monto mayor que cero.
ALTER TABLE pago
    ADD CONSTRAINT ck_pago_monto
    CHECK (monto_pagado > 0);


-- ============================================================
-- 13. DATOS INICIALES
-- Regla de negocio: carga datos de ejemplo coherentes para probar
-- el flujo hotelero completo.
-- ============================================================
-- EXACTAMENTE 148 INSERT
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
-- Los periodos no se cruzan entre si.
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
-- El RUT tiene formato real, con digito verificador valido.
-- ------------------------------------------------------------
INSERT INTO empleado VALUES (1, '15234567-4', 'Luis Herrera', 'Recepcionista');
INSERT INTO empleado VALUES (2, '16345678-8', 'Maria Soto', 'Recepcionista');
INSERT INTO empleado VALUES (3, '17456789-1', 'Carlos Vega', 'Administrador');
INSERT INTO empleado VALUES (4, '14567890-0', 'Paula Reyes', 'Encargada de reservas');
INSERT INTO empleado VALUES (5, '18678901-6', 'Sergio Leon', 'Supervisor');

-- ------------------------------------------------------------
-- TIPO HABITACION (4)
-- ------------------------------------------------------------
INSERT INTO tipo_habitacion VALUES (1, 'Individual', 1);
INSERT INTO tipo_habitacion VALUES (2, 'Doble', 2);
INSERT INTO tipo_habitacion VALUES (3, 'Familiar', 4);
INSERT INTO tipo_habitacion VALUES (4, 'Suite', 3);

-- ------------------------------------------------------------
-- HABITACION (10)
-- Estado actual: 102 y 201 ocupadas (tienen una estadia abierta),
-- 203 en mantenimiento y el resto disponibles.
-- ------------------------------------------------------------
INSERT INTO habitacion VALUES (1, 1, 1, '101', 1);
INSERT INTO habitacion VALUES (2, 1, 2, '102', 1);
INSERT INTO habitacion VALUES (3, 2, 2, '201', 2);
INSERT INTO habitacion VALUES (4, 2, 1, '202', 2);
INSERT INTO habitacion VALUES (5, 3, 1, '301', 3);
INSERT INTO habitacion VALUES (6, 3, 1, '302', 3);
INSERT INTO habitacion VALUES (7, 4, 1, '401', 4);
INSERT INTO habitacion VALUES (8, 2, 3, '203', 2);
INSERT INTO habitacion VALUES (9, 1, 1, '103', 1);
INSERT INTO habitacion VALUES (10, 3, 1, '303', 3);

-- ------------------------------------------------------------
-- TARIFA HABITACION (12)
-- Cada tipo de habitacion tiene una tarifa en cada temporada.
-- Precios de ejemplo en pesos chilenos.
-- ------------------------------------------------------------
INSERT INTO tarifa_habitacion VALUES (1, 1, 1, 45000);
INSERT INTO tarifa_habitacion VALUES (2, 1, 2, 55000);
INSERT INTO tarifa_habitacion VALUES (3, 2, 1, 60000);
INSERT INTO tarifa_habitacion VALUES (4, 2, 2, 70000);
INSERT INTO tarifa_habitacion VALUES (5, 3, 1, 80000);
INSERT INTO tarifa_habitacion VALUES (6, 3, 2, 95000);
INSERT INTO tarifa_habitacion VALUES (7, 4, 1, 100000);
INSERT INTO tarifa_habitacion VALUES (8, 4, 2, 120000);
INSERT INTO tarifa_habitacion VALUES (9, 1, 3, 65000);
INSERT INTO tarifa_habitacion VALUES (10, 2, 3, 85000);
INSERT INTO tarifa_habitacion VALUES (11, 3, 3, 110000);
INSERT INTO tarifa_habitacion VALUES (12, 4, 3, 140000);

-- ------------------------------------------------------------
-- RESERVA (12)
-- 1 Pendiente, 4 Confirmadas, 1 Cancelada y 6 Finalizadas.
-- ------------------------------------------------------------
INSERT INTO reserva VALUES (1, 1, 1, 4, DATE '2026-08-01');
INSERT INTO reserva VALUES (2, 2, 2, 4, DATE '2026-08-02');
INSERT INTO reserva VALUES (3, 3, 1, 1, DATE '2026-08-03');
INSERT INTO reserva VALUES (4, 4, 3, 4, DATE '2026-07-20');
INSERT INTO reserva VALUES (5, 5, 4, 3, DATE '2026-08-05');
INSERT INTO reserva VALUES (6, 6, 2, 2, DATE '2026-08-06');
INSERT INTO reserva VALUES (7, 7, 5, 4, DATE '2026-08-07');
INSERT INTO reserva VALUES (8, 8, 1, 2, DATE '2026-08-08');
INSERT INTO reserva VALUES (9, 9, 4, 2, DATE '2026-08-09');
INSERT INTO reserva VALUES (10, 10, 3, 4, DATE '2026-07-25');
INSERT INTO reserva VALUES (11, 1, 2, 2, DATE '2026-08-10');
INSERT INTO reserva VALUES (12, 2, 5, 4, DATE '2026-08-11');

-- ------------------------------------------------------------
-- DETALLE RESERVA (12)
-- El precio aplicado es la tarifa de la temporada de ingreso.
-- ------------------------------------------------------------
INSERT INTO detalle_reserva VALUES (1, 1, 1, DATE '2026-08-15', DATE '2026-08-17', 55000);
INSERT INTO detalle_reserva VALUES (2, 2, 3, DATE '2026-08-18', DATE '2026-08-20', 70000);
INSERT INTO detalle_reserva VALUES (3, 3, 5, DATE '2026-09-01', DATE '2026-09-04', 95000);
INSERT INTO detalle_reserva VALUES (4, 4, 6, DATE '2026-07-21', DATE '2026-07-23', 95000);
INSERT INTO detalle_reserva VALUES (5, 5, 7, DATE '2026-08-25', DATE '2026-08-27', 120000);
INSERT INTO detalle_reserva VALUES (6, 6, 2, DATE '2026-09-05', DATE '2026-09-08', 55000);
INSERT INTO detalle_reserva VALUES (7, 7, 9, DATE '2026-09-10', DATE '2026-09-12', 55000);
INSERT INTO detalle_reserva VALUES (8, 8, 4, DATE '2026-09-15', DATE '2026-09-18', 70000);
INSERT INTO detalle_reserva VALUES (9, 9, 1, DATE '2026-09-20', DATE '2026-09-22', 55000);
INSERT INTO detalle_reserva VALUES (10, 10, 6, DATE '2026-07-26', DATE '2026-07-29', 95000);
INSERT INTO detalle_reserva VALUES (11, 11, 3, DATE '2026-10-01', DATE '2026-10-03', 70000);
INSERT INTO detalle_reserva VALUES (12, 12, 5, DATE '2026-10-05', DATE '2026-10-08', 95000);

-- ------------------------------------------------------------
-- ESTADIA (8)
-- Las estadias 4 y 7 siguen abiertas (sin checkout).
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
-- El ocupante es el huesped titular de la reserva, con su mismo documento.
-- ------------------------------------------------------------
INSERT INTO ocupante_estadia VALUES (1, 1, '70000001', 'Ana Torres');
INSERT INTO ocupante_estadia VALUES (2, 2, '70000002', 'Bruno Salazar');
INSERT INTO ocupante_estadia VALUES (3, 3, '70000004', 'Diego Rojas');
INSERT INTO ocupante_estadia VALUES (4, 4, '70000006', 'Fabian Castro');
INSERT INTO ocupante_estadia VALUES (5, 5, 'P1000007', 'Gabriela Ruiz');
INSERT INTO ocupante_estadia VALUES (6, 6, 'CE500010', 'Javier Molina');
INSERT INTO ocupante_estadia VALUES (7, 7, '70000001', 'Ana Torres');
INSERT INTO ocupante_estadia VALUES (8, 8, '70000002', 'Bruno Salazar');

-- ------------------------------------------------------------
-- AUDITORIA RESERVA (18)
-- Historial completo de cambios de estado de cada reserva.
-- El empleado es el responsable de la reserva.
-- La reserva 3 sigue Pendiente, por eso no tiene cambios.
-- ------------------------------------------------------------
INSERT INTO auditoria_reserva VALUES (1, 1, 1, 'Pendiente', 'Confirmada', DATE '2026-08-01');
INSERT INTO auditoria_reserva VALUES (2, 1, 1, 'Confirmada', 'Finalizada', DATE '2026-08-17');
INSERT INTO auditoria_reserva VALUES (3, 2, 2, 'Pendiente', 'Confirmada', DATE '2026-08-02');
INSERT INTO auditoria_reserva VALUES (4, 2, 2, 'Confirmada', 'Finalizada', DATE '2026-08-20');
INSERT INTO auditoria_reserva VALUES (5, 4, 3, 'Pendiente', 'Confirmada', DATE '2026-07-20');
INSERT INTO auditoria_reserva VALUES (6, 4, 3, 'Confirmada', 'Finalizada', DATE '2026-07-23');
INSERT INTO auditoria_reserva VALUES (7, 5, 4, 'Pendiente', 'Confirmada', DATE '2026-08-05');
INSERT INTO auditoria_reserva VALUES (8, 5, 4, 'Confirmada', 'Cancelada', DATE '2026-08-05');
INSERT INTO auditoria_reserva VALUES (9, 6, 2, 'Pendiente', 'Confirmada', DATE '2026-08-06');
INSERT INTO auditoria_reserva VALUES (10, 7, 5, 'Pendiente', 'Confirmada', DATE '2026-08-07');
INSERT INTO auditoria_reserva VALUES (11, 7, 5, 'Confirmada', 'Finalizada', DATE '2026-09-12');
INSERT INTO auditoria_reserva VALUES (12, 8, 1, 'Pendiente', 'Confirmada', DATE '2026-08-08');
INSERT INTO auditoria_reserva VALUES (13, 9, 4, 'Pendiente', 'Confirmada', DATE '2026-08-09');
INSERT INTO auditoria_reserva VALUES (14, 10, 3, 'Pendiente', 'Confirmada', DATE '2026-07-25');
INSERT INTO auditoria_reserva VALUES (15, 10, 3, 'Confirmada', 'Finalizada', DATE '2026-07-29');
INSERT INTO auditoria_reserva VALUES (16, 11, 2, 'Pendiente', 'Confirmada', DATE '2026-08-10');
INSERT INTO auditoria_reserva VALUES (17, 12, 5, 'Pendiente', 'Confirmada', DATE '2026-08-11');
INSERT INTO auditoria_reserva VALUES (18, 12, 5, 'Confirmada', 'Finalizada', DATE '2026-10-08');

-- ------------------------------------------------------------
-- SERVICIO ADICIONAL (5)
-- Precios de ejemplo en pesos chilenos.
-- ------------------------------------------------------------
INSERT INTO servicio_adicional VALUES (1, 1, 'Desayuno', 8000);
INSERT INTO servicio_adicional VALUES (2, 1, 'Almuerzo', 12000);
INSERT INTO servicio_adicional VALUES (3, 2, 'Bebida', 2500);
INSERT INTO servicio_adicional VALUES (4, 3, 'Lavado de ropa', 8000);
INSERT INTO servicio_adicional VALUES (5, 2, 'Agua embotellada', 1500);

-- ------------------------------------------------------------
-- CONSUMO SERVICIO (7)
-- ------------------------------------------------------------
INSERT INTO consumo_servicio VALUES (1, 1, 1, 2, 8000);
INSERT INTO consumo_servicio VALUES (2, 1, 3, 3, 2500);
INSERT INTO consumo_servicio VALUES (3, 2, 2, 1, 12000);
INSERT INTO consumo_servicio VALUES (4, 3, 1, 2, 8000);
INSERT INTO consumo_servicio VALUES (5, 5, 4, 1, 8000);
INSERT INTO consumo_servicio VALUES (6, 6, 1, 2, 8000);
INSERT INTO consumo_servicio VALUES (7, 8, 5, 2, 1500);

-- ------------------------------------------------------------
-- CUENTA COBRO (6)
-- Hay una cuenta por cada estadia con checkout.
-- total = alojamiento + consumos.
-- ------------------------------------------------------------
INSERT INTO cuenta_cobro VALUES (1, 1, 110000, 23500, 133500);
INSERT INTO cuenta_cobro VALUES (2, 2, 140000, 12000, 152000);
INSERT INTO cuenta_cobro VALUES (3, 3, 190000, 16000, 206000);
INSERT INTO cuenta_cobro VALUES (4, 5, 110000, 8000, 118000);
INSERT INTO cuenta_cobro VALUES (5, 6, 285000, 16000, 301000);
INSERT INTO cuenta_cobro VALUES (6, 8, 285000, 3000, 288000);

-- ------------------------------------------------------------
-- PAGO (3)
-- Los pagos se registran desde el dia del checkout, cuando
-- ya existe la cuenta, y no superan el total.
-- ------------------------------------------------------------
INSERT INTO pago VALUES (1, 1, 2, 100000, DATE '2026-08-17');
INSERT INTO pago VALUES (2, 2, 3, 150000, DATE '2026-08-20');
INSERT INTO pago VALUES (3, 5, 1, 200000, DATE '2026-07-29');

-- ============================================================
-- CONTROL DE CANTIDAD
-- ============================================================
-- Distribucion: 3+6+3+3+4+3+3+3+10+5+4+10+12+12+12+8+8+18+5+7+6+3 = 148
-- ============================================================

-- ============================================================
-- 14. SECUENCIAS
-- Regla de negocio: genera identificadores para nuevos registros.
-- ============================================================
-- Se utilizan en las tablas donde el hotel generara nuevos
-- registros durante su funcionamiento.
--
-- Cada secuencia comienza despues del ultimo ID utilizado
-- por los 148 INSERT iniciales.
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
    START WITH 13
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
    START WITH 19
    INCREMENT BY 1;

CREATE SEQUENCE seq_servicio
    START WITH 6
    INCREMENT BY 1;

CREATE SEQUENCE seq_consumo
    START WITH 8
    INCREMENT BY 1;

CREATE SEQUENCE seq_cuenta
    START WITH 7
    INCREMENT BY 1;

CREATE SEQUENCE seq_pago
    START WITH 4
    INCREMENT BY 1;

COMMIT;

-- ============================================================
-- 15. REGLAS QUE SE CONTROLAN CON PL/SQL
-- Regla de negocio: documenta los controles que necesitan logica
-- que un CHECK o un UNIQUE no pueden resolver por si solos.
-- ============================================================
-- 1. No permitir reservas superpuestas ni de habitaciones en mantenimiento.
-- 2. Calcular el precio segun el tipo de habitacion y la temporada.
-- 3. Validar los cambios de estado de una reserva.
-- 4. No permitir check-in de una reserva cancelada o no confirmada.
-- 5. No permitir ocupantes sobre la capacidad ni consumos tras el check-out.
-- 6. Controlar que los pagos no superen la cuenta.
-- 7. Calcular los montos de las cuentas.
-- 8. Auditar automaticamente los cambios de estado.
-- ============================================================

-- ============================================================
-- FIN DE LA PARTE I - BASE DE DATOS
-- ============================================================


-- ============================================================
-- PARTE II - EJERCICIOS PL/SQL (PRIMERA EVALUACION)
-- ============================================================
-- Base de referencia:
-- 22 tablas + 148 INSERT + 13 secuencias
--
-- Orden de los ejercicios:
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
-- ============================================================

-- ============================================================
-- 1. BLOQUE ANONIMO - INICIO DEL SISTEMA
-- Regla de negocio: comprueba la ejecución básica de PL/SQL.
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
-- Regla de negocio: consulta los datos de un huésped existente.
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
-- Regla de negocio: calcula noches a partir de las fechas de reserva.
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
-- Regla de negocio: agrupa los datos principales de un huésped.
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
-- Regla de negocio: agrupa los datos de una reserva para consultarlos juntos.
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
-- Regla de negocio: representa los estados posibles de una reserva.
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
-- Regla de negocio: agrupa una lista limitada de servicios de una categoría.
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
-- Regla de negocio: recorre los huéspedes registrados.
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
-- Regla de negocio: recorre las reservas registradas para su revisión.
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
-- Regla de negocio: muestra las reservas del huésped indicado.
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
-- Regla de negocio: lista las habitaciones de un tipo específico.
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
-- Regla de negocio: recorre las tarifas registradas para revisarlas.
-- ============================================================
DECLARE
    v_id     tarifa_habitacion.id_tarifa%TYPE := 1;
    v_ultimo tarifa_habitacion.id_tarifa%TYPE;
    v_precio tarifa_habitacion.precio_noche%TYPE;
BEGIN
    -- El ultimo ID se consulta, asi el LOOP sigue sirviendo
    -- aunque se agreguen nuevas tarifas.
    SELECT MAX(id_tarifa)
    INTO v_ultimo
    FROM tarifa_habitacion;

    LOOP
        SELECT precio_noche
        INTO v_precio
        FROM tarifa_habitacion
        WHERE id_tarifa = v_id;

        DBMS_OUTPUT.PUT_LINE(
            'Tarifa ' || v_id || ': ' || v_precio
        );

        v_id := v_id + 1;

        EXIT WHEN v_id > v_ultimo;
    END LOOP;
END;
/

-- Explicacion:
-- LOOP repite una operacion hasta que una condicion indica que debe salir.

-- ============================================================
-- 13. LOOP - RECORRER NOCHES
-- Regla de negocio: cuenta las noches de una estadía.
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
-- Regla de negocio: relaciona tipos de habitación con sus habitaciones.
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
-- Regla de negocio: revisa los servicios asociados a cada estadía.
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
-- Regla de negocio: identifica habitaciones libres para las fechas
-- consultadas. Una habitacion en mantenimiento no se ofrece, y una
-- reserva activa que se cruza con las fechas la deja ocupada.
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
        WHERE eh.nombre_estado <> 'Mantenimiento'
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
-- No se filtra por "Disponible" porque ese es el estado de HOY:
-- una habitacion ocupada hoy puede estar libre en otras fechas.
-- Solo se excluye "Mantenimiento".

-- ============================================================
-- 17. EXCEPCION ORACLE - NO_DATA_FOUND
-- Regla de negocio: informa cuando no existe el registro consultado.
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
-- Regla de negocio: impide pagos superiores al saldo pendiente.
-- ============================================================
DECLARE
    e_pago_excesivo EXCEPTION;

    v_total       cuenta_cobro.monto_total%TYPE;
    v_pagado      NUMBER;
    v_saldo       NUMBER;
    v_nuevo_pago  NUMBER := 50000;  -- pago que se intenta registrar
BEGIN
    SELECT monto_total
    INTO v_total
    FROM cuenta_cobro
    WHERE id_cuenta = 1;

    SELECT NVL(SUM(monto_pagado), 0)
    INTO v_pagado
    FROM pago
    WHERE id_cuenta = 1;

    v_saldo := v_total - v_pagado;

    IF v_nuevo_pago > v_saldo THEN
        RAISE e_pago_excesivo;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Pago aceptado. Saldo pendiente: ' || v_saldo
    );

EXCEPTION
    WHEN e_pago_excesivo THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error: el pago de ' || v_nuevo_pago ||
            ' supera el saldo pendiente de ' || v_saldo || '.'
        );
END;
/

-- Explicacion:
-- Una excepcion propia permite crear una regla especifica
-- para el negocio. Aqui la cuenta 1 tiene saldo 33500, por eso
-- un pago de 50000 se rechaza. Prueba con 20000 para verlo aceptado.

-- ============================================================
-- 19. EXCEPCION PROPIA - RESERVA CANCELADA
-- Regla de negocio: impide continuar con una reserva cancelada.
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

-- ============================================================
-- PARTE III - TRIGGERS, PAQUETES, FUNCIONES Y PROCEDIMIENTOS
-- ============================================================
-- Estados de reserva:     1 Pendiente, 2 Confirmada, 3 Cancelada, 4 Finalizada
-- Estados de habitacion:  1 Disponible, 2 Ocupada, 3 Mantenimiento
-- ============================================================

-- ============================================================
-- 20. TRIGGERS DEL HOTEL
-- Regla de negocio: valida los cambios de estado de una reserva
-- y audita cada cambio automaticamente.
-- ============================================================

-- Valida que el cambio de estado sea permitido.
-- Permitidos: Pendiente -> Confirmada o Cancelada
--             Confirmada -> Finalizada o Cancelada
CREATE OR REPLACE TRIGGER tr_validar_cambio_estado
BEFORE UPDATE OF id_estado_res ON reserva
FOR EACH ROW
WHEN (OLD.id_estado_res <> NEW.id_estado_res)
BEGIN
    IF :OLD.id_estado_res IN (3, 4) THEN
        RAISE_APPLICATION_ERROR(-20030,
            'Una reserva cancelada o finalizada no puede cambiar de estado.');
    ELSIF :OLD.id_estado_res = 1 AND :NEW.id_estado_res = 4 THEN
        RAISE_APPLICATION_ERROR(-20031,
            'Una reserva pendiente debe confirmarse antes de finalizar.');
    ELSIF :OLD.id_estado_res = 2 AND :NEW.id_estado_res = 1 THEN
        RAISE_APPLICATION_ERROR(-20032,
            'Una reserva confirmada no puede volver a pendiente.');
    END IF;
END;
/

-- Guarda en la auditoria cada cambio de estado.
-- El empleado registrado es el responsable de la reserva.
CREATE OR REPLACE TRIGGER tr_auditar_cambio_reserva
AFTER UPDATE OF id_estado_res ON reserva
FOR EACH ROW
WHEN (OLD.id_estado_res <> NEW.id_estado_res)
DECLARE
    v_anterior estado_reserva.nombre_estado%TYPE;
    v_nuevo    estado_reserva.nombre_estado%TYPE;
BEGIN
    SELECT nombre_estado INTO v_anterior
    FROM estado_reserva WHERE id_estado_res = :OLD.id_estado_res;

    SELECT nombre_estado INTO v_nuevo
    FROM estado_reserva WHERE id_estado_res = :NEW.id_estado_res;

    INSERT INTO auditoria_reserva
        (id_auditoria, id_reserva, id_empleado, estado_anterior, estado_nuevo, fecha_cambio)
    VALUES
        (seq_auditoria.NEXTVAL, :NEW.id_reserva, :NEW.id_empleado,
         v_anterior, v_nuevo, SYSDATE);
END;
/

-- ============================================================
-- 21. PAQUETE DE RESERVAS
-- Regla de negocio: valida fechas y disponibilidad, y controla
-- la confirmacion y cancelacion de reservas.
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_reservas AS
    FUNCTION hay_cruce(p_habitacion NUMBER, p_ingreso DATE, p_salida DATE) RETURN BOOLEAN;
    PROCEDURE validar_reserva(p_habitacion NUMBER, p_ingreso DATE, p_salida DATE);
    PROCEDURE consultar_disponibilidad(p_ingreso DATE, p_salida DATE);
    PROCEDURE confirmar_reserva(p_id_reserva NUMBER);
    PROCEDURE cancelar_reserva(p_id_reserva NUMBER);
END pkg_reservas;
/

CREATE OR REPLACE PACKAGE BODY pkg_reservas AS

    -- Indica si la habitacion ya tiene una reserva activa (Pendiente o
    -- Confirmada) que se cruce con las fechas. Si un huesped sale el
    -- mismo dia que otro entra, no se considera cruce.
    FUNCTION hay_cruce(p_habitacion NUMBER, p_ingreso DATE, p_salida DATE) RETURN BOOLEAN IS
        v_cruces NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cruces
        FROM detalle_reserva d
        JOIN reserva r ON r.id_reserva = d.id_reserva
        WHERE d.id_habitacion = p_habitacion
          AND r.id_estado_res IN (1, 2)
          AND TRUNC(p_ingreso) < TRUNC(d.fec_salida)
          AND TRUNC(p_salida) > TRUNC(d.fec_ingreso);

        RETURN v_cruces > 0;
    END hay_cruce;

    -- Si la reserva no es valida, termina con un error.
    PROCEDURE validar_reserva(p_habitacion NUMBER, p_ingreso DATE, p_salida DATE) IS
        v_estado_hab NUMBER;
    BEGIN
        IF p_ingreso IS NULL OR p_salida IS NULL
           OR TRUNC(p_salida) <= TRUNC(p_ingreso) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Las fechas de reserva no son validas.');
        END IF;

        SELECT id_estado_hab INTO v_estado_hab
        FROM habitacion WHERE id_habitacion = p_habitacion;

        IF v_estado_hab = 3 THEN
            RAISE_APPLICATION_ERROR(-20007, 'La habitacion esta en mantenimiento.');
        END IF;

        IF hay_cruce(p_habitacion, p_ingreso, p_salida) THEN
            RAISE_APPLICATION_ERROR(-20002, 'La habitacion ya esta reservada en esas fechas.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'La habitacion indicada no existe.');
    END validar_reserva;

    -- Muestra las habitaciones que se pueden reservar en ese rango de fechas.
    PROCEDURE consultar_disponibilidad(p_ingreso DATE, p_salida DATE) IS
        v_cantidad NUMBER := 0;
    BEGIN
        IF p_ingreso IS NULL OR p_salida IS NULL OR TRUNC(p_salida) <= TRUNC(p_ingreso) THEN
            RAISE_APPLICATION_ERROR(-20003, 'Ingrese un rango de fechas valido.');
        END IF;

        FOR h IN (
            SELECT id_habitacion, numero_hab
            FROM habitacion
            WHERE id_estado_hab <> 3
            ORDER BY numero_hab
        ) LOOP
            IF NOT hay_cruce(h.id_habitacion, p_ingreso, p_salida) THEN
                DBMS_OUTPUT.PUT_LINE('Habitacion disponible: ' || h.numero_hab);
                v_cantidad := v_cantidad + 1;
            END IF;
        END LOOP;

        IF v_cantidad = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No hay habitaciones disponibles para esas fechas.');
        END IF;
    END consultar_disponibilidad;

    -- Pasa una reserva de Pendiente a Confirmada.
    PROCEDURE confirmar_reserva(p_id_reserva NUMBER) IS
        v_estado NUMBER;
    BEGIN
        SELECT id_estado_res INTO v_estado
        FROM reserva WHERE id_reserva = p_id_reserva;

        IF v_estado <> 1 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Solo se pueden confirmar reservas pendientes.');
        END IF;

        UPDATE reserva SET id_estado_res = 2
        WHERE id_reserva = p_id_reserva;

        DBMS_OUTPUT.PUT_LINE('Reserva confirmada: ' || p_id_reserva);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'No existe la reserva indicada.');
    END confirmar_reserva;

    -- Cancela una reserva pendiente o confirmada que aun no tiene check-in.
    PROCEDURE cancelar_reserva(p_id_reserva NUMBER) IS
        v_estado   NUMBER;
        v_estadias NUMBER;
    BEGIN
        SELECT id_estado_res INTO v_estado
        FROM reserva WHERE id_reserva = p_id_reserva;

        IF v_estado NOT IN (1, 2) THEN
            RAISE_APPLICATION_ERROR(-20008, 'Solo se pueden cancelar reservas pendientes o confirmadas.');
        END IF;

        SELECT COUNT(*) INTO v_estadias
        FROM estadia e
        JOIN detalle_reserva d ON d.id_detalle = e.id_detalle
        WHERE d.id_reserva = p_id_reserva;

        IF v_estadias > 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'No se puede cancelar una reserva con check-in realizado.');
        END IF;

        UPDATE reserva SET id_estado_res = 3
        WHERE id_reserva = p_id_reserva;

        DBMS_OUTPUT.PUT_LINE('Reserva cancelada: ' || p_id_reserva);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'No existe la reserva indicada.');
    END cancelar_reserva;
END pkg_reservas;
/

-- ============================================================
-- 22. PAQUETE DE ESTADIAS
-- Regla de negocio: controla check-in, ocupantes, consumos y check-out.
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_estadias AS
    PROCEDURE registrar_checkin(p_id_reserva NUMBER);
    PROCEDURE registrar_ocupante(p_id_estadia NUMBER, p_num_doc VARCHAR2, p_nombre VARCHAR2);
    PROCEDURE registrar_consumo(p_id_estadia NUMBER, p_id_servicio NUMBER, p_cantidad NUMBER);
    PROCEDURE registrar_checkout(p_id_estadia NUMBER);
END pkg_estadias;
/

CREATE OR REPLACE PACKAGE BODY pkg_estadias AS

    -- El check-in exige reserva confirmada, fechas vigentes y habitacion disponible.
    -- El huesped titular queda registrado como primer ocupante.
    PROCEDURE registrar_checkin(p_id_reserva NUMBER) IS
        v_estado     NUMBER;
        v_detalle    NUMBER;
        v_habitacion NUMBER;
        v_estado_hab NUMBER;
        v_existe     NUMBER;
        v_estadia    NUMBER;
        v_ingreso    DATE;
        v_salida     DATE;
        v_doc        huesped.num_doc%TYPE;
        v_nombre     huesped.nombre_completo%TYPE;
    BEGIN
        SELECT id_estado_res INTO v_estado
        FROM reserva WHERE id_reserva = p_id_reserva;

        IF v_estado = 3 THEN
            RAISE_APPLICATION_ERROR(-20010, 'No se puede hacer check-in de una reserva cancelada.');
        ELSIF v_estado <> 2 THEN
            RAISE_APPLICATION_ERROR(-20011, 'La reserva debe estar confirmada.');
        END IF;

        SELECT id_detalle, id_habitacion, fec_ingreso, fec_salida
        INTO v_detalle, v_habitacion, v_ingreso, v_salida
        FROM detalle_reserva WHERE id_reserva = p_id_reserva;

        IF TRUNC(SYSDATE) < TRUNC(v_ingreso) OR TRUNC(SYSDATE) >= TRUNC(v_salida) THEN
            RAISE_APPLICATION_ERROR(-20019, 'El check-in debe realizarse dentro de las fechas reservadas.');
        END IF;

        SELECT COUNT(*) INTO v_existe FROM estadia WHERE id_detalle = v_detalle;
        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'La reserva ya tiene una estadia.');
        END IF;

        SELECT id_estado_hab INTO v_estado_hab
        FROM habitacion WHERE id_habitacion = v_habitacion;

        IF v_estado_hab <> 1 THEN
            RAISE_APPLICATION_ERROR(-20040, 'La habitacion no esta disponible para el check-in.');
        END IF;

        SELECT h.num_doc, h.nombre_completo
        INTO v_doc, v_nombre
        FROM reserva r
        JOIN huesped h ON h.id_huesped = r.id_huesped
        WHERE r.id_reserva = p_id_reserva;

        v_estadia := seq_estadia.NEXTVAL;

        INSERT INTO estadia (id_estadia, id_detalle, checkin_real, checkout_real)
        VALUES (v_estadia, v_detalle, SYSDATE, NULL);

        INSERT INTO ocupante_estadia (id_ocupante, id_estadia, num_doc_ocupante, nombre_ocupante)
        VALUES (seq_ocupante_estadia.NEXTVAL, v_estadia, v_doc, v_nombre);

        UPDATE habitacion SET id_estado_hab = 2
        WHERE id_habitacion = v_habitacion;

        DBMS_OUTPUT.PUT_LINE('Check-in registrado para la reserva ' || p_id_reserva);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20013, 'No existe la reserva o su detalle.');
    END registrar_checkin;

    -- Agrega un ocupante a una estadia activa sin superar la capacidad de la habitacion.
    PROCEDURE registrar_ocupante(p_id_estadia NUMBER, p_num_doc VARCHAR2, p_nombre VARCHAR2) IS
        v_checkout  DATE;
        v_capacidad NUMBER;
        v_ocupantes NUMBER;
    BEGIN
        SELECT e.checkout_real, t.capacidad_max
        INTO v_checkout, v_capacidad
        FROM estadia e
        JOIN detalle_reserva d ON d.id_detalle = e.id_detalle
        JOIN habitacion h ON h.id_habitacion = d.id_habitacion
        JOIN tipo_habitacion t ON t.id_tipo_hab = h.id_tipo_hab
        WHERE e.id_estadia = p_id_estadia;

        IF v_checkout IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20042, 'No se puede agregar ocupantes despues del check-out.');
        END IF;

        SELECT COUNT(*) INTO v_ocupantes
        FROM ocupante_estadia WHERE id_estadia = p_id_estadia;

        IF v_ocupantes >= v_capacidad THEN
            RAISE_APPLICATION_ERROR(-20043, 'Se supera la capacidad maxima de la habitacion.');
        END IF;

        INSERT INTO ocupante_estadia (id_ocupante, id_estadia, num_doc_ocupante, nombre_ocupante)
        VALUES (seq_ocupante_estadia.NEXTVAL, p_id_estadia, p_num_doc, p_nombre);

        DBMS_OUTPUT.PUT_LINE('Ocupante registrado correctamente.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20041, 'No existe la estadia indicada.');
    END registrar_ocupante;

    -- El consumo se cobra al precio actual del servicio y solo con la estadia abierta.
    PROCEDURE registrar_consumo(p_id_estadia NUMBER, p_id_servicio NUMBER, p_cantidad NUMBER) IS
        v_precio   NUMBER;
        v_checkout DATE;
    BEGIN
        -- Auditoria: rechazar cantidades nulas, cero o negativas.
        IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20014, 'La cantidad debe ser mayor que cero.');
        END IF;

        SELECT checkout_real INTO v_checkout
        FROM estadia WHERE id_estadia = p_id_estadia;

        IF v_checkout IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20015, 'No se puede agregar consumo despues del check-out.');
        END IF;

        SELECT precio_actual INTO v_precio
        FROM servicio_adicional WHERE id_servicio = p_id_servicio;

        INSERT INTO consumo_servicio
            (id_consumo, id_estadia, id_servicio, cantidad, precio_cobrado)
        VALUES
            (seq_consumo.NEXTVAL, p_id_estadia, p_id_servicio, p_cantidad, v_precio);

        DBMS_OUTPUT.PUT_LINE('Consumo registrado correctamente.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20016, 'No existe la estadia o el servicio.');
    END registrar_consumo;

    -- El check-out cierra la estadia, libera la habitacion y finaliza la reserva.
    PROCEDURE registrar_checkout(p_id_estadia NUMBER) IS
        v_habitacion NUMBER;
        v_reserva    NUMBER;
        v_checkout   DATE;
    BEGIN
        SELECT d.id_habitacion, d.id_reserva, e.checkout_real
        INTO v_habitacion, v_reserva, v_checkout
        FROM estadia e
        JOIN detalle_reserva d ON d.id_detalle = e.id_detalle
        WHERE e.id_estadia = p_id_estadia;

        IF v_checkout IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20017, 'El check-out ya fue registrado.');
        END IF;

        UPDATE estadia SET checkout_real = SYSDATE WHERE id_estadia = p_id_estadia;
        UPDATE habitacion SET id_estado_hab = 1 WHERE id_habitacion = v_habitacion;
        UPDATE reserva SET id_estado_res = 4 WHERE id_reserva = v_reserva;

        DBMS_OUTPUT.PUT_LINE('Check-out registrado correctamente.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20018, 'No existe la estadia indicada.');
    END registrar_checkout;
END pkg_estadias;
/

-- ============================================================
-- 23. FUNCIONES DEL HOTEL
-- Regla de negocio: calcula precio por noche, noches, valor de
-- estadia, saldo y reservas pendientes.
-- ============================================================

-- Busca la tarifa del tipo de habitacion en la temporada de esa fecha.
CREATE OR REPLACE FUNCTION fn_precio_noche(p_id_tipo_hab NUMBER, p_fecha DATE)
RETURN NUMBER
IS
    v_precio NUMBER;
BEGIN
    SELECT t.precio_noche INTO v_precio
    FROM tarifa_habitacion t
    JOIN temporada te ON te.id_temporada = t.id_temporada
    WHERE t.id_tipo_hab = p_id_tipo_hab
      AND TRUNC(p_fecha) BETWEEN te.fecha_inicio AND te.fecha_fin;

    RETURN v_precio;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20028, 'No hay tarifa para la fecha de ingreso.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20033, 'Hay mas de una tarifa para la fecha de ingreso.');
END;
/

CREATE OR REPLACE FUNCTION fn_calcular_noches(p_id_detalle NUMBER)
RETURN NUMBER
IS
    v_ingreso DATE;
    v_salida  DATE;
BEGIN
    SELECT fec_ingreso, fec_salida INTO v_ingreso, v_salida
    FROM detalle_reserva WHERE id_detalle = p_id_detalle;

    IF TRUNC(v_salida) <= TRUNC(v_ingreso) THEN
        RAISE_APPLICATION_ERROR(-20020, 'La salida debe ser posterior al ingreso.');
    END IF;

    RETURN TRUNC(v_salida) - TRUNC(v_ingreso);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'No existe el detalle de reserva.');
END;
/

CREATE OR REPLACE FUNCTION fn_valor_estadia(p_id_detalle NUMBER)
RETURN NUMBER
IS
    v_noches NUMBER;
    v_precio NUMBER;
BEGIN
    v_noches := fn_calcular_noches(p_id_detalle);

    SELECT precio_aplicado INTO v_precio
    FROM detalle_reserva WHERE id_detalle = p_id_detalle;

    RETURN v_noches * v_precio;
END;
/

CREATE OR REPLACE FUNCTION fn_saldo_cuenta(p_id_cuenta NUMBER)
RETURN NUMBER
IS
    v_total  NUMBER;
    v_pagado NUMBER;
BEGIN
    SELECT monto_total INTO v_total
    FROM cuenta_cobro WHERE id_cuenta = p_id_cuenta;

    SELECT NVL(SUM(monto_pagado), 0) INTO v_pagado
    FROM pago WHERE id_cuenta = p_id_cuenta;

    RETURN v_total - v_pagado;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20022, 'No existe la cuenta.');
END;
/

CREATE OR REPLACE FUNCTION fn_contar_reservas_pendientes(p_id_huesped NUMBER)
RETURN NUMBER
IS
    v_cantidad NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cantidad
    FROM reserva
    WHERE id_huesped = p_id_huesped AND id_estado_res = 1;

    RETURN v_cantidad;
END;
/

-- ============================================================
-- 24. PAQUETE DE CUENTAS
-- Regla de negocio: calcula cuentas, controla pagos y muestra la boleta.
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_cuentas AS
    PROCEDURE generar_cuenta(p_id_estadia NUMBER);
    PROCEDURE registrar_pago(p_id_cuenta NUMBER, p_id_metodo NUMBER, p_monto NUMBER);
    PROCEDURE mostrar_boleta(p_id_cuenta NUMBER);
END pkg_cuentas;
/

CREATE OR REPLACE PACKAGE BODY pkg_cuentas AS

    -- La cuenta se genera despues del check-out: alojamiento + consumos.
    PROCEDURE generar_cuenta(p_id_estadia NUMBER) IS
        v_detalle     NUMBER;
        v_alojamiento NUMBER;
        v_servicios   NUMBER;
        v_existe      NUMBER;
        v_total       NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_existe FROM cuenta_cobro WHERE id_estadia = p_id_estadia;
        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'La estadia ya tiene una cuenta.');
        END IF;

        SELECT id_detalle INTO v_detalle
        FROM estadia
        WHERE id_estadia = p_id_estadia AND checkout_real IS NOT NULL;

        v_alojamiento := fn_valor_estadia(v_detalle);

        SELECT NVL(SUM(cantidad * precio_cobrado), 0) INTO v_servicios
        FROM consumo_servicio WHERE id_estadia = p_id_estadia;

        v_total := v_alojamiento + v_servicios;

        INSERT INTO cuenta_cobro
            (id_cuenta, id_estadia, subtotal_hab, subtotal_serv, monto_total)
        VALUES
            (seq_cuenta.NEXTVAL, p_id_estadia, v_alojamiento, v_servicios, v_total);

        DBMS_OUTPUT.PUT_LINE('Cuenta generada. Total: ' || v_total);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20024, 'La estadia no existe o aun no tiene check-out.');
    END generar_cuenta;

    -- Un pago debe ser positivo y no puede superar el saldo pendiente.
    PROCEDURE registrar_pago(p_id_cuenta NUMBER, p_id_metodo NUMBER, p_monto NUMBER) IS
        v_saldo NUMBER;
    BEGIN
        -- Auditoria: rechazar montos nulos, cero o negativos.
        IF p_monto IS NULL OR p_monto <= 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'El pago debe ser mayor que cero.');
        END IF;

        v_saldo := fn_saldo_cuenta(p_id_cuenta);
        IF p_monto > v_saldo THEN
            RAISE_APPLICATION_ERROR(-20026, 'El pago supera el saldo pendiente.');
        END IF;

        INSERT INTO pago (id_pago, id_cuenta, id_metodo_pago, monto_pagado, fecha_pago)
        VALUES (seq_pago.NEXTVAL, p_id_cuenta, p_id_metodo, p_monto, SYSDATE);

        DBMS_OUTPUT.PUT_LINE('Pago registrado. Saldo pendiente: ' || (v_saldo - p_monto));
    END registrar_pago;

    PROCEDURE mostrar_boleta(p_id_cuenta NUMBER) IS
        v_huesped VARCHAR2(100);
        v_habitacion VARCHAR2(10);
        v_tipo_habitacion VARCHAR2(50);
        v_ingreso DATE;
        v_salida DATE;
        v_noches NUMBER;
        v_alojamiento NUMBER;
        v_servicios NUMBER;
        v_total NUMBER;
        v_pagado NUMBER;
    BEGIN
        SELECT h.nombre_completo, hab.numero_hab, th.nombre_tipo,
               d.fec_ingreso, d.fec_salida,
               c.subtotal_hab, c.subtotal_serv, c.monto_total
        INTO v_huesped, v_habitacion, v_tipo_habitacion,
             v_ingreso, v_salida, v_alojamiento, v_servicios, v_total
        FROM cuenta_cobro c
        JOIN estadia e ON e.id_estadia = c.id_estadia
        JOIN detalle_reserva d ON d.id_detalle = e.id_detalle
        JOIN reserva r ON r.id_reserva = d.id_reserva
        JOIN huesped h ON h.id_huesped = r.id_huesped
        JOIN habitacion hab ON hab.id_habitacion = d.id_habitacion
        JOIN tipo_habitacion th ON th.id_tipo_hab = hab.id_tipo_hab
        WHERE c.id_cuenta = p_id_cuenta;

        SELECT NVL(SUM(monto_pagado), 0) INTO v_pagado
        FROM pago WHERE id_cuenta = p_id_cuenta;

        v_noches := TRUNC(v_salida) - TRUNC(v_ingreso);

        DBMS_OUTPUT.PUT_LINE('================================================');
        DBMS_OUTPUT.PUT_LINE('                 BOLETA DEL HOTEL               ');
        DBMS_OUTPUT.PUT_LINE('================================================');
        DBMS_OUTPUT.PUT_LINE('DATOS DEL HUESPED');
        DBMS_OUTPUT.PUT_LINE('Huesped: ' || v_huesped);
        DBMS_OUTPUT.PUT_LINE('Habitacion: ' || v_habitacion);
        DBMS_OUTPUT.PUT_LINE('Tipo de habitacion: ' || v_tipo_habitacion);
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('DETALLE DE LA ESTADIA');
        DBMS_OUTPUT.PUT_LINE('Ingreso: ' || TO_CHAR(v_ingreso, 'DD-MM-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Salida: ' || TO_CHAR(v_salida, 'DD-MM-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Noches: ' || v_noches);
        DBMS_OUTPUT.PUT_LINE('Alojamiento: $' || v_alojamiento);
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('DETALLE DE CONSUMOS');

        FOR s IN (
            SELECT sa.nombre_servicio, cs.cantidad,
                   cs.precio_cobrado, cs.cantidad * cs.precio_cobrado AS subtotal
            FROM consumo_servicio cs
            JOIN servicio_adicional sa ON sa.id_servicio = cs.id_servicio
            JOIN cuenta_cobro c ON c.id_estadia = cs.id_estadia
            WHERE c.id_cuenta = p_id_cuenta
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(s.nombre_servicio || ' (' || s.cantidad || ' unidad/es): $' || s.subtotal);
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('Subtotal consumos: $' || v_servicios);
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('RESUMEN DE LA CUENTA');
        DBMS_OUTPUT.PUT_LINE('Alojamiento: $' || v_alojamiento);
        DBMS_OUTPUT.PUT_LINE('Consumos: $' || v_servicios);
        DBMS_OUTPUT.PUT_LINE('TOTAL: $' || v_total);
        DBMS_OUTPUT.PUT_LINE('Pagado: $' || v_pagado);
        DBMS_OUTPUT.PUT_LINE('SALDO PENDIENTE: $' || (v_total - v_pagado));
        DBMS_OUTPUT.PUT_LINE('================================================');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20027, 'No existe la cuenta indicada.');
    END mostrar_boleta;
END pkg_cuentas;
/

-- ============================================================
-- 25. PROCEDIMIENTOS DE APOYO
-- Regla de negocio: permite registrar y consultar reservas con
-- operaciones simples.
-- ============================================================

-- Registra una reserva Pendiente. Aplica estas reglas:
--   * La fecha de ingreso no puede ser anterior a hoy.
--   * La habitacion debe existir, no estar en mantenimiento y no cruzarse con otra reserva.
--   * El precio es la tarifa de la temporada de la fecha de ingreso.
CREATE OR REPLACE PROCEDURE pr_registrar_reserva(
    p_id_huesped    NUMBER,
    p_id_empleado   NUMBER,
    p_id_habitacion NUMBER,
    p_ingreso       DATE,
    p_salida        DATE
)
IS
    v_tipo    NUMBER;
    v_precio  NUMBER;
    v_reserva NUMBER;
BEGIN
    IF TRUNC(p_ingreso) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20034, 'No se puede reservar con una fecha de ingreso pasada.');
    END IF;

    pkg_reservas.validar_reserva(p_id_habitacion, p_ingreso, p_salida);

    SELECT id_tipo_hab INTO v_tipo
    FROM habitacion WHERE id_habitacion = p_id_habitacion;

    v_precio := fn_precio_noche(v_tipo, p_ingreso);

    v_reserva := seq_reserva.NEXTVAL;
    INSERT INTO reserva (id_reserva, id_huesped, id_empleado, id_estado_res, fecha_registro)
    VALUES (v_reserva, p_id_huesped, p_id_empleado, 1, SYSDATE);

    INSERT INTO detalle_reserva
        (id_detalle, id_reserva, id_habitacion, fec_ingreso, fec_salida, precio_aplicado)
    VALUES
        (seq_detalle_reserva.NEXTVAL, v_reserva, p_id_habitacion,
         TRUNC(p_ingreso), TRUNC(p_salida), v_precio);

    DBMS_OUTPUT.PUT_LINE('Reserva registrada: ' || v_reserva);
END;
/

CREATE OR REPLACE PROCEDURE pr_listar_reservas_pendientes
IS
    v_total NUMBER := 0;
BEGIN
    FOR r IN (
        SELECT re.id_reserva, hu.nombre_completo, re.fecha_registro
        FROM reserva re
        JOIN huesped hu ON hu.id_huesped = re.id_huesped
        WHERE re.id_estado_res = 1
        ORDER BY re.fecha_registro
    ) LOOP
        v_total := v_total + 1;
        DBMS_OUTPUT.PUT_LINE('Reserva ' || r.id_reserva || ' - ' ||
            r.nombre_completo || ' - ' || TO_CHAR(r.fecha_registro, 'DD-MM-YYYY'));
    END LOOP;

    IF v_total = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No hay reservas pendientes.');
    END IF;
END;
/

-- ============================================================
-- 26. PRUEBAS DE REGLAS DE NEGOCIO
-- Regla de negocio: comprueba que se rechacen fechas, reservas,
-- cambios de estado, ocupantes y pagos invalidos.
-- Cada prueba debe mostrar el error esperado.
-- ============================================================
BEGIN
    -- Prueba 1: la salida es anterior al ingreso.
    BEGIN
        pkg_reservas.validar_reserva(1, DATE '2026-10-20', DATE '2026-10-19');
        DBMS_OUTPUT.PUT_LINE('Prueba 1 - ERROR: debio rechazar las fechas.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 1 - fechas invalidas: ' || SQLERRM);
    END;

    -- Prueba 2: la habitacion 203 (id 8) esta en mantenimiento.
    BEGIN
        pkg_reservas.validar_reserva(8, DATE '2026-11-01', DATE '2026-11-03');
        DBMS_OUTPUT.PUT_LINE('Prueba 2 - ERROR: debio rechazar la habitacion.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 2 - mantenimiento: ' || SQLERRM);
    END;

    -- Prueba 3: la habitacion 202 (id 4) tiene la reserva 8 del 15 al 18 de septiembre.
    BEGIN
        pkg_reservas.validar_reserva(4, DATE '2026-09-16', DATE '2026-09-17');
        DBMS_OUTPUT.PUT_LINE('Prueba 3 - ERROR: debio rechazar el cruce.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 3 - reserva superpuesta: ' || SQLERRM);
    END;

    -- Prueba 4: no se reserva con fecha de ingreso pasada.
    BEGIN
        pr_registrar_reserva(1, 1, 1, DATE '2026-01-10', DATE '2026-01-12');
        DBMS_OUTPUT.PUT_LINE('Prueba 4 - ERROR: debio rechazar la fecha pasada.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 4 - fecha pasada: ' || SQLERRM);
    END;

    -- Prueba 5: la reserva 5 esta cancelada y no admite check-in.
    BEGIN
        pkg_estadias.registrar_checkin(5);
        DBMS_OUTPUT.PUT_LINE('Prueba 5 - ERROR: debio rechazar el check-in.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 5 - reserva cancelada: ' || SQLERRM);
    END;

    -- Prueba 6: la reserva 5 ya esta cancelada y no se puede cancelar de nuevo.
    BEGIN
        pkg_reservas.cancelar_reserva(5);
        DBMS_OUTPUT.PUT_LINE('Prueba 6 - ERROR: debio rechazar la cancelacion.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 6 - cancelar dos veces: ' || SQLERRM);
    END;

    -- Prueba 7: una reserva cancelada no puede volver a confirmarse.
    BEGIN
        UPDATE reserva SET id_estado_res = 2 WHERE id_reserva = 5;
        DBMS_OUTPUT.PUT_LINE('Prueba 7 - ERROR: debio rechazar el cambio de estado.');
        ROLLBACK;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 7 - cambio de estado: ' || SQLERRM);
    END;

    -- Prueba 8: la estadia 4 es de una habitacion individual (capacidad 1) y ya tiene un ocupante.
    BEGIN
        pkg_estadias.registrar_ocupante(4, 'X0000001', 'Invitado de Prueba');
        DBMS_OUTPUT.PUT_LINE('Prueba 8 - ERROR: debio rechazar el ocupante.');
        ROLLBACK;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 8 - capacidad maxima: ' || SQLERRM);
    END;

    -- Prueba 9: el pago supera el saldo de la cuenta 1.
    BEGIN
        pkg_cuentas.registrar_pago(1, 1, 999999999);
        DBMS_OUTPUT.PUT_LINE('Prueba 9 - ERROR: debio rechazar el pago.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 9 - pago excesivo: ' || SQLERRM);
    END;
END;
/

-- ============================================================
-- 27. PRUEBA INTEGRADA DEL HOTEL
-- Regla de negocio: prueba el flujo completo y revierte los datos
-- de prueba al terminar.
-- Flujo: reserva -> confirmacion -> check-in -> consumo ->
--        check-out -> cuenta -> pago -> boleta.
-- ============================================================
DECLARE
    v_habitacion NUMBER;
    v_reserva    NUMBER;
    v_estadia    NUMBER;
    v_cuenta     NUMBER;
    v_total      NUMBER;
    v_ingreso    DATE := TRUNC(SYSDATE);
    v_salida     DATE := TRUNC(SYSDATE) + 1;
BEGIN
    SAVEPOINT inicio_prueba_hotel;

    -- Busca la primera habitacion disponible hoy sin cruce de reservas.
    FOR h IN (
        SELECT id_habitacion
        FROM habitacion
        WHERE id_estado_hab = 1
        ORDER BY id_habitacion
    ) LOOP
        IF NOT pkg_reservas.hay_cruce(h.id_habitacion, v_ingreso, v_salida) THEN
            v_habitacion := h.id_habitacion;
            EXIT;
        END IF;
    END LOOP;

    IF v_habitacion IS NULL THEN
        RAISE_APPLICATION_ERROR(-20029, 'No hay habitaciones disponibles para la prueba.');
    END IF;

    pr_registrar_reserva(1, 1, v_habitacion, v_ingreso, v_salida);
    v_reserva := seq_reserva.CURRVAL;

    pkg_reservas.confirmar_reserva(v_reserva);
    pkg_estadias.registrar_checkin(v_reserva);

    SELECT e.id_estadia INTO v_estadia
    FROM estadia e
    JOIN detalle_reserva d ON d.id_detalle = e.id_detalle
    WHERE d.id_reserva = v_reserva;

    pkg_estadias.registrar_consumo(v_estadia, 1, 1);
    pkg_estadias.registrar_checkout(v_estadia);
    pkg_cuentas.generar_cuenta(v_estadia);

    SELECT id_cuenta, monto_total INTO v_cuenta, v_total
    FROM cuenta_cobro WHERE id_estadia = v_estadia;

    pkg_cuentas.registrar_pago(v_cuenta, 1, ROUND(v_total / 2));
    pkg_cuentas.mostrar_boleta(v_cuenta);

    ROLLBACK TO inicio_prueba_hotel;
    DBMS_OUTPUT.PUT_LINE('PRUEBA INTEGRADA COMPLETADA. Datos de prueba revertidos.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_prueba_hotel;
        DBMS_OUTPUT.PUT_LINE('ERROR EN PRUEBA INTEGRADA: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Los cambios de esta prueba fueron revertidos.');
END;
/
