import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState {
  final String? name;
  final int? age;
  final String? profilePicPath;
  final bool isLoading;

  ProfileState({
    this.name,
    this.age,
    this.profilePicPath,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? name,
    int? age,
    String? profilePicPath,
    bool? isLoading,
  }) {
    return ProfileState(
      name: name ?? this.name,
      age: age ?? this.age,
      profilePicPath: profilePicPath ?? this.profilePicPath,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState(isLoading: true)) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');
    final age = prefs.getInt('profile_age');
    final profilePicPath = prefs.getString('profile_pic_path');

    state = ProfileState(
      name: name,
      age: age,
      profilePicPath: profilePicPath,
      isLoading: false,
    );
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    String? profilePicPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('profile_name', name);
    if (age != null) await prefs.setInt('profile_age', age);
    if (profilePicPath != null)
      await prefs.setString('profile_pic_path', profilePicPath);

    state = state.copyWith(
      name: name ?? state.name,
      age: age ?? state.age,
      profilePicPath: profilePicPath ?? state.profilePicPath,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});
