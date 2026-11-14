/// Local weekly/monthly or boost record stored in SharedPreferences.
class LocalPlanRecord {
  const LocalPlanRecord({
    required this.planId,
    required this.planLabel,
    required this.packageId,
    required this.purchaseDateMs,
    required this.expiryDateMs,
    required this.active,
    required this.source,
  });

  final String planId;
  final String planLabel;
  final String packageId;
  final int purchaseDateMs;
  final int expiryDateMs;
  final bool active;
  final String source;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= expiryDateMs;

  LocalPlanRecord copyWith({bool? active}) {
    return LocalPlanRecord(
      planId: planId,
      planLabel: planLabel,
      packageId: packageId,
      purchaseDateMs: purchaseDateMs,
      expiryDateMs: expiryDateMs,
      active: active ?? this.active,
      source: source,
    );
  }

  factory LocalPlanRecord.fromJson(Map<String, dynamic> json) {
    return LocalPlanRecord(
      planId: json['plan_id']?.toString() ?? '',
      planLabel: json['plan_label']?.toString() ?? '',
      packageId: json['package_id']?.toString() ?? '',
      purchaseDateMs: (json['purchase_date_ms'] as num?)?.toInt() ?? 0,
      expiryDateMs: (json['expiry_date_ms'] as num?)?.toInt() ?? 0,
      active: json['active'] == true,
      source: json['source']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'plan_label': planLabel,
        'package_id': packageId,
        'purchase_date_ms': purchaseDateMs,
        'expiry_date_ms': expiryDateMs,
        'active': active,
        'source': source,
      };
}
