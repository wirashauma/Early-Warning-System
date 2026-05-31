class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String category;
  final bool isActive;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    required this.isActive,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'category': category,
        'isActive': isActive,
      };

  /// Returns a human-readable label for the category
  String get categoryLabel {
    switch (category) {
      case 'BPBD':
        return 'BPBD';
      case 'SAR':
        return 'SAR / Basarnas';
      case 'AMBULANCE':
        return 'Ambulans';
      case 'POLICE':
        return 'Polisi';
      case 'HOSPITAL':
        return 'Rumah Sakit';
      default:
        return 'Lainnya';
    }
  }

  /// Response-time estimates per category
  String get responseTimeLabel {
    switch (category) {
      case 'BPBD':
        return '± 5-15 menit (tergantung akses lapangan)';
      case 'SAR':
        return 'Prioritas tinggi untuk kondisi kritis';
      case 'AMBULANCE':
        return 'Secepat mungkin sesuai antrian darurat';
      case 'POLICE':
        return 'Sesuai prioritas kejadian lapangan';
      case 'HOSPITAL':
        return 'Bergantung kapasitas rumah sakit';
      default:
        return 'Secepat mungkin';
    }
  }

  /// Focus-area description per category
  String get focusLabel {
    switch (category) {
      case 'BPBD':
        return 'Koordinasi tanggap bencana & evakuasi wilayah';
      case 'SAR':
        return 'Pencarian dan penyelamatan korban';
      case 'AMBULANCE':
        return 'Pertolongan medis darurat';
      case 'POLICE':
        return 'Pengamanan lokasi & dukungan evakuasi';
      case 'HOSPITAL':
        return 'Rujukan medis lanjutan & kegawatdaruratan';
      default:
        return 'Respon darurat umum';
    }
  }

  /// Fallback contacts shown when API is unreachable
  static List<EmergencyContactModel> get fallbackList => const [
        EmergencyContactModel(
          id: 'fallback-1',
          name: 'Ambulans',
          phone: '118',
          category: 'AMBULANCE',
          isActive: true,
        ),
        EmergencyContactModel(
          id: 'fallback-2',
          name: 'Basarnas',
          phone: '115',
          category: 'SAR',
          isActive: true,
        ),
        EmergencyContactModel(
          id: 'fallback-3',
          name: 'BPBD Kota Padang',
          phone: '117',
          category: 'BPBD',
          isActive: true,
        ),
        EmergencyContactModel(
          id: 'fallback-4',
          name: 'Polisi',
          phone: '110',
          category: 'POLICE',
          isActive: true,
        ),
        EmergencyContactModel(
          id: 'fallback-5',
          name: 'RS Umum Daerah',
          phone: '119',
          category: 'HOSPITAL',
          isActive: true,
        ),
      ];
}
