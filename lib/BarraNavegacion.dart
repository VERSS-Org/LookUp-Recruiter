import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lookup_flutter/Contacto/views/MensajesEmpresa.dart';
import 'package:lookup_flutter/Home/views/HomeEmpresa.dart';
import 'package:lookup_flutter/Home/views/NovedadesEmpresa.dart';
import 'package:lookup_flutter/Perfil/views/PerfilPage.dart';
import 'package:lookup_flutter/Puesto/views/GestionarOfertas.dart';
import 'package:lookup_flutter/services/auth_service.dart';
import 'package:lookup_flutter/services/contacto_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/services/postulacion_service.dart';
import 'package:lookup_flutter/services/profile_service.dart';
import 'package:lookup_flutter/services/theme_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Shell principal de la app de empresa.
///
/// Web ancha: barra superior persistente. Móvil: appbar compacta y barra
/// inferior para las dos tareas principales.
class BarraNavegacion extends StatefulWidget {
  const BarraNavegacion({super.key});

  @override
  State<BarraNavegacion> createState() => _BarraNavegacionState();
}

class _BarraNavegacionState extends State<BarraNavegacion> {
  int _currentIndex = 0;
  GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();
  Timer? _inboxTimer;
  bool _isRefreshingBadges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBadges());
    // Refresca los badges periódicamente.
    _inboxTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshBadges(),
    );
  }

  @override
  void dispose() {
    _inboxTimer?.cancel();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (index == _currentIndex) {
      _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _currentIndex = index;
      _contentNavigatorKey = GlobalKey<NavigatorState>();
    });
  }

  Future<void> _refreshBadges() async {
    if (!mounted || _isRefreshingBadges) return;
    _isRefreshingBadges = true;
    try {
      await Future.wait([
        context.read<ContactoService>().fetchBandeja(),
        context.read<PostulacionService>().fetchEventos(),
      ]);
    } catch (error) {
      // Los servicios conservan el último estado válido; un fallo de red en
      // el refresco periódico no debe interrumpir el shell de navegación.
      debugPrint('No se pudieron actualizar los indicadores: $error');
    } finally {
      _isRefreshingBadges = false;
    }
  }

  void _openNotifications() {
    context.read<PostulacionService>().markEventosSeen();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovedadesEmpresa(showBack: true),
      ),
    );
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MensajesEmpresa(showBack: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<ContactoService>().unreadMessages;
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    final c = context.colors;

    final unseenEventos = context.watch<PostulacionService>().unseenEventos;

    if (isWide) {
      final pages = [
        HomeEmpresa(
          onNavigateToOfertas: () => _navigateTo(1),
        ),
        const GestionarOfertas(),
        const MensajesEmpresa(),
        const PerfilPage(),
      ];
      return Scaffold(
        body: Column(
          children: [
            _DesktopTopBar(
              index: _currentIndex,
              unread: unread,
              eventos: unseenEventos,
              onSelect: _navigateTo,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                reverseDuration: const Duration(milliseconds: 140),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final position = Tween<Offset>(
                    begin: const Offset(0.008, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: position, child: child),
                  );
                },
                child: Navigator(
                  key: _contentNavigatorKey,
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (_) => pages[_currentIndex],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final pages = [
      HomeEmpresa(
        onNavigateToOfertas: () => _navigateTo(1),
      ),
      const GestionarOfertas(),
    ];
    final mobileIndex = _currentIndex.clamp(0, 1);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 56,
        leading: BadgedIconButton(
          icon: Icons.chat_bubble_outline,
          count: unread,
          tooltip: context.t('nav.messages'),
          onPressed: _openMessages,
        ),
        title: const BrandMark(size: 31),
        actions: [
          BadgedIconButton(
            icon: Icons.notifications_outlined,
            count: unseenEventos,
            tooltip: context.t('notif.title'),
            onPressed: _openNotifications,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 10),
            child: Builder(
              builder: (context) {
                final profile = context.watch<ProfileService>().profileData ??
                    const <String, dynamic>{};
                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: InitialsAvatar(
                    name: profile['nombre_completo']?.toString() ?? '?',
                    size: 34,
                    imageUrl: profile['foto_url']?.toString(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      endDrawer: const _CompanyDrawer(),
      body: IndexedStack(index: mobileIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: NavigationBar(
          selectedIndex: mobileIndex,
          onDestinationSelected: _navigateTo,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.t('nav.home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.work_outline),
              selectedIcon: const Icon(Icons.work),
              label: context.t('nav.vacancies'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.index,
    required this.unread,
    required this.eventos,
    required this.onSelect,
  });

  final int index;
  final int unread;
  final int eventos;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = context.watch<ProfileService>().profileData ??
        const <String, dynamic>{};
    final nombre = profile['nombre_completo']?.toString() ?? 'Empresa';
    final compactNav = MediaQuery.sizeOf(context).width < 1240;

    return Container(
      key: const ValueKey('desktop-company-navbar'),
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: compactNav ? 14 : 18),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelect(0),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: BrandMark(size: 38),
            ),
          ),
          SizedBox(width: compactNav ? 8 : 16),
          _DesktopNavItem(
            label: context.t('nav.home'),
            selected: index == 0,
            compact: compactNav,
            onTap: () => onSelect(0),
          ),
          _DesktopNavItem(
            label: context.t('nav.vacancies'),
            selected: index == 1,
            compact: compactNav,
            onTap: () => onSelect(1),
          ),
          const Spacer(),
          BadgedIconButton(
            icon: Icons.chat_outlined,
            count: unread,
            tooltip: context.t('nav.messages'),
            onPressed: () => onSelect(2),
          ),
          PopupMenuButton<void>(
            key: const ValueKey('desktop-notifications-button'),
            tooltip: context.t('notif.title'),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            constraints: const BoxConstraints.tightFor(
              width: 420,
              height: 480,
            ),
            itemBuilder: (context) => const [
              PopupMenuItem<void>(
                enabled: false,
                padding: EdgeInsets.zero,
                height: 480,
                child: NovedadesEmpresa(compact: true),
              ),
            ],
            icon: eventos > 0
                ? Badge.count(
                    count: eventos,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            key: const ValueKey('desktop-company-profile-menu'),
            tooltip: nombre,
            offset: const Offset(0, 46),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    const Icon(Icons.business_outlined, size: 19),
                    const SizedBox(width: 10),
                    Text(context.tr('nav.my_profile')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 19, color: c.danger),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('nav.logout'),
                      style: TextStyle(color: c.danger),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'perfil') {
                onSelect(3);
                return;
              }
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: InitialsAvatar(
              name: nombre,
              size: 34,
              imageUrl: profile['foto_url']?.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 13.5 : 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? c.brand : c.inkMuted,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2.5,
              width: 26,
              decoration: BoxDecoration(
                color: selected ? c.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawer móvil de la empresa: perfil, configuración y cierre de sesión.
class _CompanyDrawer extends StatelessWidget {
  const _CompanyDrawer();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final profile = context.watch<ProfileService>().profileData ??
        const <String, dynamic>{};
    final nombre = profile['nombre_completo']?.toString() ?? 'Empresa';

    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Row(
                children: [
                  InitialsAvatar(
                    name: nombre,
                    size: 52,
                    imageUrl: profile['foto_url']?.toString(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          profile['email']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: Text(context.t('nav.my_profile')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PerfilPage(showBack: true),
                  ),
                );
              },
            ),
            Divider(color: c.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                context.t('settings.title').toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.inkFaint,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('settings.theme'),
                    style: TextStyle(fontSize: 13, color: c.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined, size: 17),
                        tooltip: context.t('settings.theme.light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined, size: 17),
                        tooltip: context.t('settings.theme.dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(
                          Icons.brightness_auto_outlined,
                          size: 17,
                        ),
                        tooltip: context.t('settings.theme.system'),
                      ),
                    ],
                    selected: {themeController.mode},
                    onSelectionChanged: (selection) =>
                        themeController.setMode(selection.first),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.t('settings.language'),
                    style: TextStyle(fontSize: 13, color: c.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'es', label: Text('Español')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {localeController.language},
                    onSelectionChanged: (selection) =>
                        localeController.setLanguage(selection.first),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Divider(color: c.border, height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: c.danger),
              title: Text(
                context.t('nav.logout'),
                style: TextStyle(color: c.danger),
              ),
              onTap: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                final auth = context.read<AuthService>();
                await auth.logout();
                if (navigator.mounted) {
                  navigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
