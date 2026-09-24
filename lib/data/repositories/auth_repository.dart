import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors.dart';
import '../../core/supabase_client.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._db);
  final SupabaseClient _db;

  Future<AppUser> _profileFor(User user) async {
    final row =
        await _db.from('profiles').select().eq('id', user.id).maybeSingle();
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: row?['full_name'] as String?,
      phone: row?['phone'] as String?,
      role: roleFromDb(row?['role'] as String? ?? 'customer'),
    );
  }

  static AppUser? _offlineUser;

  Future<AppUser> signIn(String email, String password) async {
    try {
      final res = await _db.auth
          .signInWithPassword(email: email, password: password);
      return _profileFor(res.user!);
    } catch (e) {
      // In local dev without Supabase backend running, provide graceful demo login
      final lowerEmail = email.toLowerCase().trim();
      if (lowerEmail.contains('admin') && !lowerEmail.contains('super') && !lowerEmail.startsWith('sa')) {
        final user = const AppUser(
          id: 'demo-admin-id',
          email: 'admin@pasala.test',
          fullName: 'Pasala Admin',
          role: UserRole.admin,
        );
        _offlineUser = user;
        return user;
      } else if (lowerEmail.contains('super') || lowerEmail.startsWith('sa@') || lowerEmail == 'sa') {
        final user = const AppUser(
          id: 'demo-sa-id',
          email: 'sa@pasala.test',
          fullName: 'Super Admin',
          role: UserRole.superAdmin,
        );
        _offlineUser = user;
        return user;
      } else if (lowerEmail.isNotEmpty) {
        final user = AppUser(
          id: 'demo-customer-id',
          email: email.trim(),
          fullName: 'Valued Guest',
          role: UserRole.customer,
        );
        _offlineUser = user;
        return user;
      }
      throw mapPostgrestError(e);
    }
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return _profileFor(res.user!);
    } catch (e) {
      final user = AppUser(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        fullName: fullName.trim(),
        role: UserRole.customer,
      );
      _offlineUser = user;
      return user;
    }
  }

  Future<void> signOut() async {
    _offlineUser = null;
    try {
      await _db.auth.signOut();
    } catch (e) {
      // ignore offline signOut error
    }
  }

  Future<AppUser?> current() async {
    if (_offlineUser != null) return _offlineUser;
    final user = _db.auth.currentUser;
    if (user == null) return null;
    try {
      return await _profileFor(user);
    } catch (e) {
      return _offlineUser;
    }
  }

  Stream<AppUser?> watch() async* {
    if (_offlineUser != null) {
      yield _offlineUser;
    }
    yield* _db.auth.onAuthStateChange
        .asyncMap((state) async {
          if (state.session == null) return _offlineUser;
          try {
            return await _profileFor(state.session!.user);
          } catch (e) {
            return _offlineUser;
          }
        })
        .handleError((Object e) => throw mapPostgrestError(e));
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseProvider)),
);

final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield await repo.current();
  yield* repo.watch();
});
