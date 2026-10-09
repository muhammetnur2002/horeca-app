import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/inventory/domain/department_label.dart';
import 'package:horeca_app/shared/models/department_model.dart';

void main() {
  test('новый отдел показывается по имени, а не по числовому id', () {
    final label = inventoryDepartmentLabel(
      departmentId: '1710000000000',
      departments: [
        DepartmentModel(id: '1710000000000', name: 'Летник', icon: Icons.deck),
      ],
      allDepartmentsLabel: 'Все отделы',
    );
    expect(label, 'Летник');
  });

  test('все отделы и пустой id остаются понятными', () {
    expect(
      inventoryDepartmentLabel(
        departmentId: 'all',
        departments: <DepartmentModel>[],
        allDepartmentsLabel: 'Все отделы',
      ),
      'Все отделы',
    );
    expect(
      inventoryDepartmentLabel(
        departmentId: null,
        departments: <DepartmentModel>[],
        allDepartmentsLabel: 'Все отделы',
      ),
      'Неизвестный отдел',
    );
  });
}
