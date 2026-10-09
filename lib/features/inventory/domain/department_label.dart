import 'package:horeca_app/shared/models/department_model.dart';

/// Название отдела для отчёта инвентаризации.
/// Сначала ищет отдел в справочнике (новые отделы получают id из времени,
/// а не «1»…«5»), затем оставляет старые имена встроенных отделов.
String inventoryDepartmentLabel({
  required String? departmentId,
  required List<DepartmentModel> departments,
  required String allDepartmentsLabel,
}) {
  if (departmentId == null || departmentId.isEmpty) {
    return 'Неизвестный отдел';
  }
  if (departmentId == 'all') return allDepartmentsLabel;
  for (final department in departments) {
    if (department.id == departmentId && department.name.trim().isNotEmpty) {
      return department.name;
    }
  }
  switch (departmentId) {
    case '1':
      return 'Кухня';
    case '2':
      return 'Бар';
    case '3':
      return 'Зал';
    case '4':
      return 'Склад';
    case '5':
      return 'Клининг';
    default:
      return departmentId;
  }
}
