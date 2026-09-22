# logcli export scripts

เอกสารและสคริปต์ใน repository นี้ถูกสร้างโดย Codex ChatGPT

โปรเจกต์นี้มี shell script สำหรับ Ubuntu เพื่อส่งออก log จาก Loki ผ่าน `logcli` โดยแยกไฟล์ตามรูปแบบการใช้งาน 4 แบบ:

- `export_log_plain.sh` ส่งออก log ตามช่วงเวลาเป็นไฟล์ `.log` ปกติ
- `export_log_plain_query.sh` ส่งออก log ตามช่วงเวลาเป็นไฟล์ `.log` ปกติ และกำหนด query เพิ่มได้
- `export_log_archive.sh` ส่งออก log ตามช่วงเวลา แล้วบีบอัดและเข้ารหัสเป็น `.7z`
- `export_log_archive_query.sh` ส่งออก log ตามช่วงเวลา กำหนด query เพิ่มได้ แล้วบีบอัดและเข้ารหัสเป็น `.7z`

ค่าหลักที่ตั้งไว้ในทุกสคริปต์:

- Loki address: `http://127.0.0.1:3100`
- รูปแบบ output: `raw`
- จำนวน log: `--limit=0`
- ทิศทางการอ่าน log: `--forward`

สคริปต์ที่บีบอัดจะใช้ `7za` พร้อม `-mhe=on` เพื่อเข้ารหัสชื่อไฟล์ภายใน archive ทำให้ไม่สามารถอ่านรายชื่อไฟล์ได้หากไม่มีรหัสผ่าน

## สิ่งที่ต้องติดตั้งบน Ubuntu

ต้องมีคำสั่งต่อไปนี้ใน `PATH`

- `bash`
- `logcli`
- `7za`

ตัวอย่างติดตั้ง `7za` บน Ubuntu:

```bash
sudo apt update
sudo apt install p7zip-full
```

ถ้ายังไม่ได้ตั้งสิทธิ์ execute ให้ตั้งค่าก่อน:

```bash
chmod +x export_log_plain.sh export_log_plain_query.sh export_log_archive.sh export_log_archive_query.sh
```

หรือใช้ `bash ./ชื่อไฟล์.sh ...` แทนได้ทันที

## ตั้งค่า query พื้นฐาน

ทุกสคริปต์มีตัวแปร `BASE_QUERY` เริ่มต้นเป็น:

```logql
{job=~".+"}
```

ถ้า log ใน Loki ของคุณไม่ได้มี label ชื่อ `job` ให้แก้ `BASE_QUERY` ในแต่ละสคริปต์ให้ตรงกับระบบของคุณ เช่น:

```bash
BASE_QUERY="${BASE_QUERY:-{app=~\".+\"}}"
```

หรือกำหนดตอนรัน:

```bash
BASE_QUERY='{app="nginx"}' ./export_log_plain.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/nginx.log"
```

## ตั้งค่ารหัสผ่านสำหรับไฟล์ `.7z`

ใช้เฉพาะสคริปต์:

- `export_log_archive.sh`
- `export_log_archive_query.sh`

ให้ตั้งรหัสผ่านในตัวแปร `ARCHIVE_PASSWORD` ภายในสคริปต์:

```bash
ARCHIVE_PASSWORD="${LOGCLI_EXPORT_PASSWORD:-รหัสผ่านของคุณ}"
```

หรือส่งผ่าน environment variable:

```bash
export LOGCLI_EXPORT_PASSWORD='รหัสผ่านของคุณ'
```

สคริปต์ปิด shell tracing ด้วย `set +x` เพื่อลดความเสี่ยงที่รหัสผ่านจะถูกพิมพ์ลง log ของ shell อย่างไรก็ตาม หลีกเลี่ยงการรันด้วย `bash -x` และอย่า commit รหัสผ่านจริงลง repository ถ้า repository นี้ถูกแชร์กับผู้อื่น

## รูปแบบเวลา

พารามิเตอร์ `FROM` และ `TO` จะถูกส่งต่อให้ `logcli --from` และ `logcli --to` โดยตรง แนะนำให้ใช้เวลาแบบ RFC3339 พร้อม timezone offset เช่น:

```text
2026-09-22T00:00:00+07:00
2026-09-22T01:00:00+07:00
```

ตัวอย่างด้านบนคือเวลาโซนไทย `UTC+07:00` หากต้องการใช้ UTC สามารถใช้ `Z` แทน timezone offset ได้ เช่น `2026-09-22T00:00:00Z`

## 1. ส่งออก log ตามช่วงเวลาเป็นไฟล์ `.log` ปกติ

สคริปต์: `export_log_plain.sh`

ไม่มีการบีบอัดและไม่มีการเข้ารหัส ใช้ `BASE_QUERY` จากในสคริปต์

```bash
./export_log_plain.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/app.log"
```

ผลลัพธ์:

```text
./logs/app.log
```

## 2. ส่งออก log ตามช่วงเวลาเป็นไฟล์ `.log` ปกติ พร้อมกำหนด query เพิ่ม

สคริปต์: `export_log_plain_query.sh`

ตัวอย่างเพิ่ม filter ต่อท้าย `BASE_QUERY` เพื่อค้นหาเฉพาะบรรทัดที่มีคำว่า `error`:

```bash
./export_log_plain_query.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/error.log" \
  '|= "error"'
```

สคริปต์จะรวม query เป็น:

```logql
{job=~".+"} |= "error"
```

ถ้าพารามิเตอร์ query เพิ่มเริ่มต้นด้วย `{` สคริปต์จะถือว่าเป็น LogQL query แบบเต็ม และจะใช้ค่านั้นแทน `BASE_QUERY`:

```bash
./export_log_plain_query.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/nginx.log" \
  '{app="nginx"} |= "500"'
```

## 3. ส่งออก log ตามช่วงเวลาแบบบีบอัดและเข้ารหัส

สคริปต์: `export_log_archive.sh`

สคริปต์นี้ใช้ `BASE_QUERY` จากในสคริปต์ แล้วส่ง output แบบ `raw` เข้า `7za` โดยตรงผ่าน stdin ไม่มีการสร้างไฟล์ log ชั่วคราวแบบ plaintext

ก่อนใช้งานต้องตั้งรหัสผ่านในตัวแปร `ARCHIVE_PASSWORD` หรือ `LOGCLI_EXPORT_PASSWORD`

```bash
./export_log_archive.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/app.7z"
```

ภายใน archive จะมีชื่อไฟล์เริ่มต้นเป็น `exported.log` และชื่อไฟล์นี้จะถูกเข้ารหัสด้วย `-mhe=on`

ถ้าต้องการเปลี่ยนชื่อไฟล์ log ภายใน archive ให้กำหนด `INNER_LOG_NAME`:

```bash
INNER_LOG_NAME="app-2026-09-22.log" ./export_log_archive.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/app.7z"
```

## 4. ส่งออก log ตามช่วงเวลาแบบบีบอัดและเข้ารหัส พร้อมกำหนด query เพิ่ม

สคริปต์: `export_log_archive_query.sh`

ตัวอย่างค้นหาเฉพาะ log ที่มีคำว่า `error` แล้วบีบอัดและเข้ารหัสเป็น `.7z`:

```bash
./export_log_archive_query.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/error.7z" \
  '|= "error"'
```

หรือใช้ LogQL query แบบเต็ม:

```bash
./export_log_archive_query.sh \
  "2026-09-22T00:00:00+07:00" \
  "2026-09-22T01:00:00+07:00" \
  "./logs/nginx-error.7z" \
  '{app="nginx"} |= "error"'
```

## วิธีแตกไฟล์ archive

ใช้คำสั่ง:

```bash
7za x "./logs/app.7z"
```

ระบบจะถามรหัสผ่านก่อนอ่านรายชื่อไฟล์และแตกไฟล์

## หมายเหตุด้านความปลอดภัย

- อย่า commit รหัสผ่านจริงลง repository ถ้า repository นี้ถูกแชร์กับผู้อื่น
- อย่ารันสคริปต์ด้วย `bash -x` เพราะอาจทำให้ข้อมูลลับถูกพิมพ์ออกมา
- การกำหนดรหัสผ่านผ่านตัวแปรช่วยลดโอกาสที่รหัสผ่านจะหลุดใน command history หรือ log ของคำสั่ง แต่บางระบบอาจยังเห็น argument ของ process ได้ชั่วคราวขณะ `7za` กำลังทำงาน
- ใช้ `.7z` กับ `-mhe=on` เพื่อเข้ารหัสทั้งเนื้อหาและชื่อไฟล์ภายใน archive

## อ้างอิง

- เอกสาร LogCLI ของ Grafana Loki: <https://grafana.com/docs/loki/latest/query/logcli/getting-started/>
