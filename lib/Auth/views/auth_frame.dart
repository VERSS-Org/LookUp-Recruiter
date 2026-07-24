import 'package:flutter/material.dart';

import 'package:lookup_flutter/theme/lookup_theme.dart';

/// Marco compartido por registro y recuperación.
///
/// En web conserva la composición de la referencia (cabecera blanca y cuerpo
/// tintado dentro de una superficie acotada). En móvil ocupa todo el viewport
/// para evitar márgenes y scrolls anidados artificiales.
class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 760,
    this.contentMaxWidth = 500,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final verticalMargin = compact ? 0.0 : 24.0;
            final availableHeight =
                (constraints.maxHeight - verticalMargin * 2).clamp(0.0, 900.0);

            return Center(
              child: Container(
                width: compact ? constraints.maxWidth : null,
                height: compact ? constraints.maxHeight : availableHeight,
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  border: compact ? null : Border.all(color: c.border),
                  borderRadius:
                      compact ? BorderRadius.zero : BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border(bottom: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 20 : 32,
                          vertical: compact ? 28 : 34,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: contentMaxWidth),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
