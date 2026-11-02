# AP Cyber Unit 5 Lab: Access Control Simulation — RBAC Matrix & Linux Permissions

**Course**: AP Computer Science Principles — Cybersecurity
**Unit**: 5 — Application & Data Security
**Topic**: 5.2 Access Control Models (DAC, MAC, RBAC, ABAC)

---

## Lab Overview

In this lab, you will design a **Role-Based Access Control (RBAC) matrix** for a simulated healthcare system, then implement and verify the permissions using **Linux file permissions (chmod/chown)** and **ACLs**. You will submit your RBAC design and verification evidence via GitHub Actions.

---

## Learning Objectives

By the end of this lab, you will be able to:
- ☐ Analyze requirements and design an **RBAC role-permission matrix**
- ☐ Implement permissions using **Linux standard permissions** (ugo+rwx)
- ☐ Implement fine-grained access using **POSIX ACLs** (setfacl/getfacl)
- ☐ Verify access control decisions with test cases
- ☐ Document and submit findings via GitHub Actions

---

## Prerequisites

- ☐ GitHub account with access to `ivycollegiate-development` organization
- ☐ Codespaces enabled (or Linux environment with `acl` package)
- ☐ Pre-lab worksheet completed (Lesson: Pre-Lab Access Control)

---

## Repository Structure

```
apcyber-u5-access-control-lab/
├── scenario.md                 # Healthcare system scenario
├── rbac_matrix_template.csv   # Design your RBAC matrix here
├── setup_environment.sh       # Creates test files/dirs + users
├── verify_permissions.sh      # Automated verification script
├── findings_template.csv      # Submit findings here
├── evidence/                  # Screenshots of verification
├── tests/
│   └── test_rbac.py           # GitHub Actions validation
├── .github/workflows/
│   └── grade.yml              # Auto-grading workflow
└── README.md                  # This file
```

---

## Scenario: MedPort Hospital System

> **MedPort** is a regional healthcare system with 3 hospitals, 200+ clinics, and a centralized EHR (Electronic Health Record) system. You are the security architect designing access controls for the new **Patient Portal** and **Clinical Workstation** file shares.
>
> **File Share Structure**:
> ```
> /medport/
> ├── ehr/                    # Electronic Health Records
> │   ├── patient_records/    # Individual patient charts
> │   ├── lab_results/        # Lab orders & results
> │   └── imaging/            # Radiology images (DICOM)
> ├── portal/                 # Patient Portal web assets
> │   ├── public/             # Public pages (no auth)
> │   ├── patient/            # Authenticated patient area
> │   └── provider/           # Provider-only tools
> ├── admin/                  # Administrative files
> │   ├── audit_logs/         # Immutable audit trails
> │   ├── config/             # System configuration
> │   └── backups/            # Encrypted backups
> └── shared/                 # Cross-department collaboration
>     ├── policies/           # Clinical policies & procedures
>     └── schedules/          # Staff schedules
> ```

### User Roles (8 Roles)

| Role ID | Role Name | Description |
|---------|-----------|-------------|
| R01 | **Patient** | Views own records, schedules appointments, messages providers |
| R02 | **Nurse** | Views/updates assigned patient records, enters vitals, views lab results |
| R03 | **Physician** | Full access to assigned patient records, writes orders, views imaging |
| R04 | **Specialist** | Views referred patient records, writes consult notes, views imaging |
| R05 | **Lab Tech** | Views/enters lab orders & results for assigned patients |
| R06 | **Radiologist** | Views/enters imaging studies & reports for assigned patients |
| R07 | **Admin Staff** | Manages appointments, views demographics (no clinical data) |
| R08 | **Compliance Officer** | Read-only access to all records for audit; manages audit_logs |

### Permission Levels (per resource)

| Level | Symbol | Description |
|-------|--------|-------------|
| **N** | None | No access |
| **R** | Read | View/list files |
| **W** | Write | Create/modify files |
| **D** | Delete | Remove files |
| **A** | Administer | Change permissions/ownership |

---

## Lab Procedure

### Phase 1: RBAC Matrix Design (20 min)

1. **Open** `rbac_matrix_template.csv`
2. **Complete** the matrix: For each Role × Resource combination, assign permission level (N/R/W/D/A)
3. **Principles to apply**:
   - **Least Privilege**: Minimum access needed for role function
   - **Separation of Duties**: No single role has full control over sensitive flows
   - **Need-to-Know**: Clinical roles only access assigned patients (enforced via application layer)
   - **Auditability**: Compliance Officer has read-only; audit_logs append-only

### Phase 2: Environment Setup (5 min)

```bash
# Run setup script (creates directory structure, users, groups)
chmod +x setup_environment.sh
./setup_environment.sh
```

This creates:
- Directory tree at `/tmp/medport/` (or `./medport/` in Codespaces)
- Linux users: `patient1`, `nurse1`, `physician1`, `specialist1`, `labtech1`, `radiologist1`, `admin1`, `compliance1`
- Linux groups: `patients`, `nurses`, `physicians`, `specialists`, `labtechs`, `radiologists`, `admins`, `compliance`

### Phase 3: Implement Permissions (15 min)

**Standard permissions (chmod/chown)** for baseline access:
```bash
# Example: Physicians read/write ehr/patient_records
chown physician1:physicians /tmp/medport/ehr/patient_records
chmod 770 /tmp/medport/ehr/patient_records
```

**ACLs (setfacl/getfacl)** for fine-grained exceptions:
```bash
# Example: Nurses read access to patient_records (assigned patients only via app)
setfacl -m g:nurses:rx /tmp/medport/ehr/patient_records
setfacl -m g:nurses:rx /tmp/medport/ehr/lab_results

# Compliance officer read-only everywhere
setfacl -m u:compliance1:rX -R /tmp/medport/

# Audit logs: append-only for compliance, no delete
setfacl -m u:compliance1:rx /tmp/medport/admin/audit_logs
chattr +a /tmp/medport/admin/audit_logs/*.log  # Linux immutable/append-only
```

### Phase 4: Verification (15 min)

Run automated verification:
```bash
chmod +x verify_permissions.sh
./verify_permissions.sh
```

Or run Python test suite:
```bash
python3 tests/test_rbac.py
```

### Phase 5: Documentation & Submission (5 min)

- ☐ Complete `findings_template.csv` with:
  - Your RBAC matrix decisions (export from rbac_matrix_template.csv)
  - Verification results (PASS/FAIL per test case)
  - Any ACL exceptions documented
- ☐ Add screenshots to `evidence/`:
  - `getfacl_output.png` (showing ACLs on key directories)
  - `verification_results.png` (script output)
- ☐ Commit & push → GitHub Actions grades automatically

---

## RBAC Matrix Template (rbac_matrix_template.csv)

```csv
role_id,role_name,resource,permission,justification
R01,Patient,/medport/ehr/patient_records,R,"Own records only (app-enforced)"
R01,Patient,/medport/ehr/lab_results,R,"Own results only"
R01,Patient,/medport/ehr/imaging,N,"No direct imaging access"
R01,Patient,/medport/portal/public,R,"Public pages"
R01,Patient,/medport/portal/patient,RW,"Own portal data"
R01,Patient,/medport/portal/provider,N,"Provider only"
R01,Patient,/medport/admin/audit_logs,N,"No admin access"
R01,Patient,/medport/admin/config,N,"No admin access"
R01,Patient,/medport/admin/backups,N,"No admin access"
R01,Patient,/medport/shared/policies,R,"Patient-facing policies"
R01,Patient,/medport/shared/schedules,R,"Own appointments"
R02,Nurse,/medport/ehr/patient_records,RW,"Assigned patients"
R02,Nurse,/medport/ehr/lab_results,R,"View results"
R02,Nurse,/medport/ehr/imaging,N,"No imaging access"
R02,Nurse,/medport/portal/public,R,"Public pages"
R02,Nurse,/medport/portal/patient,N,"Patient portal only"
R02,Nurse,/medport/portal/provider,R,"Provider tools access"
R02,Nurse,/medport/admin/audit_logs,N,"No audit access"
R02,Nurse,/medport/admin/config,N,"No config access"
R02,Nurse,/medport/admin/backups,N,"No backup access"
R02,Nurse,/medport/shared/policies,R,"Clinical policies"
R02,Nurse,/medport/shared/schedules,R,"View schedules"
# ... continue for all 8 roles × 11 resources = 88 rows
```

---

## Grading Rubric (GitHub Actions)

| Criterion | Points |
|-----------|--------|
| RBAC Matrix: All 88 cells populated | 20 pts |
| Least Privilege: No over-privileged roles | 15 pts |
| Separation of Duties: Admin/Clinical separated | 15 pts |
| Standard Permissions: chmod/chown correct | 15 pts |
| ACLs: setfacl used for exceptions | 15 pts |
| Verification: All test cases PASS | 20 pts |
| **Total** | **100 pts** |

---

## Resources

- **Linux Permissions**: `man chmod`, `man chown`, `man setfacl`, `man getfacl`
- **RBAC NIST Model**: https://csrc.nist.gov/projects/role-based-access-control
- **POSIX ACLs**: https://www.redhat.com/sysadmin/linux-acls
- **HIPAA Access Control**: 45 CFR § 164.312(a)(1)

---

## Academic Integrity

- ☐ **No sharing matrices** — independent design
- ☐ **Writeups in your own words**
- ☐ **Scope**: Only this lab environment
- ☐ **Violations** → zero for lab + disciplinary referral