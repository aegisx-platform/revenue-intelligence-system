# Volume Mounts & Data Storage

คู่มือการจัดการ Volume Mounts และ Data Storage

---

## สารบัญ

- [Overview](#-overview)
- [Volume Mounts ทั้งหมด](#-volume-mounts-ทั้งหมด)
- [รายละเอียดแต่ละ Directory](#-รายละเอียดแต่ละ-directory)
- [Docker Compose Configuration](#-docker-compose-configuration)
- [Permissions](#-permissions)
- [Backup & Restore](#-backup--restore)
- [Custom Mounts](#-custom-mounts)
- [Troubleshooting](#-troubleshooting)

---

## Overview

Revenue Intelligence System ใช้ Volume Mounts เพื่อเก็บข้อมูลนอก Container:

```
./
├── downloads/          # ไฟล์ที่ดาวน์โหลด
│   ├── rep/           # REP files
│   ├── stm/           # STM files
│   └── smt/           # SMT files
├── logs/              # Log files
├── data/              # Application data
└── user_data/         # License & Settings
    ├── license.lic
    └── settings.json
```

**ทำไมต้อง Mount?**
- ข้อมูลไม่หายเมื่อ restart/update container
- สามารถ backup ได้ง่าย
- แชร์ข้อมูลระหว่าง containers ได้

---

## Volume Mounts ทั้งหมด

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `./downloads/` | `/app/downloads` | ไฟล์ REP, STM, SMT ที่ดาวน์โหลด |
| `./logs/` | `/app/logs` | Application logs |
| `./data/` | `/app/data` | Cache, temp files |
| `./user_data/` | `/app/user_data` | **License file** + Settings |
| `db_data` (volume) | `/var/lib/postgresql/data` | PostgreSQL data |

---

## รายละเอียดแต่ละ Directory

### downloads/

เก็บไฟล์ที่ดาวน์โหลดจาก NHSO:

```
downloads/
├── rep/                    # REP (Revenue) files
│   ├── 2026/
│   │   ├── 01/
│   │   │   ├── REP_10670_202601_001.zip
│   │   │   ├── REP_10670_202601_002.zip
│   │   │   └── ...
│   │   └── 02/
│   └── ...
├── stm/                    # STM (Statement) files
│   ├── 2026/
│   │   ├── 01/
│   │   │   └── STM_10670_202601.zip
│   │   └── ...
│   └── ...
└── smt/                    # SMT Budget files
    └── SMT_Budget_202601.xlsx
```

**ขนาดโดยประมาณ:**
- REP: ~50-200 MB/เดือน (ขึ้นกับจำนวนรายการ)
- STM: ~10-50 MB/เดือน
- SMT: ~1-5 MB/เดือน

**การจัดการ:**
```bash
# ดูขนาด
du -sh ./downloads/*

# ลบไฟล์เก่ากว่า 1 ปี
find ./downloads -type f -mtime +365 -delete

# ลบเฉพาะ REP เก่ากว่า 6 เดือน
find ./downloads/rep -type f -mtime +180 -delete
```

---

### logs/

เก็บ Application logs:

```
logs/
├── app.log                 # Main application log
├── app.log.1               # Rotated logs
├── app.log.2
├── download.log            # Download activity
├── scheduler.log           # Scheduler activity
└── error.log               # Errors only
```

**Log Rotation:**
- ขนาดสูงสุด: 10 MB/file
- เก็บไว้: 5 files

**การจัดการ:**
```bash
# ดู logs ล่าสุด
tail -f ./logs/app.log

# ดู errors
grep -i error ./logs/app.log

# ล้าง logs ทั้งหมด
rm -rf ./logs/*
docker compose restart web
```

---

### data/

เก็บ Application data:

```
data/
├── cache/                  # Temporary cache
│   ├── analytics/
│   └── reports/
└── temp/                   # Temporary files
```

**การจัดการ:**
```bash
# ล้าง cache
rm -rf ./data/cache/*
```

---

### user_data/

เก็บ License และ Settings ของผู้ใช้:

```
user_data/
├── license.lic             # License file (สำคัญมาก!)
└── settings.json           # User settings (credentials, scheduler)
```

**สำคัญ: license.lic**
- ไฟล์นี้คือ License ของระบบ
- **ห้ามลบ!** ถ้าลบต้องติดตั้ง license ใหม่
- Backup ไว้เสมอ

**สำคัญ: settings.json**
- เก็บ NHSO credentials, scheduler config
- ถ้าลบ ต้องตั้งค่าใหม่ผ่าน Web UI

**การจัดการ:**
```bash
# Backup license
cp ./user_data/license.lic ~/backup/license.lic.bak

# ติดตั้ง license ใหม่
cp /path/to/new/license.lic ./user_data/license.lic
docker compose restart web

# Backup settings
cp ./user_data/settings.json ~/backup/settings.json.bak
```

> หมายเหตุ: หากอัพเกรดจากเวอร์ชันเก่าที่ใช้ `config/` directory, ระบบจะย้ายไฟล์ไป `user_data/` ให้อัตโนมัติตอน container start

---

## Docker Compose Configuration

### Default Configuration

```yaml
# docker-compose.yml
services:
  web:
    image: ghcr.io/aegisx-platform/revenue-intelligence-system:latest
    environment:
      USER_DATA_DIR: /app/user_data
    volumes:
      # Downloads - ไฟล์ REP, STM, SMT
      - ./downloads:/app/downloads

      # Logs - Application logs
      - ./logs:/app/logs

      # Data - Cache, temp
      - ./data:/app/data

      # User Data - License & Settings
      - ./user_data:/app/user_data

  db:
    image: postgres:15-alpine
    volumes:
      # Database data (named volume)
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### Custom Mount Points

```yaml
volumes:
  # Mount ไปที่อื่น
  - /mnt/nas/nhso-downloads:/app/downloads

  # Mount เฉพาะบาง subdirectory
  - /data/rep:/app/downloads/rep
  - /data/stm:/app/downloads/stm
```

---

## Permissions

### ตั้งค่า Permissions

```bash
# สร้าง directories พร้อม permissions
mkdir -p downloads/{rep,stm,smt} logs data user_data
chmod 755 downloads logs data user_data

# ให้ current user เป็น owner
chown -R $USER:$USER downloads logs data user_data
```

### Permission Issues

**ปัญหา: Permission denied**
```bash
# ตรวจสอบ ownership
ls -la ./downloads

# แก้ไข
sudo chown -R $USER:$USER ./downloads ./logs ./data ./user_data
```

**ปัญหา: Container ไม่สามารถเขียนได้**
```bash
# ให้ container user (uid 1000) เขียนได้
sudo chown -R 1000:1000 ./downloads ./logs ./data ./user_data

# หรือให้ everyone เขียนได้
chmod -R 777 ./downloads ./logs ./data ./user_data
```

### Docker User Mapping

```yaml
# docker-compose.yml
services:
  web:
    user: "${UID:-1000}:${GID:-1000}"
    volumes:
      - ./downloads:/app/downloads
```

---

## Backup & Restore

### Backup ทั้งหมด

```bash
# สร้าง backup directory
mkdir -p ~/backup/revenue-intel

# Backup ทุกอย่าง
tar -czvf ~/backup/revenue-intel/backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  ./downloads ./logs ./data ./user_data

# Backup database ด้วย
docker compose exec db pg_dump -U eclaim eclaim_db | gzip > \
  ~/backup/revenue-intel/db_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Backup เฉพาะส่วนสำคัญ

```bash
# Backup เฉพาะ user_data (license + settings)
tar -czvf ~/backup/user_data_$(date +%Y%m%d).tar.gz ./user_data

# Backup เฉพาะ downloads
tar -czvf ~/backup/downloads_$(date +%Y%m%d).tar.gz ./downloads
```

### Restore

```bash
# Stop services
docker compose down

# Restore files
tar -xzvf backup_20260201.tar.gz

# Restore database
gunzip -c db_20260201.sql.gz | docker compose exec -T db psql -U eclaim eclaim_db

# Start services
docker compose up -d
```

### Automated Backup Script

```bash
#!/bin/bash
# backup.sh - Daily backup script

BACKUP_DIR=~/backup/revenue-intel
DATE=$(date +%Y%m%d)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup files
tar -czvf $BACKUP_DIR/files_$DATE.tar.gz ./user_data ./data

# Backup database
docker compose exec -T db pg_dump -U eclaim eclaim_db | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# เพิ่มใน crontab (backup ทุกวัน 2:00 AM)
crontab -e
0 2 * * * cd /path/to/revenue-intel && ./backup.sh
```

---

## Custom Mounts

### Mount จาก NAS/Network Storage

```yaml
# docker-compose.yml
services:
  web:
    volumes:
      # NFS mount
      - /mnt/nfs/nhso-data/downloads:/app/downloads

      # SMB/CIFS mount
      - /mnt/smb/hospital-share/revenue-intel:/app/data
```

**ตั้งค่า NFS mount บน host:**
```bash
# /etc/fstab
nas.hospital.local:/volume1/nhso-data /mnt/nfs/nhso-data nfs defaults 0 0
```

### Mount แยก Database Data

```yaml
# เก็บ database บน SSD
volumes:
  - /ssd/postgres-data:/var/lib/postgresql/data

# เก็บ downloads บน HDD
volumes:
  - /hdd/nhso-downloads:/app/downloads
```

### Mount สำหรับ Development

```yaml
# docker-compose.override.yml (development)
services:
  web:
    volumes:
      # Mount source code สำหรับ hot reload
      - ./src:/app/src:ro

      # Mount custom templates
      - ./templates:/app/templates:ro
```

---

## Troubleshooting

### ปัญหา: ไฟล์ไม่ปรากฏใน Container

```bash
# ตรวจสอบ mount
docker compose exec web ls -la /app/downloads

# ตรวจสอบว่า mount ถูกต้อง
docker inspect nhso-web | grep -A 10 "Mounts"
```

### ปัญหา: Disk Full

```bash
# ดูขนาดแต่ละ directory
du -sh ./downloads/* ./logs ./data ./user_data

# ล้างไฟล์เก่า
find ./downloads -type f -mtime +180 -delete
find ./logs -type f -mtime +30 -delete

# ล้าง docker
docker system prune -a
```

### ปัญหา: Slow Performance

```bash
# ใช้ cached mode (macOS)
volumes:
  - ./downloads:/app/downloads:cached

# ใช้ delegated mode (เร็วกว่า แต่ sync ช้า)
volumes:
  - ./downloads:/app/downloads:delegated
```

### ปัญหา: License หาย

```bash
# ตรวจสอบว่ามี license
ls -la ./user_data/license.lic

# ถ้าไม่มี ให้ติดตั้งใหม่ผ่าน Web UI
# Settings > License > Upload License File

# หรือ copy จาก backup
cp ~/backup/license.lic ./user_data/license.lic
docker compose restart web
```

---

## Storage Requirements

| Component | Min Size | Recommended | Growth Rate |
|-----------|----------|-------------|-------------|
| downloads/ | 1 GB | 10 GB | ~500 MB/month |
| logs/ | 100 MB | 1 GB | ~100 MB/month |
| data/ | 100 MB | 500 MB | Minimal |
| user_data/ | 1 MB | 10 MB | None |
| database | 500 MB | 5 GB | ~200 MB/month |

**Total Recommended:** 20 GB+

---

## Related Docs

- [Installation Guide](INSTALLATION.md)
- [Configuration Guide](CONFIGURATION.md)
- [Commands Reference](COMMANDS.md)
- [Backup & Restore](USER_MANAGEMENT.md#-backup--restore)
