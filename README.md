# 🏨 Sistema de Gestión de Hotel y Reservas

## 📌 Descripción del proyecto

Este proyecto consiste en el diseño e implementación de una base de datos para un **Sistema de Gestión de Hotel y Reservas**, desarrollado con Oracle SQL y PL/SQL.

Su propósito es organizar y administrar los procesos principales de un hotel, incluyendo huéspedes, habitaciones, reservas, estadías, servicios adicionales, consumos, cuentas, pagos y auditoría.

Además, incorpora reglas de negocio mediante procedimientos, funciones, paquetes PL/SQL y triggers, con el objetivo de mantener la integridad de la información y controlar las operaciones del sistema.

## 🎯 Objetivo general

Diseñar e implementar una base de datos relacional que permita gestionar de forma organizada el ciclo de una reserva hotelera, desde su registro hasta el cobro de la estadía, aplicando reglas de negocio que representen el funcionamiento de un hotel.

## 🔄 Flujo principal del negocio

El funcionamiento general del sistema se representa mediante el siguiente flujo:

**Huésped → Reserva → Habitación → Estadía → Servicios y consumos → Cuenta → Pago**

Este flujo permite relacionar las operaciones principales del hotel y comprender cómo la información se utiliza durante todo el proceso de alojamiento.

## 💡 Core del proyecto

El core del sistema consiste en gestionar el ciclo completo de una reserva hotelera, desde su registro y validación hasta la administración de la estadía y el cobro correspondiente.

Para representar esta lógica, el proyecto se centra en tres paquetes PL/SQL principales:

- **`PKG_RESERVAS`:** valida reservas, controla las fechas, consulta la disponibilidad y gestiona la confirmación o cancelación.
- **`PKG_ESTADIAS`:** administra el check-in, el registro de ocupantes, los consumos y el check-out.
- **`PKG_CUENTAS`:** gestiona las cuentas, los pagos y la presentación de la boleta.

Estos paquetes permiten organizar la lógica del negocio y separar las responsabilidades de cada proceso.

## 🏢 Valor que aporta al negocio

El sistema busca aportar valor a la gestión hotelera mediante:

- **Prevención de errores:** valida fechas y evita conflictos entre reservas.
- **Automatización de reglas:** aplica controles durante las operaciones del hotel.
- **Control financiero:** organiza las cuentas, los pagos y los saldos pendientes.
- **Trazabilidad:** registra determinados cambios para facilitar el seguimiento de las operaciones.
- **Organización de la información:** relaciona huéspedes, habitaciones, reservas y estadías en una base de datos estructurada.

## 🗄️ Base de datos

La base de datos contempla entidades relacionadas con los principales procesos del hotel, entre ellas:

- Huéspedes y empleados.
- Habitaciones, tipos de habitación y estados.
- Reservas y detalles de reserva.
- Estadías y ocupantes.
- Servicios adicionales y consumos.
- Cuentas de cobro y pagos.
- Auditoría de reservas.
- Tarifas y temporadas.

Las entidades se relacionan mediante claves primarias y foráneas, según el diseño implementado.

## ⚙️ Tecnologías utilizadas

- **Oracle Database:** administración de la base de datos relacional.
- **SQL:** definición, consulta y manipulación de datos.
- **PL/SQL:** implementación de reglas de negocio mediante funciones, procedimientos, paquetes y triggers.
- **GitHub:** almacenamiento y organización de los archivos del proyecto.

## 📂 Estructura del repositorio

```text
Proyecto-Base-de-Datos-Hotel/
│
├── EA1/
│   ├── BD/
│   ├── DOCUMENTACION/
│   ├── MODELOS/
│   └── PRESENTACION/
│
├── EA2/
│   └── Archivos SQL y documentación de la evaluación
│
└── README.md
```

La estructura representa la organización general del repositorio. Dentro de cada carpeta se encuentran los archivos correspondientes a las actividades y entregables de cada evaluación.

## 🎓 Contexto académico

Este proyecto se desarrolla como parte de una actividad académica de bases de datos. Su finalidad es aplicar conocimientos de modelado relacional, SQL y PL/SQL a un caso práctico de gestión hotelera, considerando tanto la estructura de los datos como las reglas del negocio.

## ✅ Resultado esperado

Contar con una base de datos capaz de representar los procesos principales de un hotel, mantener relacionadas sus operaciones y aplicar controles para gestionar las reservas, las estadías y los cobros de manera organizada.

