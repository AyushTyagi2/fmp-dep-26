// lib/shared/profile/profile_data.dart
//
// Mirrors the backend ProfileDto exactly.
// All fields except phone/fullName/role/memberSince are nullable
// since they only apply to specific roles.

class ProfileData {
  // ── Common ────────────────────────────────────────────────────────────────
  final String phone;
  final String fullName;
  final String role;
  final DateTime memberSince;

  // ── Driver ────────────────────────────────────────────────────────────────
  final String?   licenseNumber;
  final String?   licenseType;
  final DateTime? licenseExpiry;
  final String?   driverStatus;
  final bool?     driverVerified;
  final double?   averageRating;
  final int?      totalTrips;
  final String?   vehicleNumber;
  final String?   vehicleType;

  // ── Sender / Org ──────────────────────────────────────────────────────────
  final String? orgName;
  final String? orgType;
  final String? contactEmail;
  final String? industry;
  final String? city;
  final String? state;
  final String? gstNumber;
  final String? panNumber;

  // ── Fleet owner ───────────────────────────────────────────────────────────
  final String? businessName;
  final String? businessType;
  final String? businessContactEmail;
  final bool?   fleetVerified;

  const ProfileData({
    required this.phone,
    required this.fullName,
    required this.role,
    required this.memberSince,
    this.licenseNumber,
    this.licenseType,
    this.licenseExpiry,
    this.driverStatus,
    this.driverVerified,
    this.averageRating,
    this.totalTrips,
    this.vehicleNumber,
    this.vehicleType,
    this.orgName,
    this.orgType,
    this.contactEmail,
    this.industry,
    this.city,
    this.state,
    this.gstNumber,
    this.panNumber,
    this.businessName,
    this.businessType,
    this.businessContactEmail,
    this.fleetVerified,
  });

  factory ProfileData.fromJson(Map<String, dynamic> j) => ProfileData(
        phone:       j['phone'] as String? ?? '',
        fullName:    j['fullName'] as String? ?? '',
        role:        j['role'] as String? ?? '',
        memberSince: j['memberSince'] != null
            ? DateTime.tryParse(j['memberSince'] as String) ?? DateTime(2024)
            : DateTime(2024),

        licenseNumber:  j['licenseNumber']  as String?,
        licenseType:    j['licenseType']    as String?,
        licenseExpiry:  j['licenseExpiry'] != null
            ? DateTime.tryParse(j['licenseExpiry'] as String)
            : null,
        driverStatus:   j['driverStatus']   as String?,
        driverVerified: j['driverVerified'] as bool?,
        averageRating:  (j['averageRating'] as num?)?.toDouble(),
        totalTrips:     j['totalTrips']     as int?,
        vehicleNumber:  j['vehicleNumber']  as String?,
        vehicleType:    j['vehicleType']    as String?,

        orgName:      j['orgName']      as String?,
        orgType:      j['orgType']      as String?,
        contactEmail: j['contactEmail'] as String?,
        industry:     j['industry']     as String?,
        city:         j['city']         as String?,
        state:        j['state']        as String?,
        gstNumber:    j['gstNumber']    as String?,
        panNumber:    j['panNumber']    as String?,

        businessName:         j['businessName']         as String?,
        businessType:         j['businessType']         as String?,
        businessContactEmail: j['businessContactEmail'] as String?,
        fleetVerified:        j['fleetVerified']        as bool?,
      );
}