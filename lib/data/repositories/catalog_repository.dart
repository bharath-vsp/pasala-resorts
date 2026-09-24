import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors.dart';
import '../../core/supabase_client.dart';
import '../models/property.dart';
import '../models/slot_type.dart';
import '../models/unit.dart';

class CatalogRepository {
  CatalogRepository(this._db);
  final SupabaseClient _db;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  static const _demoProperties = [
    Property(
      id: 'p1',
      name: 'Pasala Riverside Resort',
      slug: 'pasala-riverside',
      description:
          'A serene luxury resort by the riverside with private cottages, lush lawns, swimming pool, and premium hospitality.',
      address: 'Shamirpet, Hyderabad, Telangana',
      images: [],
      amenities: [
        'Swimming pool',
        'Free parking',
        'Air conditioning',
        'Bonfire pit',
        'Wi-Fi',
        'Breakfast',
      ],
      checkInTime: '14:00',
      checkOutTime: '11:00',
      isActive: true,
    ),
    Property(
      id: 'p2',
      name: 'Pasala Hilltop Retreat',
      slug: 'pasala-hilltop',
      description:
          'Scenic panoramic hilltop views, infinity pool, and luxury cottages designed for families and celebrations.',
      address: 'Bommalaramaram Rd, Rangapuram, Telangana',
      images: [],
      amenities: [
        'Swimming pool',
        'Bonfire pit',
        'Outdoor dining',
        'Free parking',
        'Wi-Fi',
      ],
      checkInTime: '14:00',
      checkOutTime: '11:00',
      isActive: true,
    ),
  ];

  static const _demoUnit = Unit(
    id: 'u1',
    propertyId: 'p1',
    name: 'Luxury Pool Cottage',
    capacityBase: 2,
    capacityMax: 4,
    bookingMode: BookingMode.nightly,
    isActive: true,
  );

  Future<List<Property>> properties() async {
    try {
      final rows = await _db
          .from('properties')
          .select()
          .order('name', ascending: true);
      return rows.map(Property.fromJson).toList();
    } catch (_) {
      return _demoProperties;
    }
  }

  Future<Property> property(String id) async {
    try {
      final row = await _db.from('properties').select().eq('id', id).single();
      return Property.fromJson(row);
    } catch (_) {
      return _demoProperties.firstWhere(
        (p) => p.id == id,
        orElse: () => _demoProperties.first,
      );
    }
  }

  /// Fetches a single unit by id. Used by the booking flow, which only ever
  /// arrives with a `unitId` (from the booking flow embedded on the property
  /// page) and needs the unit's capacity, booking mode, and property before
  /// it can render a calendar or a guest picker.
  Future<Unit> unit(String id) async {
    try {
      final row = await _db.from('units').select().eq('id', id).single();
      return Unit.fromJson(row);
    } catch (_) {
      return _demoUnit;
    }
  }

  Future<List<Unit>> units(String propertyId) async {
    try {
      final rows = await _db
          .from('units')
          .select()
          .eq('property_id', propertyId)
          .order('name', ascending: true);
      return rows.map(Unit.fromJson).toList();
    } catch (_) {
      return [_demoUnit];
    }
  }

  Future<List<SlotType>> slotTypes(String propertyId) async {
    try {
      final rows =
          await _db.from('slot_types').select().eq('property_id', propertyId);
      return rows.map(SlotType.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Property> upsertProperty(Property property, {String? id}) =>
      _guard(() async {
        final payload = property.toInsert();
        final row = id == null
            ? await _db.from('properties').insert(payload).select().single()
            : await _db
                .from('properties')
                .update(payload)
                .eq('id', id)
                .select()
                .single();
        return Property.fromJson(row);
      });

  /// A narrow, targeted update for the Owner Settings screens (tax,
  /// booking rules, payment display) -- deliberately separate from
  /// [upsertProperty]/[Property.toInsert], which `PropertyFormScreen`
  /// (Farmhouse Information) uses and which never touches these columns.
  /// Each Settings screen passes only the column(s) it owns, e.g.
  /// `{'tax_pct': 18, 'gstin': '29ABCDE1234F1Z5'}`.
  Future<void> updateSettings(String propertyId, Map<String, dynamic> fields) =>
      _guard(() async {
        await _db.from('properties').update(fields).eq('id', propertyId);
      });

  Future<Unit> upsertUnit(Unit unit, {String? id}) => _guard(() async {
        final payload = unit.toInsert();
        final row = id == null
            ? await _db.from('units').insert(payload).select().single()
            : await _db.from('units').update(payload).eq('id', id).select().single();
        return Unit.fromJson(row);
      });
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(supabaseProvider)),
);
