import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_assets.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/staggered_fade_in.dart';
import '../../data/models/property.dart';
import '../../data/repositories/auth_repository.dart';
import 'providers.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String? _selectedAmenity;

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final user = ref.watch(currentUserProvider).value;
    final firstName = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim().split(' ').first
        : 'Guest';
    final wide =
        MediaQuery.sizeOf(context).width >= PasalaTokens.wideBreakpoint;

    return AsyncView(
      value: properties,
      onRetry: () => ref.invalidate(propertiesProvider),
      empty: () => const EmptyState(
        icon: Icons.villa_outlined,
        title: 'No properties yet',
        message: 'Ask an admin to add one.',
      ),
      data: (list) {
        // With exactly one active property, skip the list entirely and
        // land the customer straight on it -- self-correcting if a second
        // property is ever seeded (see
        // docs/superpowers/specs/2026-08-13-single-property-onboarding-design.md
        // section 4.4). Scheduled post-frame so this never navigates
        // mid-build.
        if (list.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/property/${list.single.id}');
          });
          return const LoadingState();
        }

        // Collect all distinct amenities present across properties
        final allAmenities = <String>{};
        for (final p in list) {
          allAmenities.addAll(p.amenities);
        }
        final amenityList = allAmenities.toList()..sort();

        final filteredList = _selectedAmenity == null
            ? list
            : list.where((p) => p.amenities.any((a) =>
                a.toLowerCase().contains(_selectedAmenity!.toLowerCase()))).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(propertiesProvider),
          child: CustomScrollView(
            cacheExtent: 1000,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    Spacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top greeting bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hi, $firstName 👋',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 20),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      // Floating search bar pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                'Where do you want to stay?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.black12,
                              margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                            ),
                            Icon(Icons.tune_rounded, color: Colors.black87, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      // Hero banner card
                      _BrowseHero(wide: wide),
                      const SizedBox(height: Spacing.sm),
                      // Featured Offers header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Featured Offers',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View all',
                              style: TextStyle(
                                color: PasalaTokens.seed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Filter chips row matching middle screen
              if (amenityList.isNotEmpty)
                SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: Spacing.md,
                    right: Spacing.md,
                    bottom: Spacing.sm,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.tune, size: 16),
                          label: const Text('Filter'),
                          onPressed: () {},
                        ),
                        const SizedBox(width: Spacing.xs),
                        ActionChip(
                          avatar: const Icon(Icons.swap_vert, size: 16),
                          label: const Text('Sort'),
                          onPressed: () {},
                        ),
                        const SizedBox(width: Spacing.xs),
                        ActionChip(
                          avatar: const Icon(Icons.attach_money, size: 16),
                          label: const Text('Price range'),
                          onPressed: () {},
                        ),
                        const SizedBox(width: Spacing.xs),
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedAmenity == null,
                          onSelected: (_) => setState(() => _selectedAmenity = null),
                        ),
                        const SizedBox(width: Spacing.xs),
                        for (final amenity in amenityList) ...[
                          FilterChip(
                            label: Text(amenity),
                            selected: _selectedAmenity == amenity,
                            onSelected: (selected) => setState(() {
                              _selectedAmenity = selected ? amenity : null;
                            }),
                          ),
                          const SizedBox(width: Spacing.xs),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (filteredList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'No properties with "$_selectedAmenity"',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: Spacing.sm),
                          TextButton(
                            onPressed: () => setState(() => _selectedAmenity = null),
                            child: const Text('Show all properties'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (wide)
                SliverPadding(
                  padding: const EdgeInsets.all(Spacing.md),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: Spacing.md,
                          crossAxisSpacing: Spacing.md,
                          childAspectRatio: 0.82,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => StaggeredFadeIn(
                        key: ValueKey(filteredList[i].id),
                        index: i,
                        child: PropertyCard(
                          property: filteredList[i],
                          onTap: () => context.go('/property/${filteredList[i].id}'),
                        ),
                      ),
                      childCount: filteredList.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(Spacing.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        for (var i = 0; i < filteredList.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.md),
                            child: StaggeredFadeIn(
                              key: ValueKey(filteredList[i].id),
                              index: i,
                              child: PropertyCard(
                                property: filteredList[i],
                                onTap: () => context.go('/property/${filteredList[i].id}'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BrowseHero extends StatelessWidget {
  const _BrowseHero({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 220 : 95,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.patioFirepitNight,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Escape The Ordinary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Discover your stay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: const Text(
                    'Explore Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A property's header art: its first photo when one exists, otherwise a
/// tinted placeholder carrying the property's initial. Reused by
/// [PropertyCard] (16:9, inside a card) and `PropertyScreen`'s full-width
/// header, so the "broken image never shows a customer an error box" rule
/// only has to be written once.
class PropertyMedia extends StatelessWidget {
  const PropertyMedia({super.key, required this.property});

  final Property property;

  String get _initial => property.name.trim().isEmpty
      ? '?'
      : property.name.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    // Without a semantics label a screen reader announces either nothing
    // (the Image.network path) or just the bare initial letter (the
    // placeholder path) -- neither tells a screen-reader user which
    // property this card is for. Both paths get the property's name plus a
    // short descriptor instead, applied once here rather than inside
    // [_PropertyPlaceholder] itself -- that widget is also reused as
    // Image.network's errorBuilder result, and wrapping it there too would
    // nest a second, conflicting Semantics node under this one whenever a
    // photo URL fails to load.
    if (property.images.isEmpty) {
      return Semantics(
        label: '${property.name}, no photo available',
        image: true,
        // Otherwise the placeholder's own "initial letter" Text widget
        // merges its literal text ("P") into this label instead of being
        // silenced by it, and a screen reader reads both.
        excludeSemantics: true,
        child: _PropertyPlaceholder(initial: _initial),
      );
    }

    return Semantics(
      label: '${property.name} property photo',
      image: true,
      excludeSemantics: true,
      child: Image.network(
        property.images.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // This widget already supplies the semantics above; without this,
        // Image.network would additionally wrap itself in its own
        // semantics node (unlabelled, since no `semanticLabel` is passed),
        // producing a redundant nested image node either way.
        excludeFromSemantics: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _PropertyLoadingBox();
        },
        // A broken or unreachable URL must never surface Flutter's red error
        // box to a customer -- it falls back to the same tinted placeholder
        // used when there is no image at all.
        errorBuilder: (context, error, stackTrace) =>
            _PropertyPlaceholder(initial: _initial),
      ),
    );
  }
}

class _PropertyPlaceholder extends StatelessWidget {
  const _PropertyPlaceholder({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PropertyLoadingBox extends StatelessWidget {
  const _PropertyLoadingBox();

  @override
  Widget build(BuildContext context) =>
      Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
}

/// The icon shown alongside an amenity's label. Pure so it's testable
/// without a widget, and falls back to a generic icon for anything an
/// admin adds that isn't in this list -- an unrecognised amenity must
/// never crash or render blank.
IconData amenityIcon(String label) => switch (label.toLowerCase()) {
  'pool' => Icons.pool,
  'wi-fi' || 'wifi' => Icons.wifi,
  'barbecue' => Icons.outdoor_grill,
  'parking' => Icons.local_parking,
  'garden' || 'lawn' => Icons.grass,
  'bonfire' => Icons.local_fire_department,
  'spacious' => Icons.aspect_ratio,
  _ => Icons.check_circle_outline,
};

/// Up to four amenity chips styled as metadata rather than actions, with a
/// `+N` chip absorbing the rest. Amenities never appear elsewhere on the
/// card, so styling this once here is enough.
class AmenityWrap extends StatelessWidget {
  const AmenityWrap({super.key, required this.amenities, this.max = 4});

  final List<String> amenities;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final shown = amenities.take(max).toList();
    final overflow = amenities.length - shown.length;

    Widget metaChip(String label, {IconData? icon}) => Chip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: scheme.onSurfaceVariant)
          : null,
      label: Text(label),
      labelStyle: labelStyle,
      backgroundColor: scheme.surfaceContainerHigh,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
    );

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.xs,
      children: [
        for (final a in shown) metaChip(a, icon: amenityIcon(a)),
        if (overflow > 0) metaChip('+$overflow'),
      ],
    );
  }
}

/// The tallest a card's media area is allowed to get. A plain 16:9 area
/// scales with the card's width, which is fine on a phone but turns into a
/// wall of image on a wide desktop list -- capping the height keeps the card
/// proportioned like a card instead of a banner while staying 16:9 (or
/// narrower) on anything phone-sized.
const double _cardMediaMaxHeight = 130;

class PropertyCard extends StatefulWidget {
  const PropertyCard({super.key, required this.property, this.onTap});

  final Property property;
  final VoidCallback? onTap;

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final property = widget.property;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.015 : 1.0,
        duration: PasalaTokens.motionFast,
        curve: Curves.easeOut,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final height = (constraints.maxWidth * 9 / 16)
                        .clamp(0, _cardMediaMaxHeight)
                        .toDouble();
                    return SizedBox(
                      width: double.infinity,
                      height: height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'property-media-${property.id}',
                            child: PropertyMedia(property: property),
                          ),
                          // Price badge top right (Emerald green)
                          Positioned(
                            top: Spacing.sm,
                            right: Spacing.sm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: PasalaTokens.seed,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '₹3,500/night',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          // Photo count badge bottom right
                          Positioned(
                            bottom: Spacing.sm,
                            right: Spacing.sm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                property.images.isNotEmpty
                                    ? '1/${property.images.length}'
                                    : '2/27',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              property.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '4.9 (2,241)',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      // Distance and Location
                      if (property.address != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: Spacing.sm),
                      // Perks Row (Free cancellation / Breakfast included)
                      Wrap(
                        spacing: Spacing.md,
                        runSpacing: Spacing.xs,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 15,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Free cancellation',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.coffee_outlined,
                                size: 15,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Breakfast included',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      AmenityWrap(amenities: property.amenities),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Check-in ${Property.normalizeTime(property.checkInTime)} · '
                        'Check-out ${Property.normalizeTime(property.checkOutTime)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      // View Rooms CTA Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'View Rooms',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
