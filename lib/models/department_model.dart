class DepartmentModel {
  final int id;
  final String name;
  final String? description;
  final int? managerId;
  final String? managerName;
  final String status;
  final int employeeCount;
  final int totalEmployeeCount;
  final int activeProjectsCount;
  final int totalProjectsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.managerId,
    this.managerName,
    this.status = 'active',
    this.employeeCount = 0,
    this.totalEmployeeCount = 0,
    this.activeProjectsCount = 0,
    this.totalProjectsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasManager => managerId != null && managerId! > 0;
  bool get isInUse => totalEmployeeCount > 0 || totalProjectsCount > 0;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int defaultValue = 0]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    DateTime? parseDateTime(dynamic val) {
      if (val == null) return null;
      if (val is String && val.trim().isNotEmpty) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    final empCount = parseInt(json['employee_count']);
    final totEmpCount = parseInt(json['total_employee_count'], empCount);
    final projCount = parseInt(json['active_projects_count']);
    final totProjCount = parseInt(json['total_projects_count'], projCount);

    return DepartmentModel(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      managerId: parseNullableInt(json['manager_id']),
      managerName: json['manager_name']?.toString(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      employeeCount: empCount,
      totalEmployeeCount: totEmpCount,
      activeProjectsCount: projCount,
      totalProjectsCount: totProjCount,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (managerId != null) 'manager_id': managerId,
      if (managerName != null) 'manager_name': managerName,
      'status': status,
      'employee_count': employeeCount,
      'total_employee_count': totalEmployeeCount,
      'active_projects_count': activeProjectsCount,
      'total_projects_count': totalProjectsCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  DepartmentModel copyWith({
    int? id,
    String? name,
    String? description,
    int? managerId,
    String? managerName,
    String? status,
    int? employeeCount,
    int? totalEmployeeCount,
    int? activeProjectsCount,
    int? totalProjectsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      status: status ?? this.status,
      employeeCount: employeeCount ?? this.employeeCount,
      totalEmployeeCount: totalEmployeeCount ?? this.totalEmployeeCount,
      activeProjectsCount: activeProjectsCount ?? this.activeProjectsCount,
      totalProjectsCount: totalProjectsCount ?? this.totalProjectsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

