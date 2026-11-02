#!/bin/bash
# setup_environment.sh - Creates MedPort directory structure, users, and groups

set -e

MEDPORT_ROOT="${MEDPORT_ROOT:-/tmp/medport}"
echo "[*] Setting up MedPort environment at $MEDPORT_ROOT"

# Create directory structure
echo "[*] Creating directory structure..."
mkdir -p "$MEDPORT_ROOT/ehr/patient_records"
mkdir -p "$MEDPORT_ROOT/ehr/lab_results"
mkdir -p "$MEDPORT_ROOT/ehr/imaging"
mkdir -p "$MEDPORT_ROOT/portal/public"
mkdir -p "$MEDPORT_ROOT/portal/patient"
mkdir -p "$MEDPORT_ROOT/portal/provider"
mkdir -p "$MEDPORT_ROOT/admin/audit_logs"
mkdir -p "$MEDPORT_ROOT/admin/config"
mkdir -p "$MEDPORT_ROOT/admin/backups"
mkdir -p "$MEDPORT_ROOT/shared/policies"
mkdir -p "$MEDPORT_ROOT/shared/schedules"

# Create sample files
echo "Patient chart template" > "$MEDPORT_ROOT/ehr/patient_records/template.txt"
echo "Lab result template" > "$MEDPORT_ROOT/ehr/lab_results/template.txt"
echo "DICOM metadata template" > "$MEDPORT_ROOT/ehr/imaging/template.txt"
echo "<html>Public page</html>" > "$MEDPORT_ROOT/portal/public/index.html"
echo "<html>Patient portal</html>" > "$MEDPORT_ROOT/portal/patient/dashboard.html"
echo "<html>Provider tools</html>" > "$MEDPORT_ROOT/portal/provider/tools.html"
echo "Audit log entry 1" > "$MEDPORT_ROOT/admin/audit_logs/audit.log"
echo "System config" > "$MEDPORT_ROOT/admin/config/system.conf"
echo "Backup manifest" > "$MEDPORT_ROOT/admin/backups/manifest.txt"
echo "Clinical policy v1.0" > "$MEDPORT_ROOT/shared/policies/clinical_policy.pdf"
echo "Weekly schedule" > "$MEDPORT_ROOT/shared/schedules/week1.csv"

# Create groups
echo "[*] Creating groups..."
for group in patients nurses physicians specialists labtechs radiologists admins compliance; do
    getent group "$group" >/dev/null 2>&1 || groupadd "$group"
    echo "  Created group: $group"
done

# Create users
echo "[*] Creating users..."
declare -A USER_GROUPS=(
    ["patient1"]="patients"
    ["nurse1"]="nurses"
    ["physician1"]="physicians"
    ["specialist1"]="specialists"
    ["labtech1"]="labtechs"
    ["radiologist1"]="radiologists"
    ["admin1"]="admins"
    ["compliance1"]="compliance"
)

for user in "${!USER_GROUPS[@]}"; do
    if ! id "$user" >/dev/null 2>&1; then
        useradd -m -s /bin/bash -G "${USER_GROUPS[$user]}" "$user"
        echo "$user:password123" | chpasswd
        echo "  Created user: $user (group: ${USER_GROUPS[$user]})"
    fi
done

# Set base ownership (will be refined by student via chmod/chown/setfacl)
echo "[*] Setting base ownership..."
chown -R physician1:physicians "$MEDPORT_ROOT/ehr"
chown -R physician1:physicians "$MEDPORT_ROOT/portal/provider"
chown -R admin1:admins "$MEDPORT_ROOT/admin"
chown -R admin1:admins "$MEDPORT_ROOT/shared"
chown -R patient1:patients "$MEDPORT_ROOT/portal/public"
chown -R patient1:patients "$MEDPORT_ROOT/portal/patient"

# Set base permissions (students will modify)
echo "[*] Setting base permissions..."
chmod -R 750 "$MEDPORT_ROOT/ehr"
chmod -R 750 "$MEDPORT_ROOT/portal"
chmod -R 750 "$MEDPORT_ROOT/admin"
chmod -R 750 "$MEDPORT_ROOT/shared"

# Install acl package if needed
if ! command -v setfacl >/dev/null 2>&1; then
    echo "[*] Installing acl package..."
    apt-get update && apt-get install -y acl
fi

echo "[*] Setup complete!"
echo ""
echo "Directory structure:"
tree "$MEDPORT_ROOT" 2>/dev/null || find "$MEDPORT_ROOT" -type d | sort
echo ""
echo "Users created:"
for user in "${!USER_GROUPS[@]}"; do
    echo "  $user (groups: $(id -Gn $user))"
done
echo ""
echo "Next steps:"
echo "  1. Design RBAC matrix in rbac_matrix_template.csv"
echo "  2. Implement permissions using chmod/chown/setfacl"
echo "  3. Run ./verify_permissions.sh to test"
echo "  4. Submit findings via findings_template.csv"