# PaperBoost

PaperBoost es una aplicación móvil desarrollada con Flutter para la gestión de inventario, autenticación de usuarios, generación de notas de venta y administración de alertas de stock. Construida progresivamente hasta el Sprint 4, incorpora reglas de negocio, validaciones, flujo de ventas, alertas de inventario crítico y patrones de diseño que facilitan su evolución.

## Requisitos funcionales adicionales cubiertos en esta version

- RQF-016  —  Administrar alertas de stock
- RQF-019 — Consultar historial de ventas
- RQF-022 — Notificar alertas de stock
- RQF-020 — Buscar y consultar detalle de venta
- RQF-021 — Visualizar inventario crítico

## Estado actual del desarrollo

Hasta el Sprint 4, la aplicación incluye:

- Pantalla de login con validaciones y sesión persistente en memoria
- Gestión completa de inventario (registrar, editar, dar de baja, buscar, filtrar por categoría/estado, ordenar por nombre/precio/stock)
- Vista de inventario crítico con productos que han alcanzado su mínimo de stock
- Alertas de stock configurables por producto con activación/desactivación
- Notificación de alertas de stock mediante badge en campana y diálogo informativo
- Notificación post-venta cuando productos quedan bajo el mínimo configurado
- Flujo completo de ventas: agregar productos, seleccionar método de pago, datos del cliente, cálculo automático de subtotal + IVA 15% + total
- Validación de stock antes de registrar una venta
- Actualización automática del inventario al vender
- Cancelación de ventas con restauración de stock
- Historial de ventas con búsqueda por número de nota, nombre de cliente o email
- Detalle de venta con tabla de productos, cantidades, precios unitarios y totales
- Pruebas unitarias para servicios, validadores, controladores y repositorios
- Patrón Observer para notificación reactiva de cambios de stock

## Arquitectura

La aplicación sigue una **arquitectura en capas** con separación entre presentación, lógica de negocio y datos, facilitando el mantenimiento y la expansión futura.

### 1. Capa de presentación

Responsable de la interfaz de usuario y la experiencia de navegación.

- [lib/presentation/pages](lib/presentation/pages): pantallas principales — login, inventario (con pestañas "Todos" / "Inventario Crítico"), formulario de producto y ventas (con pestañas "Nueva Venta" / "Historial")
- [lib/presentation/widgets](lib/presentation/widgets): componentes reutilizables como `ProductCard`

### 2. Capa de lógica

Contiene los controladores, servicios, validadores y mecanismos auxiliares que implementan la lógica de negocio.

- [lib/logic/controllers](lib/logic/controllers): intermediarios entre la UI y los servicios (auth, producto, venta, alerta de stock)
- [lib/logic/services](lib/logic/services): encapsulan las reglas de negocio — autenticación, productos, ventas (cálculo de IVA, descuento de stock, cancelación), alertas de stock
- [lib/logic/validators](lib/logic/validators): centralizan la validación de entradas (producto, venta, alerta de stock)
- [lib/logic/session](lib/logic/session): `SessionManager` singleton que gestiona la sesión activa del usuario
- [lib/logic/observers](lib/logic/observers): `StockChangeNotifier` singleton + `StockObserver` interface para notificación reactiva de cambios de inventario
- [lib/logic/results](lib/logic/results): `OperationResult<T>` — modelo estándar de respuesta para operaciones exitosas o con error

### 3. Capa de datos

Administra los modelos del dominio y los repositorios de persistencia.

- [lib/data/models](lib/data/models): entidades — `AppUser`, `Product` (con `ProductStatus`, `ProductSortOption`), `Sale` (con `SaleStatus`, `PaymentMethod`), `SaleItem`, `StockAlert`
- [lib/data/repositories](lib/data/repositories): interfaces abstractas e implementaciones en memoria para producto, venta, usuario y alerta de stock
- [lib/data/security](lib/data/security): `PasswordHasher` con HMAC-SHA256 para hashing y verificación de contraseñas

## Patrones de diseño

| Patrón | Ubicación | Propósito |
|--------|-----------|-----------|
| **MVC / Capas** | `presentation/` → `logic/` → `data/` | Separación de responsabilidades: UI delega en controladores y servicios |
| **Repository** | `data/repositories/` | Abstracción de persistencia con interfaces e implementaciones intercambiables |
| **Dependency Injection** | `app_dependencies.dart` | Centraliza la creación y cableado de dependencias sin framework externo |
| **Singleton** | `SessionManager`, `StockChangeNotifier` | Instancia única global para sesión y notificador de stock |
| **Observer** | `StockObserver` + `StockChangeNotifier` | Notificación reactiva a múltiples widgets cuando el stock cambia |
| **Result Object** | `OperationResult<T>` | Estandariza respuestas exitosas/fallidas con mensaje y datos |

## Flujo principal

1. El usuario inicia sesión con credenciales predefinidas (`admin@paperboost.com` / `Admin123*`)
2. Accede al inventario donde puede registrar, editar, buscar, filtrar y ordenar productos
3. Puede configurar alertas de stock con cantidad mínima por producto
4. Desde la vista de ventas, agrega productos, selecciona método de pago y registra la venta
5. Al crear la venta se valida stock, calcula IVA (15%), descuenta inventario y notifica cambios
6. Si algún producto queda bajo su mínimo configurado, se muestra advertencia post-venta
7. Las ventas quedan en el historial con detalle completo y opción de cancelación (restaura stock)
8. La campana de notificaciones muestra un badge con la cantidad de productos en stock crítico

## Estructura del proyecto

```text
lib/
  app_dependencies.dart
  main.dart
  data/
    models/          # AppUser, Product, Sale, SaleItem, StockAlert
    repositories/    # Abstractas + InMemory (producto, venta, usuario, alerta)
    security/        # PasswordHasher
  logic/
    controllers/     # Auth, Product, Sale, StockAlert
    observers/       # StockObserver, StockChangeNotifier
    results/         # OperationResult
    services/        # Auth, Product, Sale, StockAlert
    session/         # SessionManager
    validators/      # Product, Sale, StockAlert
  presentation/
    pages/           # Login, Inventory, ProductForm, Sales
    widgets/         # ProductCard
test/
  data/repositories/ # Tests de repositorios en memoria
  logic/
    controllers/     # Tests de controladores
    services/        # Tests de servicios
    validators/      # Tests de validadores
  widget_test.dart   # Smoke test de login
```

## Tecnologías

- **Framework**: Flutter (SDK >=3.0.0)
- **Lenguaje**: Dart
- **Dependencias**: `crypto` (HMAC-SHA256), `cupertino_icons`
- **Testing**: `flutter_test` (sin librerías externas de mocking)

## Requisitos para ejecutar

```bash
flutter pub get
flutter run
```

## Pruebas

```bash
flutter test
```

El proyecto cuenta con **81+ pruebas unitarias** que cubren servicios, validadores, controladores y repositorios.

## Notas importantes

- La persistencia actual es **en memoria**, los datos se reinician al cerrar la app
- Usuario por defecto: `admin@paperboost.com` / `Admin123*`
- IVA fijo de 15% configurado como constante en `SaleService`
- Arquitectura preparada para migrar a backend real con repositorios concretos
- Los IDs de venta se generan en formato `VTA-000001` (secuencial)
- Cada `SaleItem` guarda una copia del `Product` al momento de la venta (precio histórico)

## Conclusión

PaperBoost presenta una base sólida para la gestión de inventario y ventas con alertas de stock, arquitectura modular, validaciones claras y patrones de diseño aplicados que facilitan la evolución hacia sprints futuros.
