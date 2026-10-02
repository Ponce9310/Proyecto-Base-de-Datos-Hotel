# 🏨 Sistema de Gestión de Hotel y Reservas

## 📌 Descripción del proyecto

Este proyecto corresponde al desarrollo de un **Sistema de Gestión de Hotel y Reservas**, cuyo objetivo es organizar y administrar la información relacionada con huéspedes, reservas, habitaciones, estadías, servicios, consumos, cuentas y pagos.

El sistema busca representar mediante una base de datos los principales procesos del negocio hotelero, manteniendo la información relacionada de forma estructurada y permitiendo aplicar reglas de negocio mediante **PL/SQL**.

---

## 🎯 Objetivo

Diseñar e implementar una solución de base de datos que permita gestionar de manera organizada los principales procesos de un hotel, considerando las relaciones entre huéspedes, reservas, habitaciones, estadías, servicios, cuentas y pagos.

---

## 🔄 Flujo principal del negocio

El proceso central del sistema se puede representar de la siguiente manera:

**Huésped → Reserva → Habitación → Estadía → Servicios y Consumos → Cuenta → Pago**

Este flujo representa cómo se relacionan las principales entidades del negocio hotelero y sirve como base para el desarrollo de las funcionalidades del sistema.

---

## 🗄️ Base de datos

La solución contempla diferentes entidades relacionadas con la operación del hotel, entre ellas:

- Huéspedes
- Empleados
- Habitaciones
- Tipos de habitación
- Estados de habitación
- Reservas
- Detalles de reserva
- Estadías
- Ocupantes de estadía
- Servicios
- Consumos
- Cuentas
- Pagos
- Auditoría de reservas

La base de datos se encuentra desarrollada utilizando **Oracle SQL y PL/SQL**.

---

## 📚 Estructura del proyecto

El repositorio se organiza según las distintas etapas de evaluación del proyecto:

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
│
└── README.md
