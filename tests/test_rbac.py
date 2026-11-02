#!/usr/bin/env python3
"""
Test script for GitHub Actions validation of Access Control Lab findings.
Validates rbac_matrix_template.csv and findings_template.csv.
"""
import csv
import sys
import os

EXPECTED_ROLES = ["R01", "R02", "R03", "R04", "R05", "R06", "R07", "R08"]
EXPECTED_RESOURCES = [
    "/medport/ehr/patient_records",
    "/medport/ehr/lab_results",
    "/medport/ehr/imaging",
    "/medport/portal/public",
    "/medport/portal/patient",
    "/medport/portal/provider",
    "/medport/admin/audit_logs",
    "/medport/admin/config",
    "/medport/admin/backups",
    "/medport/shared/policies",
    "/medport/shared/schedules"
]
VALID_PERMISSIONS = {"N", "R", "W", "D", "A", "RW", "RX", "RWX"}

def validate_rbac_matrix(csv_path):
    errors = []
    warnings = []
    
    if not os.path.exists(csv_path):
        errors.append(f"File not found: {csv_path}")
        return errors, warnings
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    # Check we have 88 rows (8 roles × 11 resources)
    if len(rows) != 88:
        errors.append(f"Expected 88 rows (8 roles × 11 resources), got {len(rows)}")
    
    # Check all role-resource combinations present
    seen = set()
    for i, row in enumerate(rows):
        role_id = row.get("role_id", "").strip()
        resource = row.get("resource", "").strip()
        permission = row.get("permission", "").strip()
        
        key = (role_id, resource)
        if key in seen:
            errors.append(f"Row {i+2}: Duplicate role-resource combination: {role_id} × {resource}")
        seen.add(key)
        
        if role_id not in EXPECTED_ROLES:
            errors.append(f"Row {i+2}: Invalid role_id: {role_id}")
        
        if resource not in EXPECTED_RESOURCES:
            errors.append(f"Row {i+2}: Invalid resource: {resource}")
        
        if permission and permission not in VALID_PERMISSIONS:
            warnings.append(f"Row {i+2}: Unusual permission format: {permission}")
        
        if not permission:
            warnings.append(f"Row {i+2}: Empty permission for {role_id} × {resource}")
    
    # Check all combinations covered
    for role in EXPECTED_ROLES:
        for resource in EXPECTED_RESOURCES:
            if (role, resource) not in seen:
                errors.append(f"Missing combination: {role} × {resource}")
    
    return errors, warnings

def validate_findings(csv_path):
    errors = []
    warnings = []
    
    if not os.path.exists(csv_path):
        errors.append(f"File not found: {csv_path}")
        return errors, warnings
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    required_cols = ["finding_id", "test_category", "role", "resource", "action", "expected_result", "actual_result", "pass_fail", "notes"]
    if reader.fieldnames != required_cols:
        errors.append(f"Invalid columns. Expected: {required_cols}, Got: {reader.fieldnames}")
    
    # Check for actual_result and pass_fail populated
    for i, row in enumerate(rows):
        actual = row.get("actual_result", "").strip()
        pf = row.get("pass_fail", "").strip()
        
        if not actual:
            warnings.append(f"Row {i+2} ({row.get('finding_id')}): Empty actual_result")
        if not pf:
            warnings.append(f"Row {i+2} ({row.get('finding_id')}): Empty pass_fail")
        
        if pf and pf not in {"PASS", "FAIL"}:
            errors.append(f"Row {i+2}: pass_fail must be PASS or FAIL, got: {pf}")
    
    return errors, warnings

if __name__ == "__main__":
    rbac_path = sys.argv[1] if len(sys.argv) > 1 else "rbac_matrix_template.csv"
    findings_path = sys.argv[2] if len(sys.argv) > 2 else "findings_template.csv"
    
    all_errors = []
    all_warnings = []
    
    print(f"[*] Validating RBAC matrix: {rbac_path}")
    rbac_errors, rbac_warnings = validate_rbac_matrix(rbac_path)
    all_errors.extend(rbac_errors)
    all_warnings.extend(rbac_warnings)
    
    print(f"[*] Validating findings: {findings_path}")
    findings_errors, findings_warnings = validate_findings(findings_path)
    all_errors.extend(findings_errors)
    all_warnings.extend(findings_warnings)
    
    if all_warnings:
        print("\n[WARNINGS]")
        for w in all_warnings:
            print(f"  ! {w}")
    
    if all_errors:
        print("\n[ERRORS]")
        for e in all_errors:
            print(f"  ✗ {e}")
        print(f"\nValidation FAILED: {len(all_errors)} errors")
        sys.exit(1)
    else:
        print("\n[SUCCESS] All validations passed!")
        sys.exit(0)