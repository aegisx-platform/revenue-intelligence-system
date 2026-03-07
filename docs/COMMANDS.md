# Command Reference

รวม Commands ที่ใช้บ่อยสำหรับ Revenue Intelligence System

---

## 📋 Quick Reference

```bash
# ดู logs
docker compose logs -f web

# Restart
docker compose restart web

# Stop
docker compose down

# Start
docker compose up -d

# Update
docker compose pull && docker compose up -d
```

---

## 🔑 User & Password

### Reset Admin Password

```bash
docker compose exec web python scripts/create_user.py \
  --username admin \
  --password "NewPassword123!" \
  --update
```

### สร้าง User ใหม่

```bash
# สร้าง user ธรรมดา
docker compose exec web python scripts/create_user.py \
  --username newuser \
  --password "Password123!" \
  --name "ชื่อผู้ใช้" \
  --role user

# สร้าง admin
docker compose exec web python scripts/create_user.py \
  --username newadmin \
  --password "AdminPass123!" \
  --name "Admin Name" \
  --role admin
```

### Reset Password ของ User

```bash
docker compose exec web python scripts/create_user.py \
  --username targetuser \
  --password "NewPassword123!" \
  --update
```

### ดูรายชื่อ Users

```bash
docker compose exec web python -c "
from utils.auth import get_all_users
for u in get_all_users():
    print(f'{u.username} ({u.role})')
"
```

---

## 🗄️ Database

### Run Migrations

```bash
docker compose exec web python database/migrate.py
```

### Seed Data (ข้อมูลพื้นฐาน)

```bash
# ทั้งหมด
docker compose exec web python database/migrate.py --seed
docker compose exec web python database/seeds/health_offices_importer.py
docker compose exec web python database/seeds/nhso_error_codes_importer.py

# หรือใช้ make (ถ้ามี)
make seed-all
```

### Reset Database

```bash
# ลบและสร้างใหม่
docker compose exec web python database/migrate.py --reset
docker compose exec web python database/migrate.py --seed
```

### Backup Database

```bash
# PostgreSQL
docker compose exec db pg_dump -U eclaim eclaim_db > backup.sql

# MySQL
docker compose exec db mysqldump -u eclaim -p eclaim_db > backup.sql
```

### Restore Database

```bash
# PostgreSQL
docker compose exec -T db psql -U eclaim eclaim_db < backup.sql

# MySQL
docker compose exec -T db mysql -u eclaim -p eclaim_db < backup.sql
```

---

## 📥 Downloads

### ดาวน์โหลด Manual

```bash
# Download REP
docker compose exec web python -c "
from utils.eclaim.downloader import download_rep
download_rep('2026', '01')
"

# Download STM
docker compose exec web python -c "
from utils.eclaim.downloader import download_stm
download_stm('2026', '01')
"
```

### ลบไฟล์ Downloads

```bash
# ลบทั้งหมด
rm -rf ./downloads/rep/* ./downloads/stm/* ./downloads/smt/*

# ลบเฉพาะ REP
rm -rf ./downloads/rep/*

# ลบเฉพาะ STM
rm -rf ./downloads/stm/*

# ลบเฉพาะ SMT
rm -rf ./downloads/smt/*
```

---

## ⚙️ System

### ดู Logs

```bash
# ดู logs แบบ follow
docker compose logs -f web

# ดู logs 100 บรรทัดล่าสุด
docker compose logs --tail 100 web

# ดู logs ของ database
docker compose logs -f db

# ดู logs ทั้งหมด
docker compose logs -f
```

### Restart Services

```bash
# Restart เฉพาะ web
docker compose restart web

# Restart ทั้งหมด
docker compose restart

# Stop แล้ว Start ใหม่
docker compose down && docker compose up -d
```

### Update to Latest Version

```bash
# Pull image ใหม่
docker compose pull

# Restart ด้วย image ใหม่
docker compose up -d

# ดู version
docker compose exec web python -c "print(open('VERSION').read())"
```

### ดู Status

```bash
# ดู containers
docker compose ps

# ดู resource usage
docker stats

# ดู disk usage
docker system df
```

---

## 🔄 Reset Commands

### Reset Settings

```bash
rm ./user_data/settings.json
docker compose restart web
```

### Reset License

```bash
rm ./user_data/license.lic
docker compose restart web
```

### Reset Logs

```bash
rm -rf ./logs/*
docker compose restart web
```

### Reset ทั้งหมด (Fresh Install)

```bash
# Stop
docker compose down -v

# ลบ data
rm -rf ./downloads/* ./logs/* ./data/* ./user_data/*

# Start ใหม่
docker compose up -d

# Seed data
docker compose exec web python database/migrate.py --seed
docker compose exec web python database/seeds/health_offices_importer.py
docker compose exec web python database/seeds/nhso_error_codes_importer.py
```

---

## 🔧 Troubleshooting

### ตรวจสอบ Database Connection

```bash
docker compose exec web python -c "
from config.database import get_db
db = get_db()
print('Connected!' if db else 'Failed!')
"
```

### ตรวจสอบ E-Claim Connection

```bash
docker compose exec web python -c "
from utils.eclaim.auth import test_connection
result = test_connection()
print('OK' if result else 'Failed')
"
```

### ตรวจสอบ License

```bash
docker compose exec web python -c "
from utils.license_checker import LicenseChecker
lc = LicenseChecker()
print(lc.get_license_info())
"
```

### เข้า Shell ใน Container

```bash
# Bash shell
docker compose exec web bash

# Python shell
docker compose exec web python
```

### ดู Environment Variables

```bash
docker compose exec web env | grep -E "DB_|ECLAIM_|SECRET"
```

---

## 📝 One-Liner Commands

```bash
# Reset admin password เป็น "admin123"
docker compose exec web python scripts/create_user.py -u admin -p admin123 --update

# Restart และดู logs
docker compose restart web && docker compose logs -f web

# Backup database + files
pg_dump && tar -czvf backup.tar.gz ./downloads ./data ./user_data

# Check health
docker compose ps && docker compose logs --tail 5 web
```

---

## 📚 Related Docs

- [Installation Guide](INSTALLATION.md)
- [Configuration Guide](CONFIGURATION.md)
- [User Management](USER_MANAGEMENT.md)
