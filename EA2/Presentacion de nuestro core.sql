-- =====================================================================
-- PROYECTO: SISTEMA DE GESTION DE HOTEL Y RESERVAS
-- Asignatura: Taller de Base de Datos
--
-- RESUMEN DEL PROYECTO COMPLETO:
--   * 22 tablas.
--   * 148 registros iniciales.
--   * 13 secuencias.
--   * 27 ejercicios/secciones de PL/SQL.

-- CORE DEL PROYECTO:
-- Gestionar el ciclo de una reserva hotelera, desde la reserva hasta
-- el alojamiento y el cobro de la estadia.
--
-- VALOR PARA EL NEGOCIO:
-- Evita errores de reserva, aplica reglas hoteleras automaticamente,
-- organiza el alojamiento, controla los cobros y permite trazabilidad.
--
-- ¿POR QUE ESTOS TRES PACKAGES?
-- PKG_RESERVAS: controla las reservas y la disponibilidad.
-- PKG_ESTADIAS: controla el ingreso, los ocupantes, los consumos y salida.
-- PKG_CUENTAS: calcula la cuenta, registra pagos y muestra la boleta.
-- Juntos representan el flujo principal: RESERVAR -> ALOJAR -> COBRAR.
-- =====================================================================

-- =====================================================================
-- PACKAGE 1: PKG_RESERVAS
-- ¿Que hace? Valida fechas, evita cruces, consulta disponibilidad y
-- permite confirmar o cancelar reservas.
-- Resultado esperado: saber que habitaciones pueden reservarse y
-- bloquear operaciones que incumplen las reglas de reserva del hotel.
-- =====================================================================
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


-- =====================================================================
-- PACKAGE 2: PKG_ESTADIAS
-- ¿Que hace? Gestiona check-in, registro de ocupantes, consumos y
-- check-out, aplicando las reglas del alojamiento.
-- Resultado esperado: registrar correctamente la estadia y sus consumos,
-- evitando ingresos no permitidos y operaciones fuera de tiempo.
-- =====================================================================
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


-- =====================================================================
-- PACKAGE 3: PKG_CUENTAS
-- ¿Que hace? Genera la cuenta de la estadia, registra pagos y muestra
-- el detalle de cargos, total pagado y saldo pendiente en la boleta.
-- Resultado esperado: conocer cuanto cuesta la estadia, cuanto se pago
-- y cuanto queda por pagar, con control de los cobros.
-- =====================================================================
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
