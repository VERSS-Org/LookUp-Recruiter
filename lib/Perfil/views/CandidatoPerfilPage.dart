import 'package:flutter/material.dart';
import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Perfil público de un postulante visto por la empresa: datos de contacto y
/// perfil profesional extendido (experiencia, educación, habilidades, etc.).
class CandidatoPerfilPage extends StatefulWidget {
  const CandidatoPerfilPage({
    super.key,
    required this.cuentaId,
    this.profileLoader,
  });

  final String cuentaId;
  final Future<Map<String, dynamic>?> Function(String cuentaId)? profileLoader;

  @override
  State<CandidatoPerfilPage> createState() => _CandidatoPerfilPageState();
}

class _CandidatoPerfilPageState extends State<CandidatoPerfilPage> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>?> _fetch() async {
    try {
      if (widget.profileLoader != null) {
        return widget.profileLoader!(widget.cuentaId);
      }
      final response = await ApiService().get('iam/cuenta/${widget.cuentaId}');
      return response is Map ? Map<String, dynamic>.from(response) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('candprofile.title'))),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) {
            return PageContainer(
              maxWidth: 760,
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  ErrorBanner(
                    message: context.t('candprofile.load.error'),
                    actionLabel: context.t('common.retry'),
                    onAction: () => setState(() => _future = _fetch()),
                  ),
                ],
              ),
            );
          }
          final cuenta = snapshot.data!;
          final nombre = cuenta['nombre_completo']?.toString() ??
              context.t('common.applicant');
          final perfil = cuenta['perfil'] is Map
              ? Map<String, dynamic>.from(cuenta['perfil'] as Map)
              : const <String, dynamic>{};
          final descripcion = perfil['descripcion']?.toString() ?? '';
          final habilidades = (perfil['habilidades'] as List?) ?? const [];
          final email = perfil['mostrar_email'] == false
              ? ''
              : (cuenta['email']?.toString().trim() ?? '');

          return ListView(
            key: const ValueKey('candidate-profile-page-scroll'),
            padding: EdgeInsets.zero,
            children: [
              PageContainer(
                maxWidth: 760,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
                    22,
                    MediaQuery.sizeOf(context).width < 480 ? 16 : 22,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileBanner(
                        avatar: InitialsAvatar(
                          name: nombre,
                          size: 88,
                          imageUrl: cuenta['foto_url']?.toString(),
                        ),
                        title: nombre,
                        subtitle: [
                          if ((cuenta['carrera']?.toString() ?? '').isNotEmpty)
                            cuenta['carrera'].toString(),
                          if ((cuenta['ciudad']?.toString() ?? '').isNotEmpty)
                            cuenta['ciudad'].toString(),
                        ].join(' · '),
                        caption: email,
                      ),
                      if (descripcion.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        SectionLabel(title: context.t('candprofile.about')),
                        Text(
                          descripcion,
                          style: TextStyle(
                              color: c.ink, height: 1.55, fontSize: 14.5),
                        ),
                      ],
                      _EntrySection(
                        title: context.t('candprofile.experience'),
                        icon: Icons.work_outline,
                        entries: perfil['experiencia'],
                        titleKey: 'puesto',
                        subtitleKeys: const ['organizacion', 'periodo'],
                        bodyKey: 'descripcion',
                      ),
                      _EntrySection(
                        title: context.t('candprofile.education'),
                        icon: Icons.school_outlined,
                        entries: perfil['educacion'],
                        titleKey: 'titulo',
                        subtitleKeys: const ['institucion', 'periodo'],
                      ),
                      _EntrySection(
                        title: context.t('candprofile.certificates'),
                        icon: Icons.verified_outlined,
                        entries: perfil['certificados'],
                        titleKey: 'nombre',
                        subtitleKeys: const ['anio'],
                      ),
                      if (habilidades.isNotEmpty) ...[
                        SectionLabel(title: context.t('candprofile.skills')),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final habilidad in habilidades)
                              Chip(label: Text(habilidad.toString())),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      _EntrySection(
                        title: context.t('candprofile.languages'),
                        icon: Icons.translate_outlined,
                        entries: perfil['idiomas'],
                        titleKey: 'idioma',
                        subtitleKeys: const ['nivel'],
                      ),
                      _EntrySection(
                        title: context.t('candprofile.extras'),
                        icon: Icons.star_outline,
                        entries: perfil['extras'],
                        titleKey: 'titulo',
                        subtitleKeys: const [],
                        bodyKey: 'descripcion',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EntrySection extends StatelessWidget {
  const _EntrySection({
    required this.title,
    required this.icon,
    required this.entries,
    required this.titleKey,
    required this.subtitleKeys,
    this.bodyKey,
  });

  final String title;
  final IconData icon;
  final dynamic entries;
  final String titleKey;
  final List<String> subtitleKeys;
  final String? bodyKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lista = entries is List
        ? (entries as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];
    if (lista.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title: title),
        ...lista.map((entry) {
          final sub = subtitleKeys
              .map((k) => entry[k]?.toString() ?? '')
              .where((v) => v.isNotEmpty)
              .join(' · ');
          final body =
              bodyKey == null ? '' : (entry[bodyKey!]?.toString() ?? '');
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 19, color: c.inkFaint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry[titleKey]?.toString() ?? '—',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                          fontSize: 14.5,
                        ),
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          style: TextStyle(color: c.inkMuted, fontSize: 13),
                        ),
                      if (body.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            body,
                            style: TextStyle(
                              color: c.inkMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 18),
      ],
    );
  }
}
