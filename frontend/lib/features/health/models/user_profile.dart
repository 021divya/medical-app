class UserProfile {
  String name;
  String contact;
  String email;
  String gender;
  String dob;
  String bloodGroup;
  String maritalStatus;

  UserProfile({
    required this.name,
    required this.contact,
    required this.email,
    required this.gender,
    required this.dob,
    required this.bloodGroup,
    required this.maritalStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      maritalStatus: json['marital_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "contact": contact,
      "email": email,
      "gender": gender,
      "dob": dob,
      "blood_group": bloodGroup,
      "marital_status": maritalStatus,
    };
  }
}