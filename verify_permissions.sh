#!/bin/bash
# verify_permissions.sh - Tests RBAC implementation against expected access

set -e

MEDPORT_ROOT="${MEDPORT_ROOT:-/tmp/medport}"
PASS=0
FAIL=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_access() {
    local user=$1
    local path=$2
    local expected=$3  # "allow" or "deny"
    local action=$4    # "read", "write", "execute"
    local description=$5

    # Map action to test command
    case $action in
        read)   test_cmd="cat" ;;
        write)  test_cmd="echo test >" ;;
        execute) test_cmd="ls" ;;
        *) echo "Unknown action: $action"; return 1 ;;
    esac

    # Run test as user
    if sudo -u "$user" bash -c "$test_cmd \"$path\" 2>/dev/null"; then
        result="allow"
    else
        result="deny"
    fi

    if [[ "$result" == "$expected" ]]; then
        echo -e "${GREEN}[PASS]${NC} $description"
        echo "  User: $user | Path: $path | Action: $action | Expected: $expected | Got: $result"
        ((PASS++))
    else
        echo -e "${RED}[FAIL]${NC} $description"
        echo "  User: $user | Path: $path | Action: $action | Expected: $expected | Got: $result"
        ((FAIL++))
    fi
}

echo "[*] Verifying MedPort RBAC implementation..."
echo "=========================================="

# ===== PATIENT (R01) =====
echo -e "\n${YELLOW}=== R01: Patient ===${NC}"
test_access patient1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow read "Patient reads own record (app-enforced)"
test_access patient1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow read "Patient reads own lab results"
test_access patient1 "$MEDPORT_ROOT/ehr/imaging/template.txt" deny read "Patient denied imaging access"
test_access patient1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Patient reads public portal"
test_access patient1 "$MEDPORT_ROOT/portal/patient/dashboard.html" allow read "Patient reads patient portal"
test_access patient1 "$MEDPORT_ROOT/portal/provider/tools.html" deny read "Patient denied provider portal"
test_access patient1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny read "Patient denied audit logs"
test_access patient1 "$MEDPORT_ROOT/admin/config/system.conf" deny read "Patient denied config"
test_access patient1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Patient reads policies"
test_access patient1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Patient reads schedules"

# ===== NURSE (R02) =====
echo -e "\n${YELLOW}=== R02: Nurse ===${NC}"
test_access nurse1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow read "Nurse reads assigned patient records"
test_access nurse1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow write "Nurse writes assigned patient records"
test_access nurse1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow read "Nurse reads lab results"
test_access nurse1 "$MEDPORT_ROOT/ehr/imaging/template.txt" deny read "Nurse denied imaging"
test_access nurse1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Nurse reads public portal"
test_access nurse1 "$MEDPORT_ROOT/portal/patient/dashboard.html" deny read "Nurse denied patient portal"
test_access nurse1 "$MEDPORT_ROOT/portal/provider/tools.html" allow read "Nurse reads provider portal"
test_access nurse1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny read "Nurse denied audit logs"
test_access nurse1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Nurse reads policies"
test_access nurse1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Nurse reads schedules"

# ===== PHYSICIAN (R03) =====
echo -e "\n${YELLOW}=== R03: Physician ===${NC}"
test_access physician1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow read "Physician reads patient records"
test_access physician1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow write "Physician writes patient records"
test_access physician1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow read "Physician reads lab results"
test_access physician1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow write "Physician writes lab orders"
test_access physician1 "$MEDPORT_ROOT/ehr/imaging/template.txt" allow read "Physician reads imaging"
test_access physician1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Physician reads public portal"
test_access physician1 "$MEDPORT_ROOT/portal/patient/dashboard.html" deny read "Physician denied patient portal"
test_access physician1 "$MEDPORT_ROOT/portal/provider/tools.html" allow read "Physician reads provider portal"
test_access physician1 "$MEDPORT_ROOT/portal/provider/tools.html" allow write "Physician writes provider portal"
test_access physician1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny read "Physician denied audit logs"
test_access physician1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Physician reads policies"
test_access physician1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Physician reads schedules"

# ===== SPECIALIST (R04) =====
echo -e "\n${YELLOW}=== R04: Specialist ===${NC}"
test_access specialist1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow read "Specialist reads referred records"
test_access specialist1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow write "Specialist writes consult notes"
test_access specialist1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow read "Specialist reads lab results"
test_access specialist1 "$MEDPORT_ROOT/ehr/imaging/template.txt" allow read "Specialist reads imaging"
test_access specialist1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Specialist reads public portal"
test_access specialist1 "$MEDPORT_ROOT/portal/patient/dashboard.html" deny read "Specialist denied patient portal"
test_access specialist1 "$MEDPORT_ROOT/portal/provider/tools.html" allow read "Specialist reads provider portal"
test_access specialist1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny read "Specialist denied audit logs"
test_access specialist1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Specialist reads policies"
test_access specialist1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Specialist reads schedules"

# ===== LAB TECH (R05) =====
echo -e "\n${YELLOW}=== R05: Lab Tech ===${NC}"
test_access labtech1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" deny read "Lab tech denied patient records"
test_access labtech1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow read "Lab tech reads lab orders"
test_access labtech1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow write "Lab tech enters lab results"
test_access labtech1 "$MEDPORT_ROOT/ehr/imaging/template.txt" deny read "Lab tech denied imaging"
test_access labtech1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Lab tech reads public portal"
test_access labtech1 "$MEDPORT_ROOT/portal/patient/dashboard.html" deny read "Lab tech denied patient portal"
test_access labtech1 "$MEDPORT_ROOT/portal/provider/tools.html" deny read "Lab tech denied provider portal"
test_access labtech1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny read "Lab tech denied audit logs"
test_access labtech1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Lab tech reads policies"
test_access labtech1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Lab tech reads schedules"

# ===== RADIOLOGIST (R06) =====
echo -e "\n${YELLOW}=== R06: Radiologist ===${NC}"
test_access radiologist1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" deny read "Radiologist denied patient records"
test_access radiologist1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" deny read "Radiologist denied lab results"
test_access radiologist1 "$MEDPORT_ROOT/ehr/imaging/template.txt" allow read "Radiologist reads imaging"
test_access radiologist1 "$MEDPORT_ROOT/ehr/imaging/template.txt" allow write "Radiologist writes imaging reports"
test_access radiologist1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Radiologist reads public portal"
test_access radiologist1 "$MEDPORT_ROOT/portal/patient/dashboard.html" deny read "Radiologist denied patient portal"
test_access radiologist1 "$MEDPORT_ROOT/portal/provider/tools.html" allow read "Radiologist reads provider portal"
test_access radiologist1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny read "Radiologist denied audit logs"
test_access radiologist1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Radiologist reads policies"
test_access radiologist1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Radiologist reads schedules"

# ===== ADMIN STAFF (R07) =====
echo -e "\n${YELLOW}=== R07: Admin Staff ===${NC}"
test_access admin1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" deny read "Admin denied patient records"
test_access admin1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" deny read "Admin denied lab results"
test_access admin1 "$MEDPORT_ROOT/ehr/imaging/template.txt" deny read "Admin denied imaging"
test_access admin1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Admin reads public portal"
test_access admin1 "$MEDPORT_ROOT/portal/patient/dashboard.html" allow read "Admin reads demographics (no clinical)"
test_access admin1 "$MEDPORT_ROOT/portal/provider/tools.html" deny read "Admin denied provider portal"
test_access admin1 "$MEDPORT_ROOT/admin/config/system.conf" allow read "Admin reads config"
test_access admin1 "$MEDPORT_ROOT/admin/config/system.conf" allow write "Admin writes config"
test_access admin1 "$MEDPORT_ROOT/admin/backups/manifest.txt" deny read "Admin denied backups"
test_access admin1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Admin reads schedules"
test_access admin1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow write "Admin writes schedules"

# ===== COMPLIANCE OFFICER (R08) =====
echo -e "\n${YELLOW}=== R08: Compliance Officer ===${NC}"
test_access compliance1 "$MEDPORT_ROOT/ehr/patient_records/template.txt" allow read "Compliance reads patient records (audit)"
test_access compliance1 "$MEDPORT_ROOT/ehr/lab_results/template.txt" allow read "Compliance reads lab results (audit)"
test_access compliance1 "$MEDPORT_ROOT/ehr/imaging/template.txt" allow read "Compliance reads imaging (audit)"
test_access compliance1 "$MEDPORT_ROOT/portal/public/index.html" allow read "Compliance reads public portal"
test_access compliance1 "$MEDPORT_ROOT/portal/patient/dashboard.html" allow read "Compliance reads patient portal"
test_access compliance1 "$MEDPORT_ROOT/portal/provider/tools.html" allow read "Compliance reads provider portal"
test_access compliance1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" allow read "Compliance reads audit logs"
test_access compliance1 "$MEDPORT_ROOT/admin/audit_logs/audit.log" deny write "Compliance denied write audit (append-only)"
test_access compliance1 "$MEDPORT_ROOT/admin/config/system.conf" allow read "Compliance reads config"
test_access compliance1 "$MEDPORT_ROOT/admin/backups/manifest.txt" allow read "Compliance reads backups"
test_access compliance1 "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf" allow read "Compliance reads policies"
test_access compliance1 "$MEDPORT_ROOT/shared/schedules/week1.csv" allow read "Compliance reads schedules"

# ===== SUMMARY =====
echo ""
echo "=========================================="
echo -e "${GREEN}PASS: $PASS${NC}"
echo -e "${RED}FAIL: $FAIL${NC}"
echo "=========================================="

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}[SUCCESS] All verification tests passed!${NC}"
    exit 0
else
    echo -e "${RED}[FAILURE] $FAIL test(s) failed. Review permissions.${NC}"
    exit 1
fi