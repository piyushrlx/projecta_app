class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String adminScope;
  final bool mustChangePassword;
  final String? token;
  final String? username;
  final String? phone;
  final String? designation;
  final int? departmentId;
  final String? departmentName;
  final String? profilePhotoUrl;
  final String? expiresAt;
  final String? employeeCode;
  final String? reportingManagerName;
  final String? joiningDate;
  final bool reportingRequired;
  final String? lastLoginAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.adminScope,
    required this.mustChangePassword,
    this.token,
    this.username,
    this.phone,
    this.designation,
    this.departmentId,
    this.departmentName,
    this.profilePhotoUrl,
    this.expiresAt,
    this.employeeCode,
    this.reportingManagerName,
    this.joiningDate,
    this.reportingRequired = true,
    this.lastLoginAt,
  });

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isStaff => role == 'staff';
  String get fullName => name;

  String get roleLabel {
    if (role == 'super_admin') return 'Super Admin';
    if (role == 'admin') return 'Admin';
    if (role == 'staff') return 'Staff';
    return role;
  }

  /// Dynamic map indexer for backward compatibility with raw JSON access
  dynamic operator [](String key) {
    if (key == 'user') return toJson();
    if (key == 'token') return token;
    return toJson()[key];
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final dynamic idVal = json['id'];
    final int parsedId = idVal is int
        ? idVal
        : int.tryParse(idVal?.toString() ?? '0') ?? 0;

    final dynamic mustChangeVal = json['must_change_password'];
    final bool parsedMustChange =
        mustChangeVal == true || mustChangeVal == 1 || mustChangeVal == '1';

    final dynamic deptIdVal = json['department_id'];
    final int? parsedDeptId = deptIdVal is int
        ? deptIdVal
        : int.tryParse(deptIdVal?.toString() ?? '');

    final dynamic reportingReqVal = json['reporting_required'];
    final bool parsedReportingRequired = reportingReqVal == null
        ? true
        : (reportingReqVal == true ||
              reportingReqVal == 1 ||
              reportingReqVal == '1');

    return UserModel(
      id: parsedId,
      name: (json['name'] ?? json['full_name'] ?? json['username'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'staff').toString(),
      adminScope: (json['admin_scope'] ?? json['adminScope'] ?? 'assigned')
          .toString(),
      mustChangePassword: parsedMustChange,
      token: (token ?? json['token'])?.toString(),
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      designation: json['designation']?.toString(),
      departmentId: parsedDeptId,
      departmentName: json['department_name']?.toString(),
      profilePhotoUrl: (json['profile_photo_url'] ?? json['profile_photo'])
          ?.toString(),
      expiresAt: json['expires_at']?.toString(),
      employeeCode: json['employee_code']?.toString(),
      reportingManagerName:
          (json['reporting_manager_name'] ?? json['manager_name'])?.toString(),
      joiningDate: json['joining_date']?.toString(),
      reportingRequired: parsedReportingRequired,
      lastLoginAt: (json['last_login_at'] ?? json['last_login'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': name,
      'email': email,
      'role': role,
      'admin_scope': adminScope,
      'must_change_password': mustChangePassword,
      'token': token,
      'username': username,
      'phone': phone,
      'designation': designation,
      'department_id': departmentId,
      'department_name': departmentName,
      'profile_photo_url': profilePhotoUrl,
      'expires_at': expiresAt,
      'employee_code': employeeCode,
      'reporting_manager_name': reportingManagerName,
      'joining_date': joiningDate,
      'reporting_required': reportingRequired,
      'last_login_at': lastLoginAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? adminScope,
    bool? mustChangePassword,
    String? token,
    String? username,
    String? phone,
    String? designation,
    int? departmentId,
    String? departmentName,
    String? profilePhotoUrl,
    String? expiresAt,
    String? employeeCode,
    String? reportingManagerName,
    String? joiningDate,
    bool? reportingRequired,
    String? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      adminScope: adminScope ?? this.adminScope,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      token: token ?? this.token,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      employeeCode: employeeCode ?? this.employeeCode,
      reportingManagerName: reportingManagerName ?? this.reportingManagerName,
      joiningDate: joiningDate ?? this.joiningDate,
      reportingRequired: reportingRequired ?? this.reportingRequired,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role, adminScope: $adminScope, mustChangePassword: $mustChangePassword)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, email, role);
}
