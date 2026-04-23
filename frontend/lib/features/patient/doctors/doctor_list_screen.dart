import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';
import 'doctor_model.dart';
import 'doctor_booking_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  // ── Theme ─────────────────────────────────────────────────────────────────
  static const Color primaryLavender = Color(0xFF9C89E8);
  static const Color darkLavender    = Color(0xFF5E4DB2);
  static const Color lightLavender   = Color(0xFFF5F3FF);

  // ── Filter state ──────────────────────────────────────────────────────────
  double _maxFees            = 2000;
  double _minRating          = 0.0;
  double _maxDistance        = 5.0;
  String _selectedTiming     = 'Any';
  String _selectedSpeciality = 'All';
  String _selectedLocation   = 'All';
  bool   _showFilters        = false;
  bool   _ratingHighToLow    = true;
  String _searchQuery        = '';

  // ── Location state ────────────────────────────────────────────────────────
  double? _userLat;
  double? _userLon;
  bool _locationLoading = false;
  bool _locationEnabled = false;

  // ── User ──────────────────────────────────────────────────────────────────
  String userName = 'Guest User';

  // ── Static data ───────────────────────────────────────────────────────────
  static const List<String> _timings   = ['Any', 'Morning', 'Evening'];
  static const List<String> _locations = [
    'All', 'Dwarka', 'Rohini', 'Shahdara', 'Krishna Nagar',
  ];

  static const Map<String, List<String>> _specialityKeywords = {
    'All'             : [],
    'Cardiology'      : ['cardio', 'heart'],
    'Dermatology'     : ['derma', 'skin'],
    'ENT'             : ['ent', 'ear', 'nose', 'throat'],
    'General Medicine': ['general', 'physician', 'medicine', 'mbbs'],
    'Gynecology'      : ['gynec', 'gynaec', 'obstetr', 'women'],
    'Neurology'       : ['neuro', 'brain', 'nerve'],
    'Orthopaedics'    : ['ortho', 'bone', 'joint', 'spine'],
    'Pediatrics'      : ['pediatric', 'paediatric', 'child'],
    'Psychiatry'      : ['psychiatr', 'mental', 'psycho'],
    'Urology'         : ['urology', 'urologis', 'kidney', 'bladder'],
  };

  static const Map<String, IconData> _specIcons = {
    'All'             : Icons.medical_services,
    'Cardiology'      : Icons.favorite,
    'Dermatology'     : Icons.face_retouching_natural,
    'ENT'             : Icons.hearing,
    'General Medicine': Icons.local_hospital,
    'Gynecology'      : Icons.pregnant_woman,
    'Neurology'       : Icons.psychology,
    'Orthopaedics'    : Icons.accessibility_new,
    'Pediatrics'      : Icons.child_care,
    'Psychiatry'      : Icons.self_improvement,
    'Urology'         : Icons.water_drop,
  };

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => userName = prefs.getString('patient_name') ?? 'Guest User');
  }

  // ── Geolocation ───────────────────────────────────────────────────────────
  Future<void> _fetchUserLocation() async {
    setState(() => _locationLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLon = position.longitude;
        _locationEnabled = true;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location access denied. Please enable location."),
        ),
      );
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<List<Doctor>> _loadDoctors() async {
    final jsonString = await rootBundle.loadString('assets/data/doctors.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((e) => Doctor.fromJson(e)).toList();
  }

  // ── Haversine distance (km) ───────────────────────────────────────────────
  double _distKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;

  // ── Speciality match ──────────────────────────────────────────────────────
  bool _matchesSpeciality(String docSpec) {
    if (_selectedSpeciality == 'All') return true;
    final s = docSpec.toLowerCase();
    final keywords = _specialityKeywords[_selectedSpeciality] ?? [];
    return keywords.any((kw) => s.contains(kw));
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // ✅ FIX 1: allows Scaffold to resize when keyboard opens
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Find Doctors',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryLavender,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: AppDrawer(userName: userName, currentRoute: '/doctors'),
      // ✅ FIX 2: Wrap entire body in CustomScrollView so search bar,
      //    chips, filters, and doctor list all scroll together on any
      //    screen size — no more overflow when the keyboard pops up.
      body: CustomScrollView(
        slivers: [
          // Search bar — pinned so it stays visible while scrolling
          SliverToBoxAdapter(child: _searchBar()),

          // Speciality chips
          SliverToBoxAdapter(child: _specialityChipBar()),

          // Filters panel (expands / collapses)
          SliverToBoxAdapter(child: _filtersSection()),

          // Doctor list — fills the rest of the sliver
          _doctorListSliver(),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search doctor or speciality...',
          prefixIcon: const Icon(Icons.search, color: primaryLavender),
          filled: true,
          fillColor: lightLavender,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
      ),
    );
  }

  // ── SPECIALITY CHIP BAR ───────────────────────────────────────────────────
  Widget _specialityChipBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _specialityKeywords.keys.map((s) {
            final selected = _selectedSpeciality == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  _specIcons[s] ?? Icons.medical_services,
                  size: 16,
                  color: selected ? Colors.white : darkLavender,
                ),
                label: Text(s),
                selected: selected,
                selectedColor: primaryLavender,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? primaryLavender : Colors.grey.shade300,
                ),
                onSelected: (_) => setState(() => _selectedSpeciality = s),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── FILTERS SECTION ───────────────────────────────────────────────────────
  Widget _filtersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // ✅ FIX 3: No fixed height — lets content size itself naturally
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.tune, size: 18, color: darkLavender),
                const SizedBox(width: 6),
                const Text('Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              TextButton(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                style: TextButton.styleFrom(foregroundColor: primaryLavender),
                child: Text(_showFilters ? 'Hide' : 'Expand'),
              ),
            ],
          ),

          if (_showFilters) ...[
            const Divider(height: 8),

            _lbl('Location'),
            const SizedBox(height: 4),
            _styledDropdown<String>(
              value: _selectedLocation,
              items: _locations,
              labelBuilder: (e) => e,
              onChanged: (v) => setState(() => _selectedLocation = v!),
            ),
            const SizedBox(height: 12),

            _sliderRow(
              label: 'Max Fees',
              badge: '₹${_maxFees.toInt()}',
              badgeColor: darkLavender,
              child: Slider(
                activeColor: primaryLavender,
                inactiveColor: lightLavender,
                min: 300,
                max: 2000,
                divisions: 34,
                value: _maxFees,
                onChanged: (v) => setState(() => _maxFees = v),
              ),
            ),

            _sliderRow(
              label: 'Min Rating',
              badge: '${_minRating.toStringAsFixed(1)} ⭐',
              badgeColor: Colors.amber.shade700,
              child: Slider(
                activeColor: Colors.amber,
                inactiveColor: Colors.amber.shade100,
                min: 0.0,
                max: 5.0,
                divisions: 50,
                value: _minRating,
                onChanged: (v) => setState(() => _minRating = v),
              ),
            ),

            _sliderRow(
              label: 'Max Distance',
              badge: _locationEnabled
                  ? '${_maxDistance.toInt()} km'
                  : 'Off — tap 📍',
              badgeColor: Colors.teal,
              child: Row(children: [
                Expanded(
                  child: Slider(
                    activeColor: Colors.teal,
                    inactiveColor: Colors.teal.shade50,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    value: _maxDistance,
                    label: '${_maxDistance.toInt()} km',
                    onChanged: _locationEnabled
                        ? (v) => setState(() => _maxDistance = v)
                        : null,
                  ),
                ),
                Tooltip(
                  message: _locationEnabled
                      ? 'Location active'
                      : 'Tap to use your location',
                  child: GestureDetector(
                    onTap: _locationLoading ? null : _fetchUserLocation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _locationEnabled
                            ? Colors.teal
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: _locationLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _locationEnabled
                                  ? Icons.location_on
                                  : Icons.location_off,
                              size: 16,
                              color: _locationEnabled
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                    ),
                  ),
                ),
              ]),
            ),

            if (!_locationEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Tap 📍 to enable distance filter using your location.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),

            const SizedBox(height: 8),

            Row(children: [
              Expanded(
                child: _labelledDropdown(
                  label: 'Availability',
                  child: _styledDropdown<String>(
                    value: _selectedTiming,
                    items: _timings,
                    labelBuilder: (e) => e,
                    onChanged: (v) => setState(() => _selectedTiming = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labelledDropdown(
                  label: 'Sort by Rating',
                  child: _styledDropdown<bool>(
                    value: _ratingHighToLow,
                    items: const [true, false],
                    labelBuilder: (e) => e ? 'High → Low' : 'Low → High',
                    onChanged: (v) => setState(() => _ratingHighToLow = v!),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  // ── Filter widget helpers ─────────────────────────────────────────────────
  Widget _lbl(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      );

  Widget _sliderRow({
    required String label,
    required String badge,
    required Color badgeColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
        ),
        child,
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _styledDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: lightLavender,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: primaryLavender),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(labelBuilder(e),
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _labelledDropdown({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  // ── DOCTOR LIST as Sliver ─────────────────────────────────────────────────
  // ✅ FIX 4: Changed from Expanded+ListView to SliverList so it works
  //    inside CustomScrollView without needing a fixed height parent.
  Widget _doctorListSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: FutureBuilder<List<Doctor>>(
        future: _loadDoctors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: primaryLavender)),
            );
          }

          var doctors = snapshot.data!.where((d) {
            if (_searchQuery.isNotEmpty) {
              if (!d.name.toLowerCase().contains(_searchQuery) &&
                  !d.speciality.toLowerCase().contains(_searchQuery)) {
                return false;
              }
            }

            if (d.fees > _maxFees) return false;
            if (d.rating < _minRating) return false;

            if (_locationEnabled && _userLat != null && _userLon != null) {
              final dist =
                  _distKm(_userLat!, _userLon!, d.latitude, d.longitude);
              if (dist > _maxDistance) return false;
            }

            if (_selectedLocation != 'All') {
              if (!d.area
                  .toLowerCase()
                  .contains(_selectedLocation.toLowerCase())) {
                return false;
              }
            }

            if (_selectedTiming != 'Any') {
              final a = d.availability.toLowerCase();
              if (_selectedTiming == 'Morning' && !a.contains('am')) {
                return false;
              }
              if (_selectedTiming == 'Evening' && !a.contains('pm')) {
                return false;
              }
            }

            if (!_matchesSpeciality(d.speciality)) return false;

            return true;
          }).toList();

          doctors.sort((a, b) => _ratingHighToLow
              ? b.rating.compareTo(a.rating)
              : a.rating.compareTo(b.rating));

          if (doctors.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No doctors found',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _doctorCard(doctors[i], i),
              childCount: doctors.length,
            ),
          );
        },
      ),
    );
  }

  // ── DOCTOR CARD ───────────────────────────────────────────────────────────
  Widget _doctorCard(Doctor d, int index) {
    String? distLabel;
    if (_locationEnabled && _userLat != null && _userLon != null) {
      final km = _distKm(_userLat!, _userLon!, d.latitude, d.longitude);
      distLabel =
          km < 1 ? '${(km * 1000).toInt()} m' : '${km.toStringAsFixed(1)} km';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index % 8) * 60),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // Top row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: lightLavender,
                child: Text(
                  d.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkLavender,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(d.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(d.speciality,
                        style: const TextStyle(
                            color: primaryLavender,
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            d.address,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),

            // Bottom row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _tag(Icons.account_balance_wallet, '₹${d.fees}'),
                      _tag(
                        Icons.access_time,
                        d.availability.split('|').last.trim(),
                      ),
                      if (distLabel != null)
                        _tag(Icons.directions_walk, distLabel,
                            color: Colors.teal),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconBtn(
                      icon: Icons.call,
                      color: Colors.green,
                      onTap: () => _makeCall(d.phone),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorBookingScreen(doctor: d),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryLavender,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Book',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text,
      {Color color = const Color(0xFF777777), double? maxWidth}) {
    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    if (maxWidth != null) {
      row = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: row);
    }
    return row;
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}