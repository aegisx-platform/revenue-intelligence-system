#!/bin/bash
#
# NHSO Revenue Intelligence - Quick Install Script
# Version: 3.2.0
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash
#
# Options:
#   --mysql    Use MySQL instead of PostgreSQL
#   --no-db    Download-only mode (no database)
#   --dir      Installation directory (default: nhso-revenue)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
VERSION="latest"
INSTALL_DIR="nhso-revenue"
DB_TYPE="postgresql"
GITHUB_RAW="https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main"
AUTO_YES=false
ECLAIM_USER=""
ECLAIM_PASS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mysql)    DB_TYPE="mysql"; shift ;;
        --no-db)    DB_TYPE="none"; shift ;;
        --dir)      INSTALL_DIR="$2"; shift 2 ;;
        --version)  VERSION="$2"; shift 2 ;;
        -y|--yes)   AUTO_YES=true; shift ;;
        --username) ECLAIM_USER="$2"; shift 2 ;;
        --password) ECLAIM_PASS="$2"; shift 2 ;;
        -h|--help)
            echo "NHSO Revenue Intelligence Installer"
            echo ""
            echo "Usage: curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash -s -- [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --mysql      Use MySQL instead of PostgreSQL"
            echo "  --no-db      Download-only mode (no database)"
            echo "  --dir NAME   Installation directory (default: nhso-revenue)"
            echo "  --version V  Docker image version (default: latest)"
            echo "  -y, --yes    Skip confirmation prompt (for automation)"
            echo "  --username U E-Claim username (for automation)"
            echo "  --password P E-Claim password (for automation)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Calculate full path
if [[ "$INSTALL_DIR" = /* ]]; then
    FULL_PATH="$INSTALL_DIR"
else
    FULL_PATH="$(pwd)/$INSTALL_DIR"
fi

# Database display name
case $DB_TYPE in
    postgresql) DB_DISPLAY="PostgreSQL" ;;
    mysql)      DB_DISPLAY="MySQL" ;;
    none)       DB_DISPLAY="ไม่ใช้ (Download only)" ;;
esac

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        NHSO Revenue Intelligence - Quick Install          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Show installation summary FIRST
echo -e "${YELLOW}การติดตั้ง:${NC}"
echo -e "  📁 โฟลเดอร์: ${BLUE}${FULL_PATH}${NC}"
echo -e "  🗄️  Database: ${BLUE}${DB_DISPLAY}${NC}"
echo -e "  🐳 Version:  ${BLUE}${VERSION}${NC}"
echo ""

# Check if directory exists
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Warning: โฟลเดอร์ '${INSTALL_DIR}' มีอยู่แล้ว จะถูก overwrite${NC}"
    echo ""
fi

# Ask for confirmation BEFORE doing anything
if [ "$AUTO_YES" = true ]; then
    echo -e "${GREEN}✓ Auto-confirm enabled (--yes)${NC}"
else
    read -p "ยืนยันการติดตั้ง? (Y/n): " -n 1 -r REPLY </dev/tty
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && echo "Cancelled" && exit 1
fi

echo ""

# NOW start the actual installation
echo -e "${YELLOW}[1/7] Checking requirements...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

# Check Docker daemon
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Docker daemon${NC}"
    echo "Please start Docker or add user to docker group:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  (then log out and log back in)"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon running${NC}"

# Create directory with permission check
echo -e "${YELLOW}[2/7] Creating installation directory...${NC}"

# Try to create directory - if it fails, show solutions
if mkdir -p "$INSTALL_DIR" 2>/dev/null && cd "$INSTALL_DIR" 2>/dev/null; then
    # Success - directory created
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        echo -e "${GREEN}✓ Created: $(pwd) ${YELLOW}(using sudo)${NC}"
        echo -e "${YELLOW}⚠️  After installation, run:${NC}"
        echo -e "   ${BLUE}sudo chown -R \$SUDO_USER:\$SUDO_USER $FULL_PATH${NC}"
        echo -e "   ${BLUE}sudo usermod -aG docker \$SUDO_USER${NC}"
        echo -e "   ${BLUE}# Then logout and login${NC}"
    else
        echo -e "${GREEN}✓ Created: $(pwd)${NC}"
    fi
else
    # Failed - show solutions
    echo -e "${RED}Error: Permission denied to create directory '$INSTALL_DIR'${NC}"
    echo ""
    echo -e "${YELLOW}กรณีไม่มี Permission → เลือก 1 ใน 3 วิธี:${NC}"
    echo ""
    echo -e "${BLUE}1. Install ที่ Home Directory (แนะนำที่สุด):${NC}"
    echo "   cd ~"
    echo "   curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash"
    echo ""
    echo -e "${BLUE}2. ใช้ sudo (3 ขั้นตอน):${NC}"
    echo "   # ขั้นตอนที่ 1: Download"
    echo "   cd ~ && curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh -o install.sh"
    echo ""
    echo "   # ขั้นตอนที่ 2: Run sudo"
    echo "   sudo bash install.sh --dir $FULL_PATH"
    echo ""
    echo "   # ขั้นตอนที่ 3: Fix Permission (สำคัญมาก!)"
    echo "   sudo chown -R \$USER:\$USER $FULL_PATH"
    echo "   sudo usermod -aG docker \$USER"
    echo "   exit  # ออกแล้ว SSH เข้ามาใหม่"
    echo ""
    echo -e "${BLUE}3. Manual Setup:${NC}"
    echo "   sudo mkdir -p $FULL_PATH && cd $FULL_PATH"
    echo "   sudo curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/docker-compose-deploy.yml -o docker-compose.yml"
    echo "   sudo mkdir -p downloads/{rep,stm,smt} logs config"
    echo "   sudo chown -R \$USER:\$USER ."
    echo "   # สร้าง .env แล้ว: docker compose pull && docker compose up -d"
    echo ""
    echo -e "${YELLOW}📚 คู่มือเต็ม:${NC}"
    echo "   https://github.com/aegisx-platform/revenue-intelligence-system/blob/main/docs/PRODUCTION_DEPLOYMENT.md#permission-issues"
    echo ""
    exit 1
fi

# Download docker-compose
echo -e "${YELLOW}[3/7] Downloading configuration...${NC}"

case $DB_TYPE in
    postgresql) COMPOSE_FILE="docker-compose-deploy.yml" ;;
    mysql)      COMPOSE_FILE="docker-compose-deploy-mysql.yml" ;;
    none)       COMPOSE_FILE="docker-compose-deploy-no-db.yml" ;;
esac

curl -fsSL "${GITHUB_RAW}/${COMPOSE_FILE}" -o docker-compose.yml
echo -e "${GREEN}✓ Downloaded docker-compose.yml (${DB_TYPE})${NC}"

# Create directories
mkdir -p downloads/{rep,stm,smt} logs data user_data
echo -e "${GREEN}✓ Created directories${NC}"

# Create user_data files (for Docker volume mounts)
touch user_data/license.lic
[ ! -f user_data/settings.json ] && echo '{}' > user_data/settings.json
echo -e "${GREEN}✓ Created user_data files${NC}"

# Create .env
echo -e "${YELLOW}[4/7] Configuring credentials...${NC}"

if [ -z "$ECLAIM_USER" ] || [ -z "$ECLAIM_PASS" ]; then
    echo ""
    echo -e "${BLUE}กรุณาใส่ข้อมูลเข้าสู่ระบบ E-Claim:${NC}"
    echo ""
    read -p "ECLAIM_USERNAME: " ECLAIM_USER </dev/tty
    read -s -p "ECLAIM_PASSWORD: " ECLAIM_PASS </dev/tty
    echo ""
else
    echo -e "${GREEN}✓ Using provided credentials${NC}"
fi

cat > .env << EOF
# NHSO Revenue Intelligence
# Generated by install.sh

# E-Claim Credentials
ECLAIM_USERNAME=${ECLAIM_USER}
ECLAIM_PASSWORD=${ECLAIM_PASS}

# Docker Image Version
VERSION=${VERSION}

# Web Port (change if 5001 is in use)
WEB_PORT=5001
EOF

# Add external database settings template if --no-db mode
if [ "$DB_TYPE" = "none" ]; then
    cat >> .env << 'EOF'

# External Database Connection (กรุณาแก้ไขค่าด้านล่าง)
# DB_TYPE: postgresql หรือ mysql
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=eclaim_db
DB_USER=eclaim
DB_PASSWORD=your_password
EOF
fi

echo -e "${GREEN}✓ Created .env${NC}"

# Start services
echo -e "${YELLOW}[5/7] Pulling Docker images...${NC}"
echo ""

if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

$DOCKER_COMPOSE pull
$DOCKER_COMPOSE up -d

# Wait for database initialization (skip if --no-db mode)
if [ "$DB_TYPE" != "none" ]; then
    echo ""
    echo -e "${YELLOW}[6/7] Waiting for database initialization...${NC}"
    echo -e "${BLUE}   Checking migrations...${NC}"

    # Wait for migrations to complete (max 60 seconds)
    for i in {1..60}; do
        if $DOCKER_COMPOSE logs web 2>/dev/null | grep -q "Starting Flask application"; then
            echo -e "${GREEN}✓ Database initialized${NC}"
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""

    # Run seed data
    echo -e "${YELLOW}[7/7] Importing seed data...${NC}"
    echo -e "${BLUE}   This may take 30-60 seconds...${NC}"
    echo ""

    # Seed dimension tables
    echo -e "   • Seeding dimension tables..."
    $DOCKER_COMPOSE exec -T web python database/migrate.py --seed 2>&1 | grep -E "Seeded|✓" || true

    # Seed health offices
    echo -e "   • Seeding health offices (9,000+ records)..."
    $DOCKER_COMPOSE exec -T web python database/seeds/health_offices_importer.py 2>&1 | grep -E "Imported|✓" || true

    # Seed error codes
    echo -e "   • Seeding NHSO error codes..."
    $DOCKER_COMPOSE exec -T web python database/seeds/nhso_error_codes_importer.py 2>&1 | grep -E "Imported|✓" || true

    echo ""
    echo -e "${GREEN}✓ Seed data imported${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation Complete!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show admin credentials
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🔐 Admin Login Credentials${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
ADMIN_USER=$($DOCKER_COMPOSE exec -T web cat .admin-credentials 2>/dev/null | grep "^Username:" | head -1)
ADMIN_PASS=$($DOCKER_COMPOSE exec -T web cat .admin-credentials 2>/dev/null | grep "^Password:" | head -1)
if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ]; then
    echo "$ADMIN_USER"
    echo "$ADMIN_PASS"
    echo ""
    echo -e "${RED}⚠️  บันทึกข้อมูลนี้ไว้! จะไม่แสดงอีก${NC}"
    echo -e "${YELLOW}   แนะนำ: เปลี่ยนรหัสผ่านหลัง login ครั้งแรก${NC}"
else
    echo -e "ดู credentials: ${BLUE}docker compose exec web cat .admin-credentials${NC}"
fi
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""

# Show sudo warning if running as root
if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  คุณใช้ sudo ติดตั้ง - ต้องทำขั้นตอนนี้ก่อนใช้งาน:${NC}"
    echo ""
    REAL_USER="${SUDO_USER:-$USER}"
    echo -e "${BLUE}# 1. Fix file ownership${NC}"
    echo -e "   sudo chown -R $REAL_USER:$REAL_USER $FULL_PATH"
    echo ""
    echo -e "${BLUE}# 2. Add user to docker group${NC}"
    echo -e "   sudo usermod -aG docker $REAL_USER"
    echo ""
    echo -e "${BLUE}# 3. Logout and login again (สำคัญ!)${NC}"
    echo -e "   exit"
    echo -e "   # แล้ว SSH เข้ามาใหม่"
    echo ""
    echo -e "${BLUE}# 4. Verify${NC}"
    echo -e "   cd $FULL_PATH"
    echo -e "   docker compose ps  # ต้องรันได้โดยไม่ต้อง sudo"
    echo ""
    echo -e "${RED}❗ ถ้าไม่ทำขั้นตอนข้างบน จะใช้งานไม่ได้${NC}"
    echo ""
fi

echo -e "🌐 เข้าใช้งาน: ${BLUE}http://localhost:5001${NC}"
echo ""

# Show next steps (only if using database)
if [ "$DB_TYPE" != "none" ]; then
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  ${GREEN}1.${NC} ตั้งค่ารหัสโรงพยาบาล (Hospital Code):"
    echo -e "     ${BLUE}http://localhost:5001/setup${NC}"
    echo -e "     • จำเป็นสำหรับ SMT Budget และ Per-Bed KPIs"
    echo ""
    echo -e "  ${GREEN}2.${NC} ตั้งค่า NHSO Credentials (ถ้าต้องการดาวน์โหลดไฟล์):"
    echo -e "     ${BLUE}http://localhost:5001/data-management?tab=settings${NC}"
    echo ""
fi

echo -e "Commands:"
echo -e "  ${YELLOW}cd $(pwd)${NC}"
echo -e "  ${YELLOW}docker compose logs -f web${NC}    # ดู logs"
echo -e "  ${YELLOW}docker compose down${NC}           # หยุด"
echo -e "  ${YELLOW}docker compose up -d${NC}          # เริ่ม"
echo ""
echo -e "📚 Docs: ${BLUE}https://github.com/aegisx-platform/revenue-intelligence-system${NC}"
echo ""

# Show warning if --no-db mode
if [ "$DB_TYPE" = "none" ]; then
    echo -e "${YELLOW}⚠️  กรุณาแก้ไขการเชื่อมต่อ Database ใน .env ก่อนใช้งาน:${NC}"
    echo -e "  ${YELLOW}vi $(pwd)/.env${NC}"
    echo -e "  แก้ไข DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD"
    echo -e "  แล้ว restart: ${YELLOW}docker compose restart${NC}"
    echo ""
fi
