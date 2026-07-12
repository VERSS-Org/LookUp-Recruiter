# LookUp Empresas

Aplicación Flutter para empresas reclutadoras de LookUp.

## Funcionalidad

- Registro e inicio de sesión de cuentas de empresa.
- Gestión de vacantes: crear, editar, cerrar y reabrir, incluyendo requisitos.
- Visualización de postulantes por vacante y seguimiento de sus procesos.
- Actualización de estados de postulación y envío de feedback/mensajes.
- Perfil de empresa editable, logo y cambio de contraseña.

## Configuración

La app apunta a `http://localhost:8000` por defecto. Para apuntar a otro entorno:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://localhost:8000
```

En Android Emulator usa:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://10.0.2.2:8000
```

En un teléfono físico usa la IP LAN de la PC, por ejemplo `http://192.168.1.20:8000`.
El valor puede incluir o no `/api`; la app lo normaliza internamente.

El acceso al portal de postulantes que aparece en el inicio de sesión se
configura por separado. En desarrollo usa `http://localhost:8095` por defecto:

```bash
flutter run --dart-define=LOOKUP_USER_PORTAL_URL=http://localhost:8095
```

En un build desplegado define `LOOKUP_USER_PORTAL_URL` con la URL HTTP o HTTPS
del portal de postulantes correspondiente a ese entorno.

## Verificación

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```
