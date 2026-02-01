# Volume Mounts & Data Storage

คู่มือการจัดการ Volume Mounts และ Data Storage

---

## 📋 สารบัญ

- [Overview](#-overview)
- [Volume Mounts ทั้งหมด](#-volume-mounts-ทั้งหมด)
- [รายละเอียดแต่ละ Directory](#-รายละเอียดแต่ละ-directory)
- [Docker Compose Configuration](#-docker-compose-configuration)
- [Permissions](#-permissions)
- [Backup & Restore](#-backup--restore)
- [Custom Mounts](#-custom-mounts)
- [Troubleshooting](#-troubleshooting)

---

## 📦 Overview

Revenue Intelligence System ใช้ Volume Mounts เพื่อเก็บข้อมูลนอก Container:

```
./
├── downloads/          # ไฟล์ที่ดาวน์โหลด
│   ├── rep/           # REP files
│   ├── stm/           # STM files
│   └── smt/           # SMT files
├── logs/              # Log files
├── data/              # Application data
└── config/            # Configuration & License
```

**ทำไมต้อง Mount?**
- ข้อมูลไม่หายเมื่อ restart/update container
- สามารถ backup ได้ง่าย
- แชร์ข้อมูลระหว่าง containers ได้

---

## 📂 Volume Mounts ทั้งหมด

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `./downloads/` | `/app/downloads` | ไฟล์ REP, STM, SMT ที่ดาวน์โหลด |
| `./logs/` | `/app/logs` | Application logs |
| `./data/` | `/app/data` | Settings, cache, temp files |
| `./config/` | `/app/config` | **License file**, custom config |
| `db_data` (volume) | `/var/lib/postgresql/data` | PostgreSQL data |

---

## 📁 รายละเอียดแต่ละ Directory

### 📥 downloads/

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

### 📝 logs/

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

### 💾 data/

เก็บ Application data:

```
data/
├── settings.json           # User settings
├── hospital_info.json      # Hospital configuration
├── scheduler_state.json    # Scheduler state
├── cache/                  # Temporary cache
│   ├── analytics/
│   └── reports/
└── temp/                   # Temporary files
```

**ไฟล์สำคัญ:**

| File | Description | Reset Effect |
|------|-------------|--------------|
| `settings.json` | การตั้งค่าทั้งหมด | กลับเป็น default |
| `hospital_info.json` | ข้อมูลโรงพยาบาล | ต้อง setup ใหม่ |
| `scheduler_state.json` | สถานะ scheduler | scheduler reset |

**การจัดการ:**
```bash
# Backup settings
cp ./data/settings.json ./data/settings.json.bak

# Reset settings
rm ./data/settings.json
docker compose restart web

# ล้าง cache
rm -rf ./data/cache/*
```

---

### 🔐 config/

เก็บ Configuration และ License:

```
config/
├── license.lic             # License file (สำคัญมาก!)
├── custom_config.json      # Custom configuration (optional)
└── ssl/                    # SSL certificates (optional)
    ├── cert.pem
    └── key.pem
```

**⚠️ สำคัญ: license.lic**
- ไฟล์นี้คือ License ของระบบ
- **ห้ามลบ!** ถ้าลบต้องติดตั้ง license ใหม่
- Backup ไว้เสมอ

**การจัดการ:**
```bash
# Backup license
cp ./config/license.lic ~/backup/license.lic.bak

# ติดตั้ง license ใหม่
cp /path/to/new/license.lic ./config/license.lic
docker compose restart web
```

---

## 🐳 Docker Compose Configuration

### Default Configuration

```yaml
# docker-compose.yml
services:
  web:
    image: ghcr.io/aegisx-platform/revenue-intelligence-system:latest
    volumes:
      # Downloads - ไฟล์ REP, STM, SMT
      - ./downloads:/app/downloads
      
      # Logs - Application logs
      - ./logs:/app/logs
      
      # Data - Settings, cache
      - ./data:/app/data
      
      # Config - License file
      - ./config:/app/config

  db:
    image: postgres:15-alpine
    volumes:
      # Database data (named volume)
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### Read-Only Mounts (Optional)

```yaml
volumes:
  # License file read-only (ป้องกันการแก้ไข)
  - ./config/license.lic:/app/config/license.lic:ro
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

## 🔒 Permissions

### ตั้งค่า Permissions

```bash
# สร้าง directories พร้อม permissions
mkdir -p downloads/{rep,stm,smt} logs data config
chmod 755 downloads logs data config

# ให้ current user เป็น owner
chown -R $USER:$USER downloads logs data config
```

### Permission Issues

**ปัญหา: Permission denied**
```bash
# ตรวจสอบ ownership
ls -la ./downloads

# แก้ไข
sudo chown -R $USER:$USER ./downloads ./logs ./data ./config
```

**ปัญหา: Container ไม่สามารถเขียนได้**
```bash
# ให้ container user (uid 1000) เขียนได้
sudo chown -R 1000:1000 ./downloads ./logs ./data ./config

# หรือให้ everyone เขียนได้
chmod -R 777 ./downloads ./logs ./data ./config
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

## 💾 Backup & Restore

### Backup ทั้งหมด

```bash
# สร้าง backup directory
mkdir -p ~/backup/revenue-intel

# Backup ทุกอย่าง
tar -czvf ~/backup/revenue-intel/backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  ./downloads ./logs ./data ./config

# Backup database ด้วย
docker compose exec db pg_dump -U eclaim eclaim_db | gzip > \
  ~/backup/revenue-intel/db_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Backup เฉพาะส่วนสำคัญ

```bash
# Backup เฉพาะ config และ license
tar -czvf ~/backup/config_$(date +%Y%m%d).tar.gz ./config ./data/settings.json

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
tar -czvf $BACKUP_DIR/files_$DATE.tar.gz ./config ./data

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

## 🔧 Custom Mounts

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

## 🔧 Troubleshooting

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
du -sh ./downloads/* ./logs ./data ./config

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
ls -la ./config/license.lic

# ถ้าไม่มี ให้ติดตั้งใหม่ผ่าน Web UI
# Settings > License > Upload License File

# หรือ copy จาก backup
cp ~/backup/license.lic ./config/license.lic
docker compose restart web
```

---

## 📊 Storage Requirements

| Component | Min Size | Recommended | Growth Rate |
|-----------|----------|-------------|-------------|
| downloads/ | 1 GB | 10 GB | ~500 MB/month |
| logs/ | 100 MB | 1 GB | ~100 MB/month |
| data/ | 100 MB | 500 MB | Minimal |
| config/ | 1 MB | 10 MB | None |
| database | 500 MB | 5 GB | ~200 MB/month |

**Total Recommended:** 20 GB+

---

## 📚 Related Docs

- [Installation Guide](INSTALLATION.md)
- [Configuration Guide](CONFIGURATION.md)
- [Commands Reference](COMMANDS.md)
- [Backup & Restore](USER_MANAGEMENT.md#-backup--restore)
