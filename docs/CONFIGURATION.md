# Configuration Guide

คู่มือการตั้งค่า Revenue Intelligence System

---

## 📋 สารบัญ

- [Initial Setup](#-initial-setup)
- [Hospital Configuration](#-hospital-configuration)
- [E-Claim Credentials](#-e-claim-credentials)
- [Database Configuration](#-database-configuration)
- [License Setup](#-license-setup)
- [Scheduler Configuration](#-scheduler-configuration)
- [Advanced Settings](#-advanced-settings)

---

## 🏁 Initial Setup

### ขั้นตอนแรกหลังติดตั้ง

1. **เปิด Setup Page**
   ```
   http://localhost:5001/setup
   ```

2. **กรอกรหัสโรงพยาบาล 5 หลัก**
   - เช่น `10670` สำหรับ รพ.ขอนแก่น
   - ระบบจะดึงข้อมูลโรงพยาบาลอัตโนมัติ

3. **ยืนยันข้อมูล**
   - ชื่อโรงพยาบาล
   - จังหวัด
   - เขตสุขภาพ

4. **เริ่มใช้งาน**
   - Dashboard: `http://localhost:5001/dashboard`
   - Data Management: `http://localhost:5001/data-management`

---

## 🏥 Hospital Configuration

### เปลี่ยนรหัสโรงพยาบาล

1. ไปที่ **Settings > Hospital Info**
2. กรอกรหัสโรงพยาบาลใหม่
3. กด **Save**

### ตั้งค่าจำนวนเตียง (สำหรับ Per-Bed Analytics)

1. ไปที่ **Settings > Hospital Info**
2. กรอกจำนวนเตียง
3. กด **Save**

> 💡 จำนวนเตียงใช้คำนวณ Per-Bed Performance ใน Dashboard

---

## 🔐 E-Claim Credentials

### ตั้งค่า Username/Password

**วิธีที่ 1: ผ่าน Web UI**

1. ไปที่ **Settings > Credentials**
2. กรอก NHSO Username
3. กรอก NHSO Password
4. กด **Save & Test**

**วิธีที่ 2: ผ่าน .env file**

```bash
nano .env
```

```env
ECLAIM_USERNAME=your_nhso_username
ECLAIM_PASSWORD=your_nhso_password
```

```bash
docker compose restart web
```

### ทดสอบ Credentials

1. ไปที่ **Settings > Credentials**
2. กด **Test Connection**
3. ถ้าสำเร็จจะแสดง ✅

---

## 🗄️ Database Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_TYPE` | `postgresql` หรือ `mysql` | `postgresql` |
| `DB_HOST` | Database server hostname | `db` |
| `DB_PORT` | Database port | `5432` / `3306` |
| `DB_NAME` | Database name | `eclaim_db` |
| `DB_USER` | Database username | `eclaim` |
| `DB_PASSWORD` | Database password | - |

### เปลี่ยน Database

1. แก้ไข `.env`:
   ```env
   DB_TYPE=mysql
   DB_HOST=mysql-server.hospital.local
   DB_PORT=3306
   DB_NAME=eclaim_db
   DB_USER=eclaim
   DB_PASSWORD=new_password
   ```

2. Restart:
   ```bash
   docker compose down
   docker compose up -d
   ```

3. Run Migrations:
   ```bash
   docker compose exec web python database/migrate.py
   ```

---

## 🔑 License Setup

### ติดตั้ง License

**วิธีที่ 1: ผ่าน Web UI**

1. ไปที่ **Settings > License**
2. กด **Upload License File**
3. เลือกไฟล์ `.lic` ที่ได้รับ
4. กด **Install License**

**วิธีที่ 2: Copy ไฟล์โดยตรง**

```bash
cp /path/to/your/license.lic ./config/license.lic
docker compose restart web
```

### ตรวจสอบ License

1. ไปที่ **Settings > License**
2. ดูสถานะ:
   - ✅ Active - ใช้งานได้
   - ⚠️ Expiring Soon - ใกล้หมดอายุ
   - ❌ Expired - หมดอายุแล้ว

### Verify License Online

1. ไปที่ **Settings > License**
2. กด **Verify on Portal**
3. ระบบจะเปิดหน้า License Portal

---

## ⏰ Scheduler Configuration

### ตั้งเวลาดาวน์โหลดอัตโนมัติ

1. ไปที่ **Data Management > Settings**
2. เปิด **Auto Download**
3. ตั้งเวลา:
   - REP: แนะนำ 06:00 (หลัง NHSO update)
   - STM: แนะนำ 07:00
   - SMT: แนะนำ 08:00

### Schedule Options

| Type | Frequency | Recommended Time |
|------|-----------|------------------|
| REP | Daily | 06:00 |
| STM | Daily | 07:00 |
| SMT Budget | Weekly (Mon) | 08:00 |

---

## ⚙️ Advanced Settings

### เปลี่ยน Port

```bash
# แก้ไข .env
WEB_PORT=8080

# Restart
docker compose down && docker compose up -d
```

### เปลี่ยน Timezone

```bash
# แก้ไข .env
TZ=Asia/Bangkok

# Restart
docker compose restart web
```

### Enable Debug Mode

```bash
# แก้ไข .env
FLASK_ENV=development
LOG_LEVEL=DEBUG

# Restart
docker compose restart web
```

### Resource Limits

```yaml
# docker-compose.yml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

---

## 📁 Configuration Files

| File | Description |
|------|-------------|
| `.env` | Environment variables |
| `./config/license.lic` | License file |
| `./data/settings.json` | Application settings |

---

## 🔄 Apply Changes

หลังแก้ไข configuration:

```bash
# Restart เฉพาะ web
docker compose restart web

# หรือ Restart ทั้งหมด
docker compose down && docker compose up -d
```

---

## 📚 Related Docs

- [Installation Guide](INSTALLATION.md)
- [User Management](USER_MANAGEMENT.md)
- [API Documentation](API.md)
