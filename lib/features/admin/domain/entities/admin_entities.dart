class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String name;
  final String phone;
  final AdminRole role;
  final bool isActive;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final raw = parts
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1))
        .join()
        .toUpperCase();
    return raw.length > 2 ? raw.substring(0, 2) : raw;
  }

  AdminUser copyWith({
    String? id,
    String? name,
    String? phone,
    AdminRole? role,
    bool? isActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum AdminRole {
  assistant(
    'assistant',
    'সহকারী (Assistant)',
    'সহকারী',
    'সব ওয়ালেট দেখতে পাবে, বাজার করবে',
  ),
  owner(
    'owner',
    'মালিক (Owner)',
    'মালিক',
    'নির্দিষ্ট wallet-এর হিসাব ম্যানেজ করবে',
  ),
  admin('admin', 'অ্যাডমিন (Admin)', 'অ্যাডমিন', 'সম্পূর্ণ সিস্টেম অ্যাক্সেস');

  const AdminRole(this.value, this.label, this.shortLabel, this.description);

  final String value;
  final String label;
  final String shortLabel;
  final String description;
}

class AdminWallet {
  const AdminWallet({
    required this.id,
    required this.name,
    required this.type,
    required this.owners,
    required this.balance,
  });

  final String id;
  final String name;
  final String type;
  final List<String> owners;
  final double balance;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final raw = parts
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1))
        .join()
        .toUpperCase();
    return raw.length > 2 ? raw.substring(0, 2) : raw;
  }
}

const adminWalletTypes = <String>['shared', 'personal', 'event', 'other'];

String adminWalletTypeLabel(String type) {
  return switch (type) {
    'shared' => 'শেয়ার্ড',
    'personal' => 'ব্যক্তিগত',
    'event' => 'ইভেন্ট',
    'other' => 'অন্যান্য',
    _ => type,
  };
}

class CreateAdminUserRequest {
  const CreateAdminUserRequest({
    required this.name,
    required this.phone,
    required this.role,
    this.walletIds = const [],
  });

  final String name;
  final String phone;
  final AdminRole role;
  final List<String> walletIds;
}

class CreateAdminWalletRequest {
  const CreateAdminWalletRequest({
    required this.name,
    required this.type,
    required this.ownerIds,
  });

  final String name;
  final String type;
  final List<String> ownerIds;
}
