import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/household_model.dart';
import '../domain/profile_model.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': displayName},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final data = await _client
        .from(tableProfiles)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<void> updateAvatarEmoji(String userId, String emoji) async {
    await _client
        .from(tableProfiles)
        .update({'avatar_emoji': emoji})
        .eq('id', userId);
  }

  Future<HouseholdModel> createHousehold(String userId) async {
    final result = await _client
        .rpc('create_household_for_user', params: {'user_id': userId});
    final model = HouseholdModel.fromJson(result as Map<String, dynamic>);
    await _client.from(tableProfileHouseholdMemberships).upsert({
      'profile_id': userId,
      'household_id': model.id,
    });
    return model;
  }

  Future<HouseholdModel?> getHousehold(String id) async {
    final data = await _client
        .from(tableHouseholds)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return HouseholdModel.fromJson(data);
  }

  Future<List<ProfileModel>> getHouseholdMembers(String householdId) async {
    final data = await _client
        .from(tableProfiles)
        .select()
        .eq('household_id', householdId);
    return (data as List).map((e) => ProfileModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateHouseholdName(String householdId, String newName) async {
    await _client
        .from(tableHouseholds)
        .update({'name': newName})
        .eq('id', householdId);
  }

  Future<void> removeHouseholdMember(String memberId, String householdId) async {
    await _client
        .from(tableProfileHouseholdMemberships)
        .delete()
        .eq('profile_id', memberId)
        .eq('household_id', householdId);
    await _client
        .from(tableProfiles)
        .update({'household_id': null})
        .eq('id', memberId);
  }

  Future<HouseholdModel> joinHousehold(String inviteCode, String userId) async {
    final data = await _client
        .from(tableHouseholds)
        .select()
        .eq('invite_code', inviteCode.trim())
        .maybeSingle();
    if (data == null) throw Exception('Invite code not found. Check and try again.');
    final model = HouseholdModel.fromJson(data);
    await _client
        .from(tableProfiles)
        .update({'household_id': model.id})
        .eq('id', userId);
    await _client.from(tableProfileHouseholdMemberships).upsert({
      'profile_id': userId,
      'household_id': model.id,
    });
    return model;
  }

  Future<List<HouseholdModel>> getMyHouseholds(String userId) async {
    final data = await _client
        .from(tableProfileHouseholdMemberships)
        .select('household_id, households(*)')
        .eq('profile_id', userId);
    return (data as List)
        .map((e) => HouseholdModel.fromJson(e['households'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> switchHousehold(String userId, String householdId) async {
    await _client
        .from(tableProfiles)
        .update({'household_id': householdId})
        .eq('id', userId);
  }

  Future<void> leaveHousehold(String userId, String householdId) async {
    await _client
        .from(tableProfileHouseholdMemberships)
        .delete()
        .eq('profile_id', userId)
        .eq('household_id', householdId);
    // If this was the active household, clear it (router redirects to /household-link)
    await _client
        .from(tableProfiles)
        .update({'household_id': null})
        .eq('id', userId)
        .eq('household_id', householdId);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  final user = authState.session?.user;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getProfile(user.id);
});

final currentHouseholdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return null;
  return ref.watch(authRepositoryProvider).getHousehold(profile!.householdId!);
});

final householdMembersProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  return ref.watch(authRepositoryProvider).getHouseholdMembers(profile!.householdId!);
});

final myHouseholdsProvider = FutureProvider<List<HouseholdModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(authRepositoryProvider).getMyHouseholds(profile.id);
});
