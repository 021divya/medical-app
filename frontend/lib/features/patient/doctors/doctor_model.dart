class Doctor {
  final String name;
  final String speciality;
  final String area;
  final double latitude;
  final double longitude;
  final int fees;
  final double rating;
  final String availability;
  final String phone;       // ✅ renamed from contact, handles both keys
  final String address;
  final int experience;     // ✅ new field

  Doctor({
    required this.name,
    required this.speciality,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.fees,
    required this.rating,
    required this.availability,
    required this.phone,
    required this.address,
    required this.experience,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      name:         json['name']         ?? json['Doctor / Clinic Name'] ?? 'Unknown Doctor',
      speciality:   json['speciality']   ?? json['Speciality']           ?? 'General',
      area:         json['area']         ?? json['Area']                 ?? 'Unknown Area',
      latitude:     (json['latitude']    ?? json['Latitude']             ?? 0).toDouble(),
      longitude:    (json['longitude']   ?? json['Longitude']            ?? 0).toDouble(),
      fees:         (json['fees']        ?? json['Fees (₹)']             ?? 0).toInt(),
      rating:       (json['rating']      ?? json['Rating']               ?? 0).toDouble(),
      availability: json['availability'] ?? json['Availability']         ?? 'Not Available',
      // ✅ handle both phone/contact keys safely
      phone:        json['phone']        ?? json['contact'] ?? json['Contact Number'] ?? 'N/A',
      address:      json['address']      ?? json['Address']              ?? 'No Address Provided',
      // ✅ safe int parse for experience
      experience: json['experience'] is int
          ? json['experience'] as int
          : int.tryParse(json['experience']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name':         name,
        'speciality':   speciality,
        'area':         area,
        'latitude':     latitude,
        'longitude':    longitude,
        'fees':         fees,
        'rating':       rating,
        'availability': availability,
        'phone':        phone,
        'address':      address,
        'experience':   experience,
      };
}
