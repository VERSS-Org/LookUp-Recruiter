import 'package:flutter/material.dart';

import 'package:lookup_flutter/services/api_service.dart';
import 'package:lookup_flutter/services/locale_controller.dart';
import 'package:lookup_flutter/theme/lookup_theme.dart';
import 'package:lookup_flutter/theme/lookup_widgets.dart';

/// Perfil público de un postulante visto por una empresa.
class CandidatoPerfilPage extends StatefulWidget {
  const CandidatoPerfilPage({
    super.key,
    required this.cuentaId,
    this.profileLoader,
    this.onContact,
  });

  final String cuentaId;
  final Future<Map<String, dynamic>?> Function(String cuentaId)? profileLoader;
  final VoidCallback? onContact;

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
    return Scaffold(
      appBar: AppBar(title: Text(context.t('candprofile.title'))),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) {
            return ViewportScrollPage(
              maxWidth: 760,
              padding: const EdgeInsets.all(22),
              child: Column(
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

          final account = snapshot.data!;
          final profile = account['perfil'] is Map
              ? Map<String, dynamic>.from(account['perfil'] as Map)
              : const <String, dynamic>{};
          final name = account['nombre_completo']?.toString() ??
              context.t('common.applicant');
          final email = profile['mostrar_email'] == false
              ? ''
              : (account['email']?.toString().trim() ?? '');
          final description = profile['descripcion']?.toString().trim() ?? '';
          final skills = (profile['habilidades'] as List?) ?? const [];

          return ViewportScrollPage(
            key: const ValueKey('candidate-profile-page-scroll'),
            maxWidth: 780,
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
              24,
              MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CandidateHeader(
                  name: name,
                  imageUrl: account['foto_url']?.toString(),
                  career: account['carrera']?.toString() ?? '',
                  city: account['ciudad']?.toString() ?? '',
                  email: email,
                  onContact: widget.onContact,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionCaption(
                    text: context.t('candprofile.about'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.colors.ink,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
                _EntrySection(
                  title: context.t('candprofile.experience'),
                  icon: Icons.work_outline,
                  entries: profile['experiencia'],
                  titleKey: 'puesto',
                  subtitleKeys: const ['organizacion', 'periodo'],
                  bodyKey: 'descripcion',
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 640;
                    final left = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EntrySection(
                          title: context.t('candprofile.education'),
                          icon: Icons.school_outlined,
                          entries: profile['educacion'],
                          titleKey: 'titulo',
                          subtitleKeys: const ['institucion', 'periodo'],
                        ),
                        _EntrySection(
                          title: context.t('candprofile.certificates'),
                          icon: Icons.verified_outlined,
                          entries: profile['certificados'],
                          titleKey: 'nombre',
                          subtitleKeys: const ['anio'],
                        ),
                      ],
                    );
                    final right = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (skills.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionCaption(
                            text: context.t('candprofile.skills'),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              for (final skill in skills)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(skill.toString()),
                                ),
                            ],
                          ),
                        ],
                        _EntrySection(
                          title: context.t('candprofile.languages'),
                          icon: Icons.translate_outlined,
                          entries: profile['idiomas'],
                          titleKey: 'idioma',
                          subtitleKeys: const ['nivel'],
                        ),
                        _EntrySection(
                          title: context.t('candprofile.extras'),
                          icon: Icons.star_outline,
                          entries: profile['extras'],
                          titleKey: 'titulo',
                          subtitleKeys: const [],
                          bodyKey: 'descripcion',
                        ),
                      ],
                    );
                    if (!wide) {
                      return Column(children: [left, right]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 32),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CandidateHeader extends StatelessWidget {
  const _CandidateHeader({
    required this.name,
    required this.imageUrl,
    required this.career,
    required this.city,
    required this.email,
    required this.onContact,
  });

  final String name;
  final String? imageUrl;
  final String career;
  final String city;
  final String email;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final details = [career, city].where((value) => value.trim().isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final identity = Row(
          children: [
            InitialsAvatar(
              name: name,
              size: compact ? 52 : 58,
              imageUrl: imageUrl,
              circular: true,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details.join(' · '),
                      style: TextStyle(color: c.inkMuted, fontSize: 12),
                    ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.inkFaint, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        );
        final action = onContact == null
            ? null
            : OutlinedButton.icon(
                onPressed: onContact,
                icon: const Icon(Icons.chat_outlined, size: 17),
                label: Text(context.t('cand.contact')),
              );

        return Container(
          padding: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    if (action != null) ...[
                      const SizedBox(height: 14),
                      action,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    if (action != null) ...[
                      const SizedBox(width: 16),
                      action,
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
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
    final list = entries is List
        ? (entries as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : const <Map<String, dynamic>>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _SectionCaption(text: title),
        const SizedBox(height: 4),
        for (final entry in list)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: c.inkFaint),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry[titleKey]?.toString() ?? '—',
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitleKeys
                          .map((key) => entry[key]?.toString() ?? '')
                          .where((value) => value.isNotEmpty)
                          .isNotEmpty)
                        Text(
                          subtitleKeys
                              .map((key) => entry[key]?.toString() ?? '')
                              .where((value) => value.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(color: c.inkMuted, fontSize: 12),
                        ),
                      if (bodyKey != null &&
                          (entry[bodyKey!]?.toString() ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            entry[bodyKey!].toString(),
                            style: TextStyle(
                              color: c.inkMuted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
