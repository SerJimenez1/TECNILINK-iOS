# TECNILINK 🔧

> Plataforma digital que conecta usuarios con técnicos verificados en servicios del hogar en Arequipa, Perú.

![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![iOS](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-yellow?logo=firebase)
![Cloudinary](https://img.shields.io/badge/Storage-Cloudinary-purple)
![RENIEC](https://img.shields.io/badge/Verificación-RENIEC-green)

---

## 📱 Descripción

TECNILINK es una app iOS nativa que resuelve el problema de encontrar técnicos confiables para servicios del hogar. El diferencial principal es el **sistema de verificación de identidad en tiempo real con RENIEC**, que garantiza que cada técnico es quien dice ser antes de aparecer en la plataforma.

**Especialidades disponibles:**
- ⚡ Electricidad
- 💧 Gasfitería
- 🪚 Carpintería
- 🔐 Cerrajería
- 🧺 Electrodomésticos
- 🖌️ Pintura / Albañilería

**Zona de cobertura:** Distrito José Luis Bustamante y Rivero, Arequipa, Perú

---

## 🏗️ Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| UI | SwiftUI |
| Arquitectura | MVVM (ObservableObject / StateObject) |
| Autenticación | Firebase Auth (Email + Google Sign-In) |
| Base de datos | Firebase Firestore |
| Almacenamiento | Cloudinary |
| Verificación DNI | API Factiliza (RENIEC) |
| Persistencia local | Core Data |
| Networking | URLSession + async/await |

---

## 👥 Roles de usuario

### 👤 Cliente
- Registro con email/contraseña o Google Sign-In
- Búsqueda y filtrado de técnicos verificados
- Solicitud de servicio con precio estimado
- Historial de servicios con estados
- Confirmación de trabajo completado
- Calificación del técnico (1-5 estrellas)

### 🔧 Técnico
- Registro con verificación de DNI en tiempo real (RENIEC)
- Subida de documentos (DNI, certificado, selfie, fotos de trabajo)
- Dashboard con filtros: Nuevas / En curso / Rechazadas / Completadas
- Vista detallada de cada solicitud antes de aceptar o rechazar
- Marcar trabajo como completado

### 🛡️ Administrador
- Panel de verificación de técnicos pendientes
- Visualización de documentos subidos
- Verificación del DNI consultado en RENIEC
- Aprobación o rechazo con motivo

---

## 🔄 Flujos principales

### Flujo del Cliente
```
Registro → Buscar técnico → Solicitar servicio →
Esperar respuesta del técnico → Ver aceptación →
Confirmar trabajo completado → Calificar técnico
```

### Flujo del Técnico
```
Registro → Verificación DNI (RENIEC) → Llenar perfil →
Subir documentos → Esperar aprobación del admin →
Dashboard → Ver solicitud en detalle →
Aceptar/Rechazar → Marcar como completado
```

### Flujo del Administrador
```
Login → Panel de verificación →
Ver técnicos pendientes → Revisar documentos y DNI →
Aprobar o rechazar con motivo
```

---

## ✅ Sistema de Verificación

El diferencial de TECNILINK es su proceso de verificación en 3 capas:

1. **Verificación DNI con RENIEC** — Al registrarse, el técnico ingresa su DNI que se valida en tiempo real contra la base de datos de RENIEC vía API Factiliza. El nombre devuelto se guarda y es visible para el administrador.

2. **Documentos físicos** — El técnico sube fotos de:
   - DNI frontal y posterior
   - Certificado técnico o constancia de estudios
   - Selfie sosteniendo el DNI
   - Mínimo 3 fotos de trabajos anteriores

3. **Revisión manual del admin** — El administrador revisa los documentos y el resultado de RENIEC antes de aprobar al técnico. Solo técnicos aprobados aparecen en la app.

---

## 🗄️ Estructura de Firestore

```
/usuarios/{userId}
  - id, name, email, role, registeredAt

/tecnicos/{tecnicoId}
  - id, userId, name, email, specialty
  - phone, location, description
  - dni, dniNombreRENIEC, dniVerificado
  - verificationStatus: "pending_documents" | "pending" | "verified" | "rejected"
  - isVerified, rating, reviewCount, completedJobs
  - documents: { dniFrontURL, dniBackURL, certificateURL, selfieURL, workPhotos }
  - createdAt, updatedAt, verifiedAt?

/servicios/{servicioId}
  - id, userId, technicianId, technicianName
  - specialty, description, estimatedPrice
  - scheduledDate, status, escrowStatus, createdAt

/resenas/{resenaId}
  - id, tecnicoId, userId, servicioId
  - rating, comment, createdAt
```

---

## 📁 Estructura del proyecto

```
TECNILINK/
├── App/
│   ├── TECNILINKApp.swift
│   └── ContentView.swift
├── Extensions/
│   └── Color+Hex.swift
├── Models/
│   ├── Tecnico.swift
│   ├── Servicio.swift
│   └── Usuario.swift
├── Persistence/
│   └── CoreDataManager.swift
├── Services/
│   ├── FirebaseService.swift
│   ├── FirestoreService.swift
│   ├── StorageService.swift
│   ├── FactilizaService.swift
│   ├── CloudinaryConfig.swift     ← en .gitignore
│   └── FactilizaConfig.swift      ← en .gitignore
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── TecnicoViewModel.swift
│   ├── SolicitudViewModel.swift
│   ├── AdminViewModel.swift
│   └── TecnicoDashboardViewModel.swift
└── Views/
    ├── Admin/
    │   ├── AdminDashboardView.swift
    │   └── AdminTecnicoDetailView.swift
    ├── Auth/
    │   ├── LoginView.swift
    │   └── RegisterView.swift
    ├── Components/
    ├── Home/
    │   └── HomeView.swift
    ├── MisServicios/
    │   ├── MisServiciosView.swift
    │   └── CalificacionView.swift
    ├── Pago/
    │   └── PagoView.swift
    ├── Perfil/
    │   └── PerfilView.swift
    ├── Solicitud/
    │   └── SolicitudView.swift
    ├── Tecnico/
    │   ├── TecnicoListView.swift
    │   └── TecnicoDetailView.swift
    └── TecnicoApp/
        ├── TecnicoTabView.swift
        ├── TecnicoRegistroView.swift
        ├── TecnicoDocumentosView.swift
        ├── TecnicoEsperaView.swift
        ├── TecnicoDashboardView.swift
        ├── TecnicoPerfilView.swift
        ├── TecnicoRechazadoView.swift
        └── SolicitudDetalleView.swift
```

---

## 🚀 Instalación

### Requisitos
- Xcode 15+
- iOS 17+
- Cuenta Firebase
- Cuenta Cloudinary
- Token API Factiliza

### Configuración

1. Clona el repositorio:
```bash
git clone https://github.com/SerJimenez1/TECNILINK-iOS.git
cd TECNILINK-iOS
```

2. Abre `TECNILINK.xcodeproj` en Xcode

3. Agrega los archivos de credenciales (no incluidos en el repo):

**GoogleService-Info.plist** — descárgalo desde Firebase Console y agrégalo al proyecto.

**CloudinaryConfig.swift** en `Services/`:
```swift
struct CloudinaryConfig {
    static let cloudName = "TU_CLOUD_NAME"
    static let apiKey = "TU_API_KEY"
    static let apiSecret = "TU_API_SECRET"
}
```

**FactilizaConfig.swift** en `Services/`:
```swift
struct FactilizaConfig {
    static let token = "TU_TOKEN_FACTILIZA"
}
```

4. Instala dependencias via SPM:
   - Firebase iOS SDK (Auth, Firestore, Storage)
   - GoogleSignIn iOS

5. Ejecuta con **Cmd + R**

---

## 👤 Cuenta de administrador

Para acceder al panel de admin, el usuario debe tener `role: "admin"` en la colección `/usuarios` de Firestore.

---

## 📊 Modelo de negocio

- **Comisión:** 15% sobre cada servicio
- **Ticket promedio:** S/ 200
- **Mercado objetivo:** Distrito JLB y Rivero, Arequipa
- **Demanda estimada:** 546 servicios/año
- **Ingresos proyectados:** S/ 109,200 anuales

---

## 👨‍💻 Equipo

| Rol | Nombre |
|-----|--------|
| Project Manager | Gomez Venero Jordy|
| iOS Developer | Jimenez Araoz, Sergio |
| QA| Apaza Quilla,  Yonay |
| QA | Choquepuma,  Josue  |
| QA | Rosas Flores,  Steven |

**Institución:** TECSUP — Ciclo V  
**Curso:** Diseño de Proyectos de Innovación + Móviles iOS

---

## 📄 Licencia

Este proyecto fue desarrollado con fines académicos para TECSUP Arequipa.
