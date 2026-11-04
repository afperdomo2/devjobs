import 'package:flutter/material.dart';

import '../screens/distribution_detail_screen.dart';
import '../screens/filtered_applications_screen.dart';
import '../theme.dart';

/// Definición de un grupo del selector de distribución.
class _DistributionSegment {
  final String field;
  final String label;
  final IconData icon;
  final Color color;

  const _DistributionSegment({
    required this.field,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Distribución por plataforma / modalidad / ciudad.
///
/// Muestra un selector segmentado de ancho completo y debajo solo el grupo
/// activo. "Empresas" queda fuera a propósito: tiene su propia pestaña.
class DistributionCard extends StatefulWidget {
  final List<(String, int)> plataformas;
  final List<(String, int)> modalidades;
  final List<(String, int)> ciudades;
  final Color colorPlataformas;
  final Color colorModalidades;
  final Color colorCiudades;

  const DistributionCard({
    super.key,
    required this.plataformas,
    required this.modalidades,
    required this.ciudades,
    required this.colorPlataformas,
    required this.colorModalidades,
    required this.colorCiudades,
  });

  @override
  State<DistributionCard> createState() => _DistributionCardState();
}

class _DistributionCardState extends State<DistributionCard> {
  /// Campo activo por defecto. La pantalla vive en un `IndexedStack`, así que
  /// la selección se conserva al cambiar de pestaña durante la sesión.
  String _field = 'plataforma';

  List<_DistributionSegment> get _segments => [
    _DistributionSegment(
      field: 'plataforma',
      label: 'Plataformas',
      icon: Icons.language,
      color: widget.colorPlataformas,
    ),
    _DistributionSegment(
      field: 'modalidad',
      label: 'Modalidades',
      icon: Icons.business_center,
      color: widget.colorModalidades,
    ),
    _DistributionSegment(
      field: 'ciudad',
      label: 'Ciudades',
      icon: Icons.location_on_outlined,
      color: widget.colorCiudades,
    ),
  ];

  _DistributionSegment get _active =>
      _segments.firstWhere((s) => s.field == _field);

  List<(String, int)> get _items => switch (_field) {
    'modalidad' => widget.modalidades,
    'ciudad' => widget.ciudades,
    _ => widget.plataformas,
  };

  void _openDetail() {
    final segment = _active;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DistributionDetailScreen(
          field: segment.field,
          label: segment.label,
          icon: segment.icon,
          color: segment.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Distribución', style: AppType.section(context)),
                ),
                _SeeAllLink(color: active.color, onTap: _openDetail),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            _DistributionSelector(
              segments: _segments,
              selected: _field,
              onSelected: (field) => setState(() => _field = field),
            ),
            const SizedBox(height: AppSpace.lg),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: _DistributionGroup(
                  key: ValueKey(_field),
                  field: _field,
                  label: active.label,
                  items: _items,
                  color: active.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector segmentado de ancho completo: track hundido y segmento activo
/// resaltado con el color del grupo.
class _DistributionSelector extends StatelessWidget {
  final List<_DistributionSegment> segments;
  final String selected;
  final ValueChanged<String> onSelected;

  const _DistributionSelector({
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.control),
        ),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _DistributionSegmentButton(
                segment: segment,
                selected: segment.field == selected,
                onTap: () => onSelected(segment.field),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistributionSegmentButton extends StatelessWidget {
  final _DistributionSegment segment;
  final bool selected;
  final VoidCallback onTap;

  const _DistributionSegmentButton({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = segment.color;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        // Material transparente para que el ripple pinte sobre el relleno del
        // segmento (el Material de la Card quedaría debajo de la decoración).
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.chip),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    segment.icon,
                    size: AppIconSize.chip,
                    color: selected ? color : muted,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        segment.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? color : muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeAllLink extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _SeeAllLink({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs + 2,
            vertical: AppSpace.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todas',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistributionGroup extends StatelessWidget {
  final String field;
  final String label;
  final List<(String, int)> items;
  final Color color;

  const _DistributionGroup({
    super.key,
    required this.field,
    required this.label,
    required this.items,
    required this.color,
  });

  void _openFiltered(BuildContext context, String value) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredApplicationsScreen(
          title: label,
          field: field,
          value: value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty
        ? 1
        : items.map((e) => e.$2).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Text(
            '—',
            style: TextStyle(
              color: statusColor('', Theme.of(context).brightness),
            ),
          )
        else
          for (final (name, count) in items)
            InkWell(
              onTap: () => _openFiltered(context, name),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.chip),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: color),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadius.bar),
                      ),
                      child: LinearProgressIndicator(
                        value: count / maxCount,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
