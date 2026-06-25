# TECNILINK — App iOS Nativa

Plataforma digital que conecta usuarios con técnicos verificados en servicios del hogar en el distrito de **José Luis Bustamante y Rivero, Arequipa, Perú**.

---

## Modelo de negocio

| Concepto | Detalle |
|---|---|
| Comisión | 15% por servicio completado |
| Ticket promedio | S/ 200 |
| Pago | Sistema Escrow (retenido hasta confirmar trabajo) |
| Área de cobertura | J.L.B. y Rivero, Arequipa |

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| UI | SwiftUI |
| Arquitectura | MVVM (ObservableObject / StateObject) |
| Autenticación | Firebase Auth (email/password) |
| Persistencia local | Core Data |
| Red | URLSession con async/await |
| Serialización | Codable (JSON) |
| Reactividad | Combine |

---

## Estructura de archivos

```
TECNILINK/
├── .gitignore
└── TECNILINK/
    ├── TECNILINKApp.swift
    ├── ContentView.swift
    │
    ├── Extensions/
    │   └── Color+Hex.swift
    │
    ├── Models/
    │   ├── Tecnico.swift
    │   ├── Servicio.swift
    │   └── Usuario.swift
    │
    ├── ViewModels/
    │   ├── AuthViewModel.swift
    │   ├── TecnicoViewModel.swift
    │   └── SolicitudViewModel.swift
    │
    ├── Services/
    │   ├── FirebaseService.swift
    │   └── APIService.swift
    │
    ├── Persistence/
    │   └── CoreDataManager.swift
    │
    ├── Resources/
    │   └── TECNILINK.xcdatamodeld/   ← modelo Core Data
    │
    └── Views/
        ├── MainTabView.swift
        ├── Auth/
        │   ├── LoginView.swift
        │   └── RegisterView.swift
        ├── Home/
        │   └── HomeView.swift
        ├── Tecnico/
        │   ├── TecnicoListView.swift
        │   └── TecnicoDetailView.swift
        ├── Solicitud/
        │   └── SolicitudView.swift
        ├── Pago/
        │   └── PagoView.swift
        ├── Perfil/
        │   └── PerfilView.swift
        └── Components/
            └── TecniComponents.swift
```

---

## Pantallas

### LoginView / RegisterView
- Autenticación con Firebase Auth (email + contraseña)
- Validaciones locales antes de llamar a Firebase
- Mensajes de error mapeados al español
- Fondo degradado con la paleta de marca

### HomeView
- Banner de bienvenida con nombre del usuario
- Buscador rápido (navega a TecnicoListView)
- Categorías de servicios en scroll horizontal
- Lista de técnicos destacados (máx. 4)

### TecnicoListView
- Buscador en tiempo real (debounce 250ms via Combine)
- Filtros por especialidad (chips seleccionables)
- Lista animada con badge **VERIFICADO**
- Estado vacío cuando no hay resultados

### TecnicoDetailView
- Foto/avatar, nombre, badge verificado
- DNI Validado indicado en pantalla
- Stats: trabajos completados, calificación, cantidad de reseñas
- Galería de reseñas de usuarios
- Contacto (teléfono y ubicación)
- Botón "Solicitar Servicio"

### SolicitudView
- Resumen del técnico seleccionado
- Selector de fecha y hora (DatePicker)
- Campo de descripción del problema
- Slider de precio estimado (S/ 50 – S/ 1,000)
- Nota sobre sistema Escrow
- Guarda localmente si no hay red

### PagoView
- Estado del Escrow con ícono dinámico
- Resumen del servicio y desglose de comisión (15%)
- Selección de método de pago: Yape / Plin / Tarjeta
- Total a pagar destacado
- Confirmación con alerta informativa

### PerfilView
- Avatar con inicial del nombre
- Stats: total de servicios, completados, monto pagado
- Historial de solicitudes desde Core Data
- Eliminar solicitudes con confirmación
- Botón de cierre de sesión

---

## Modelos de datos

### Tecnico
| Campo | Tipo | Descripción |
|---|---|---|
| id | String | Identificador único |
| name | String | Nombre completo |
| specialty | Specialty | Enum de 6 especialidades |
| rating | Double | Calificación 0–5 |
| isVerified | Bool | Badge VERIFICADO |
| description | String | Descripción del técnico |
| phone | String | Teléfono de contacto |
| location | String | Zona de cobertura |
| reviewCount | Int | Número de reseñas |
| completedJobs | Int | Trabajos terminados |
| reviews | [Review] | Lista de reseñas |

### Servicio
| Campo | Tipo | Descripción |
|---|---|---|
| id | String | UUID generado localmente |
| specialty | Specialty | Tipo de servicio |
| description | String | Descripción del problema |
| estimatedPrice | Double | Precio acordado |
| scheduledDate | Date | Fecha y hora del servicio |
| status | ServiceStatus | pending / accepted / inProgress / completed / cancelled |
| escrowStatus | EscrowStatus | notInitiated / held / released / refunded |
| technicianId | String | ID del técnico |
| userId | String | ID del usuario (Firebase UID) |

### Usuario
| Campo | Tipo | Descripción |
|---|---|---|
| id | String | Firebase UID |
| name | String | displayName de Firebase |
| email | String | Email de Firebase |
| phone | String? | Teléfono opcional |
| serviceHistory | [String] | IDs de servicios |

### Especialidades disponibles
| Enum | Valor |
|---|---|
| `.electricity` | Electricidad |
| `.plumbing` | Gasfitería |
| `.carpentry` | Carpintería |
| `.locksmith` | Cerrajería |
| `.appliances` | Electrodomésticos |
| `.painting` | Pintura/Albañilería |

---

## Arquitectura MVVM

```
View  ──observa──▶  ViewModel  ──usa──▶  Service / CoreData
 │                      │
 │   (no lógica)        └── @Published vars
 │                          async/await
 └── .task { await vm.fetch() }
     Button { Task { await vm.action() } }
```

- **Views** — solo UI, sin lógica de negocio
- **ViewModels** — `@MainActor`, `ObservableObject`, toda la lógica
- **Services** — Firebase y API REST (sin estado)
- **CoreDataManager** — singleton, CRUD de `ServicioEntity`

---

## Paleta de colores

| Nombre | Hex | Uso |
|---|---|---|
| `tecniPrimary` | `#1A3C6E` | Azul marino — color principal |
| `tecniAccent` | `#028090` | Teal — acentos e íconos |
| `tecniMint` | `#02C39A` | Mint — badge verificado, confirmaciones |
| `tecniGray` | `#64748B` | Gris — texto secundario |

---

## Componentes reutilizables (`TecniComponents.swift`)

| Componente | Descripción |
|---|---|
| `TecniTextField` | Campo de texto con ícono SF Symbol, estilo glass |
| `TecniSecureField` | Campo contraseña con toggle mostrar/ocultar |
| `VerifiedBadge` | Chip verde "VERIFICADO" con sello |
| `StarRatingView` | Estrellas dinámicas (llena, media, vacía) |
| `StatusBadge` | Chip de color según `ServiceStatus` |
| `TecniButton` | Botón primario con estado de carga |
| `EmptyStateView` | Vista de estado vacío con ícono y texto |
| `.tecniCard()` | Modificador: fondo blanco + sombra + bordes redondeados |

---

## Core Data

**Entidad: `ServicioEntity`**

| Atributo | Tipo | Nullable |
|---|---|---|
| id | String | No |
| specialty | String | No |
| serviceDesc | String | No |
| estimatedPrice | Double | No |
| scheduledDate | Date | No |
| status | String | No |
| technicianId | String | No |
| userId | String | No |
| escrowStatus | String | No |
| technicianName | String | Sí |

**Operaciones disponibles:**
- `saveServicio(_:)` — crea o actualiza (upsert por ID)
- `fetchServicios(for:)` — historial del usuario, ordenado por fecha
- `updateStatus(id:status:)` — actualiza solo el estado
- `deleteServicio(id:)` — elimina por ID

---

## Manejo de errores

| Escenario | Comportamiento |
|---|---|
| Sin conexión al cargar técnicos | Muestra mock data + mensaje informativo |
| Sin conexión al crear solicitud | Guarda en Core Data para envío posterior |
| Email/contraseña incorrectos | Mensaje en español mapeado por código de error Firebase |
| Respuesta HTTP no 2xx | `APIError.invalidResponse(statusCode:)` |
| JSON inválido | `APIError.decodingError(_:)` |
| Form inválido (fecha pasada, descripción vacía) | Validación local antes de llamar al ViewModel |

---

## Flujo de navegación

```
[Sin sesión]
LoginView ──→ RegisterView

[Con sesión]
MainTabView (TabView)
 ├── Tab 1: HomeView
 │    └──→ TecnicoListView
 │              └──→ TecnicoDetailView
 │                        └──→ SolicitudView
 │                                  └──→ PagoView
 ├── Tab 2: TecnicoListView (acceso directo)
 └── Tab 3: PerfilView (historial + logout)
```

---

## Configuración inicial

### 1. Firebase (Swift Package Manager)
```
File → Add Package Dependencies
URL: https://github.com/firebase/firebase-ios-sdk
Producto requerido: FirebaseAuth
```

### 2. Agregar archivos al proyecto Xcode
```
Clic derecho en grupo TECNILINK → Add Files to "TECNILINK"…
Seleccionar todas las carpetas nuevas → Create groups → Add to target: TECNILINK
```

### 3. GoogleService-Info.plist
- Crear app en Firebase Console (Bundle ID del proyecto)
- Descargar y arrastrar a Xcode
- **NO subir a Git** (ya está en `.gitignore`)

### 4. Habilitar Email/Password en Firebase Console
```
Authentication → Sign-in method → Email/Password → Habilitar
```

---

## Criterios de evaluación cubiertos

| Criterio | Implementación |
|---|---|
| Git commits semánticos | `feat:`, `fix:`, `refactor:` |
| MVVM | Views sin lógica, toda en ViewModels, Services separados |
| UI/UX | NavigationStack, TabView, List, ProgressView, animaciones |
| Core Data | CRUD completo, persiste entre sesiones |
| API REST | URLSession + Codable + manejo de errores sin crashes |
| Firebase Auth | login/registro/logout, `addStateDidChangeListener` controla navegación |
| Funcionalidad | Mock data offline, validaciones, estados vacíos, casos borde |
