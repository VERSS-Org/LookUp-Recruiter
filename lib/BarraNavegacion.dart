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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovedadesEmpresa(showBack: true),
      ),
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
      const MensajesEmpresa(embedded: true),
      const PerfilPage(),
    ];
    final mobileIndex = _currentIndex.clamp(0, 3);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: _currentIndex == 2
            ? Text(context.t('nav.messages'))
            : InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _navigateTo(0),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: BrandMark(size: 34),
                ),
              ),
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
                  onTap: () => _navigateTo(3),
                  child: InitialsAvatar(
                    name: profile['nombre_completo']?.toString() ?? '?',
                    size: 34,
                    imageUrl: profile['foto_url']?.toString(),
                    circular: true,
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
            NavigationDestination(
              icon: unread > 0
                  ? Badge.count(
                      count: unread,
                      child: const Icon(Icons.chat_bubble_outline),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: context.t('nav.messages'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.business_outlined),
              selectedIcon: const Icon(Icons.business),
              label: context.t('nav.my_profile'),
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
    final popupHeight =
        (MediaQuery.sizeOf(context).height - 76).clamp(240.0, 430.0);

    return Container(
      key: const ValueKey('desktop-company-navbar'),
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: compactNav ? 12 : 18),
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
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: BrandMark(size: 32),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            context.t('nav.company').toUpperCase(),
            style: TextStyle(
              color: c.inkFaint,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(width: compactNav ? 6 : 12),
          _DesktopNavItem(
            icon: Icons.home_outlined,
            label: context.t('nav.home'),
            selected: index == 0,
            compact: compactNav,
            onTap: () => onSelect(0),
          ),
          _DesktopNavItem(
            icon: Icons.work_outline,
            label: context.t('nav.vacancies'),
            selected: index == 1,
            compact: compactNav,
            onTap: () => onSelect(1),
          ),
          const SizedBox(width: 6),
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
            constraints: BoxConstraints.tightFor(
              width: 420,
              height: popupHeight,
            ),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                padding: EdgeInsets.zero,
                height: popupHeight,
                child: NovedadesEmpresa(
                  compact: true,
                  compactHeight: popupHeight,
                ),
              ),
            ],
            icon: eventos > 0
                ? Badge.count(
                    count: eventos,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 5),
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
              size: 30,
              imageUrl: profile['foto_url']?.toString(),
              circular: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11),
        decoration: BoxDecoration(
          color: selected
              ? c.brand.withValues(alpha: context.isDark ? 0.22 : 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? c.brand : c.inkMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? c.brand : c.inkMuted,
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
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Row(
                children: [
                  InitialsAvatar(
                    name: nombre,
                    size: 52,
                    imageUrl: profile['foto_url']?.toString(),
                    circular: true,
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
                  fontSize: 12,
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
