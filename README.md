# LookUp Recruiter

Aplicacion Flutter para empresas reclutadoras de LookUp.

## Funcionalidad

- Registro e inicio de sesion de cuentas de empresa.
- Gestion de ofertas laborales.
- Visualizacion de candidatos por oferta.
- Actualizacion de estados de postulacion y envio de feedback.
- Perfil de empresa y metricas basicas.

## Configuracion

La app usa el backend de LookUp por defecto. Para apuntar a otro entorno:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://localhost:8000
```

El valor puede incluir o no `/api`; la app lo normaliza internamente.

## Verificacion

```bash
flutter pub get
flutter analyze
```
