import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../fleetmgr/fleet_api.dart';
import '../../fleetmgr/fleet_state.dart';
import '../../../core/models/driver.dart';
import '../../../app_session.dart';

// ─── Design tokens (mirrors driver-side palette) ────────────────────────────
const _kNavy       = Color(0xFF1B3A6B);
const _kNavyLight  = Color(0xFF254E96);
const _kSurface    = Color(0xFFF4F6FA);
const _kCardRadius = 12.0;
// ────────────────────────────────────────────────────────────────────────────

class FleetDriversScreen extends StatefulWidget {
  const FleetDriversScreen({super.key});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final phone = AppSession.phone;
    if (phone == null) return;
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final drivers = await api.getDriversByFleetOwnerPhone(phone);
      final state = context.read<FleetState>();
      state.drivers = drivers;
      state.notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load drivers: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FleetState>();
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Drivers',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDrivers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : state.drivers.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  itemCount: state.drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = state.drivers[index] as Driver;

                    final name = (d.fullName ?? '').trim();
                    String initials = '';
                    if (name.isNotEmpty) {
                      final parts = name.split(' ');
                      initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
                    } else if ((d.phone ?? '').isNotEmpty) {
                      initials = d.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                      if (initials.length > 2) initials = initials.substring(initials.length - 2);
                    }

                    final status = (d.status ?? 'unknown').toLowerCase();
                    final statusColor = status == 'active'
                        ? const Color(0xFF2E7D32)
                        : status == 'on_trip'
                            ? _kNavyLight
                            : Colors.grey[600]!;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_kCardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(_kCardRadius),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FleetDriverDetailsScreen(driverId: d.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: _kNavy.withOpacity(0.10),
                                child: Text(
                                  initials.isNotEmpty ? initials : 'DR',
                                  style: const TextStyle(
                                    color: _kNavy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.fullName.isNotEmpty ? d.fullName : d.phone,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lic: ${d.licenseNumber}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        // Status chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: statusColor.withOpacity(0.30)),
                                          ),
                                          child: Text(
                                            d.status ?? 'unknown',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (d.currentVehicle != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.local_shipping, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  d.currentVehicle!.vehicleType,
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Trailing stats
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                                      const SizedBox(width: 3),
                                      Text(
                                        (d.averageRating ?? 0).toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${d.totalTripsCompleted ?? 0} trips',
                                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No drivers found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          SizedBox(height: 4),
          Text('Pull to refresh', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Driver Details Screen ────────────────────────────────────────────────────

class FleetDriverDetailsScreen extends StatefulWidget {
  final String driverId;
  const FleetDriverDetailsScreen({required this.driverId, super.key});

  @override
  State<FleetDriverDetailsScreen> createState() => _FleetDriverDetailsScreenState();
}

class _FleetDriverDetailsScreenState extends State<FleetDriverDetailsScreen> {
  Driver? _driver;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final d = await api.getDriverById(widget.driverId);
      setState(() => _driver = d);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load driver: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : _driver == null
              ? const Center(child: Text('No details'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile header card ──────────────────────────────
                      _buildProfileHeader(),

                      const SizedBox(height: 16),

                      // ── Contact card ─────────────────────────────────────
                      _detailCard(
                        title: 'Contact',
                        icon: Icons.phone,
                        children: [
                          _detailRow(Icons.phone_outlined, _driver!.phone ?? '—'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── License + vehicle card ────────────────────────────
                      _detailCard(
                        title: 'License & Vehicle',
                        icon: Icons.badge_outlined,
                        children: [
                          _detailRow(
                            Icons.badge_outlined,
                            '${_driver!.licenseNumber}  ·  ${_driver!.licenseType}',
                          ),
                          if (_driver!.currentVehicle != null) ...[
                            const SizedBox(height: 8),
                            _detailRow(
                              Icons.local_shipping_outlined,
                              '${_driver!.currentVehicle!.registrationNumber}  ·  ${_driver!.currentVehicle!.vehicleType}',
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Stats card ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_kCardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statPill(
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber[700]!,
                              label: 'Rating',
                              value: (_driver!.averageRating ?? 0).toStringAsFixed(1),
                            ),
                            Container(width: 1, height: 36, color: Colors.grey.shade200),
                            _statPill(
                              icon: Icons.alt_route,
                              iconColor: _kNavy,
                              label: 'Trips',
                              value: '${_driver!.totalTripsCompleted ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final name = (_driver!.fullName ?? '').trim();
    final initials = name.isNotEmpty
        ? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'DR';
    final status = (_driver!.status ?? 'unknown').toLowerCase();
    final statusColor = status == 'active'
        ? const Color(0xFF2E7D32)
        : status == 'on_trip'
            ? _kNavyLight
            : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driver!.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.50)),
                  ),
                  child: Text(
                    _driver!.status ?? 'unknown',
                    style: TextStyle(
                      color: status == 'active' ? Colors.greenAccent[100] : Colors.white70,
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

  Widget _detailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _kNavy),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _kNavy,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          ),
        ),
      ],
    );
  }

  Widget _statPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}