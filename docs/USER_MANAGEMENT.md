# User Management

คู่มือการจัดการผู้ใช้งานและการ Reset ต่างๆ

---

## 📋 สารบัญ

- [Default Admin Account](#-default-admin-account)
- [สร้าง User ใหม่](#-สร้าง-user-ใหม่)
- [Reset Password](#-reset-password)
- [จัดการ Users](#-จัดการ-users)
- [Reset ระบบ](#-reset-ระบบ)
- [Backup & Restore](#-backup--restore)

---

## 👤 Default Admin Account

หลังติดตั้งครั้งแรก ระบบจะสร้าง Admin account อัตโนมัติ:

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `admin` |
| Role | Administrator |

> ⚠️ **สำคัญ:** เปลี่ยนรหัสผ่าน admin ทันทีหลังติดตั้ง!

---

## ➕ สร้าง User ใหม่

### วิธีที่ 1: ผ่าน Web UI (Admin Only)

1. Login ด้วย Admin account
2. ไปที่ **Settings > Users**
3. กด **Add User**
4. กรอกข้อมูล:
   - Username
   - Password
   - Display Name
   - Role (Admin / User / Viewer)
5. กด **Create**

### วิธีที่ 2: ผ่าน Command Line

```bash
# สร้าง user ใหม่
docker compose exec web python scripts/create_user.py \
  --username newuser \
  --password "SecurePass123!" \
  --name "New User" \
  --role user

# สร้าง admin user
docker compose exec web python scripts/create_user.py \
  --username newadmin \
  --password "AdminPass123!" \
  --name "New Admin" \
  --role admin
```

### User Roles

| Role | Permissions |
|------|-------------|
| **Admin** | Full access - จัดการ users, settings, license |
| **User** | View & Download - ดู dashboard, download files |
| **Viewer** | View only - ดู dashboard อย่างเดียว |

---

## 🔑 Reset Password

### Reset ผ่าน Web UI (Admin Only)

1. Login ด้วย Admin account
2. ไปที่ **Settings > Users**
3. เลือก user ที่ต้องการ
4. กด **Reset Password**
5. กรอกรหัสผ่านใหม่
6. กด **Save**

### Reset ผ่าน Command Line

```bash
# Reset password ของ user
docker compose exec web python scripts/create_user.py \
  --username targetuser \
  --password "NewPassword123!" \
  --update

# Reset password ของ admin
docker compose exec web python scripts/create_user.py \
  --username admin \
  --password "NewAdminPass123!" \
  --update
```

### Reset Admin Password (ลืมรหัสผ่าน Admin)

ถ้าลืมรหัสผ่าน Admin และไม่สามารถ login ได้:

```bash
# วิธีที่ 1: Reset ผ่าน script
docker compose exec web python scripts/create_user.py \
  --username admin \
  --password "NewAdminPass123!" \
  --update

# วิธีที่ 2: สร้าง admin ใหม่
docker compose exec web python scripts/create_user.py \
  --username admin2 \
  --password "TempPass123!" \
  --role admin
```

---

## 👥 จัดการ Users

### ดูรายชื่อ Users

**ผ่าน Web UI:**
1. ไปที่ **Settings > Users**

**ผ่าน Command Line:**
```bash
docker compose exec web python -c "
from utils.auth import get_all_users
for user in get_all_users():
    print(f'{user.username} - {user.role}')
"
```

### ลบ User

**ผ่าน Web UI:**
1. ไปที่ **Settings > Users**
2. เลือก user
3. กด **Delete**
4. ยืนยันการลบ

**ผ่าน Command Line:**
```bash
docker compose exec web python -c "
from utils.auth import delete_user
delete_user('username_to_delete')
print('User deleted')
"
```

### เปลี่ยน Role

**ผ่าน Web UI:**
1. ไปที่ **Settings > Users**
2. เลือก user
3. เปลี่ยน Role
4. กด **Save**

---

## 🔄 Reset ระบบ

### Reset Settings (เฉพาะ Settings)

```bash
# ลบ settings file
rm ./user_data/settings.json

# Restart
docker compose restart web
```

### Reset Database (ลบข้อมูลทั้งหมด)

> ⚠️ **คำเตือน:** จะลบข้อมูลทั้งหมด!

```bash
# Stop services
docker compose down

# ลบ database volume
docker volume rm $(docker volume ls -q | grep db_data)

# Start ใหม่ (จะสร้าง database ใหม่)
docker compose up -d

# Run migrations และ seed data
docker compose exec web python database/migrate.py --seed
docker compose exec web python database/seeds/health_offices_importer.py
docker compose exec web python database/seeds/nhso_error_codes_importer.py
```

### Reset Downloads (ลบไฟล์ที่ download)

```bash
# ลบไฟล์ทั้งหมด
rm -rf ./downloads/rep/* ./downloads/stm/* ./downloads/smt/*

# หรือลบเฉพาะบางประเภท
rm -rf ./downloads/rep/*  # ลบเฉพาะ REP
```

### Reset ทั้งหมด (Fresh Install)

```bash
# Stop และลบ containers
docker compose down -v

# ลบ data ทั้งหมด
rm -rf ./downloads/* ./logs/* ./data/* ./user_data/*

# ติดตั้งใหม่
docker compose up -d

# Run migrations และ seed
docker compose exec web python database/migrate.py --seed
docker compose exec web python database/seeds/health_offices_importer.py
docker compose exec web python database/seeds/nhso_error_codes_importer.py
```

---

## 💾 Backup & Restore

### Backup Database

**PostgreSQL:**
```bash
# Backup
docker compose exec db pg_dump -U eclaim eclaim_db > backup_$(date +%Y%m%d).sql

# Backup with compression
docker compose exec db pg_dump -U eclaim eclaim_db | gzip > backup_$(date +%Y%m%d).sql.gz
```

**MySQL:**
```bash
# Backup
docker compose exec db mysqldump -u eclaim -p eclaim_db > backup_$(date +%Y%m%d).sql
```

### Backup Files

```bash
# Backup ทุกอย่าง
tar -czvf backup_$(date +%Y%m%d).tar.gz ./downloads ./data ./user_data ./logs

# Backup เฉพาะ config และ license
tar -czvf backup_userdata_$(date +%Y%m%d).tar.gz ./user_data
```

### Restore Database

**PostgreSQL:**
```bash
# Restore
docker compose exec -T db psql -U eclaim eclaim_db < backup_20260201.sql

# Restore from gzip
gunzip -c backup_20260201.sql.gz | docker compose exec -T db psql -U eclaim eclaim_db
```

**MySQL:**
```bash
# Restore
docker compose exec -T db mysql -u eclaim -p eclaim_db < backup_20260201.sql
```

### Restore Files

```bash
# Restore
tar -xzvf backup_20260201.tar.gz

# Restart
docker compose restart web
```

---

## 🔒 Security Best Practices

1. **เปลี่ยน default password** ทันทีหลังติดตั้ง
2. **ใช้ strong password** (อย่างน้อย 12 ตัวอักษร, ผสมตัวเลข/อักขระพิเศษ)
3. **จำกัด Admin accounts** - มีเท่าที่จำเป็น
4. **Backup สม่ำเสมอ** - อย่างน้อยสัปดาห์ละครั้ง
5. **ตรวจสอบ logs** - ดู login failures

---

## 📚 Related Docs

- [Installation Guide](INSTALLATION.md)
- [Configuration Guide](CONFIGURATION.md)
- [Troubleshooting](TROUBLESHOOTING.md)
