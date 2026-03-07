# Installation Guide

คู่มือการติดตั้ง Revenue Intelligence System แบบละเอียด

---

## 📋 สารบัญ

- [Quick Install (แนะนำ)](#-quick-install-แนะนำ)
- [ติดตั้งแบบใช้ Database ในตัว](#-ติดตั้งแบบใช้-database-ในตัว)
- [ติดตั้งแบบใช้ External Database](#-ติดตั้งแบบใช้-external-database)
  - [PostgreSQL](#postgresql)
  - [MySQL](#mysql)
- [ติดตั้งแบบ Download Only](#-ติดตั้งแบบ-download-only-ไม่ใช้-database)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Install (แนะนำ)

วิธีที่ง่ายที่สุด - ติดตั้งพร้อม PostgreSQL ในตัว:

```bash
curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash
```

ระบบจะ:
1. ตรวจสอบ Docker
2. สร้าง PostgreSQL container
3. ตั้งค่าระบบอัตโนมัติ
4. นำเข้าข้อมูลพื้นฐาน

---

## 📦 ติดตั้งแบบใช้ Database ในตัว

### PostgreSQL (Default)

```bash
curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash
```

### ระบุ Path ที่ต้องการ

```bash
curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash -s -- --dir /opt/revenue-intelligence
```

---

## 🔗 ติดตั้งแบบใช้ External Database

สำหรับโรงพยาบาลที่มี Database Server อยู่แล้ว

### PostgreSQL

#### 1. เตรียม Database

```sql
-- สร้าง database และ user
CREATE USER eclaim WITH PASSWORD 'your_secure_password';
CREATE DATABASE eclaim_db OWNER eclaim;
GRANT ALL PRIVILEGES ON DATABASE eclaim_db TO eclaim;
```

#### 2. ติดตั้งแบบ No-DB

```bash
curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash -s -- --no-db
```

#### 3. แก้ไข .env

```bash
nano .env
```

```env
# Database Configuration
DB_TYPE=postgresql
DB_HOST=your-db-server.hospital.local
DB_PORT=5432
DB_NAME=eclaim_db
DB_USER=eclaim
DB_PASSWORD=your_secure_password

# E-Claim Credentials
ECLAIM_USERNAME=your_nhso_username
ECLAIM_PASSWORD=your_nhso_password

# Security
SECRET_KEY=your-random-secret-key-min-32-chars
```

#### 4. Start Services

```bash
docker compose up -d
```

#### 5. Run Migrations & Seed Data

```bash
docker compose exec web python database/migrate.py --seed
docker compose exec web python database/seeds/health_offices_importer.py
docker compose exec web python database/seeds/nhso_error_codes_importer.py
```

---

### MySQL

#### 1. เตรียม Database

```sql
-- สร้าง database และ user
CREATE DATABASE eclaim_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'eclaim'@'%' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON eclaim_db.* TO 'eclaim'@'%';
FLUSH PRIVILEGES;
```

#### 2. ติดตั้งแบบ No-DB

```bash
curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash -s -- --no-db
```

#### 3. แก้ไข .env

```bash
nano .env
```

```env
# Database Configuration
DB_TYPE=mysql
DB_HOST=your-mysql-server.hospital.local
DB_PORT=3306
DB_NAME=eclaim_db
DB_USER=eclaim
DB_PASSWORD=your_secure_password

# E-Claim Credentials
ECLAIM_USERNAME=your_nhso_username
ECLAIM_PASSWORD=your_nhso_password

# Security
SECRET_KEY=your-random-secret-key-min-32-chars
```

#### 4. Start Services

```bash
docker compose up -d
```

#### 5. Run Migrations & Seed Data

```bash
docker compose exec web python database/migrate.py --seed
docker compose exec web python database/seeds/health_offices_importer.py
docker compose exec web python database/seeds/nhso_error_codes_importer.py
```

---

## 📥 ติดตั้งแบบ Download Only (ไม่ใช้ Database)

สำหรับใช้งานแค่ดาวน์โหลดไฟล์ REP, STM, SMT โดยไม่ต้องการ Analytics:

```bash
curl -fsSL https://raw.githubusercontent.com/aegisx-platform/revenue-intelligence-system/main/install.sh | bash -s -- --no-db
```

> ⚠️ โหมดนี้จะไม่มี Dashboard, Analytics, Reconciliation

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_TYPE` | ประเภท database (`postgresql` / `mysql`) | `postgresql` |
| `DB_HOST` | Database host | `db` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `eclaim_db` |
| `DB_USER` | Database user | `eclaim` |
| `DB_PASSWORD` | Database password | - |
| `ECLAIM_USERNAME` | NHSO username | - |
| `ECLAIM_PASSWORD` | NHSO password | - |
| `SECRET_KEY` | Flask secret key | - |
| `WEB_PORT` | Web UI port | `5001` |
| `TZ` | Timezone | `Asia/Bangkok` |

### Data Directories

| Directory | Description |
|-----------|-------------|
| `./downloads/` | ไฟล์ REP, STM, SMT ที่ดาวน์โหลด |
| `./logs/` | Log files |
| `./data/` | Settings และข้อมูลระบบ |
| `./user_data/` | License file + Settings (`license.lic`, `settings.json`) |

---

## 🔧 Troubleshooting

### ปัญหา: ไม่สามารถเชื่อมต่อ Database

```bash
# ตรวจสอบ connection
docker compose exec web python -c "from config.database import get_db; print(get_db())"

# ดู logs
docker compose logs web | grep -i database
```

### ปัญหา: Permission Denied

```bash
# แก้ไข ownership
sudo chown -R $USER:$USER ./downloads ./logs ./data ./user_data
```

### ปัญหา: Port 5001 ถูกใช้งานอยู่

```bash
# เปลี่ยน port ใน .env
WEB_PORT=5002

# Restart
docker compose down && docker compose up -d
```

### ปัญหา: Database Migration Failed

```bash
# Reset และ migrate ใหม่
docker compose exec web python database/migrate.py --reset
docker compose exec web python database/migrate.py --seed
```

---

## 📚 เอกสารเพิ่มเติม

- [Configuration Guide](CONFIGURATION.md)
- [API Documentation](API.md)
- [License Management](LICENSE.md)

---

## 🆘 Support

หากพบปัญหาในการติดตั้ง:

- 📧 Email: support@aegisxplatform.com
- 🌐 Website: https://aegisxplatform.com
- 📖 Docs: https://docs.aegisxplatform.com
