# health-monitoring-system-IoT-project

---

# 📁 Project: Real-Time Health Monitor

*A complete IoT-to-App pipeline: ESP32 → FastAPI → MySQL → Flutter Mobile App*

---

## 📄 Repository structure

```
health-monitor/
├── esp32/
│   └── esp32_health_monitor.ino
├── fastapi/
│   ├── main.py
│   └── requirements.txt
├── flutter/
│   └── [Your Flutter project folder]
│
└── README.md
```

---

## 📝 README.md

# 📲 Real-Time Health Monitoring System

This project is an end-to-end health monitoring system that collects sensor data from an **ESP32**, stores it in a **MySQL database** through a **FastAPI backend**, and displays it in real-time in a **Flutter mobile app**.

---

## 🚀 Features

✅ ESP32 reads health sensors and sends POST data to FastAPI
✅ FastAPI saves the data into MySQL (`esp32_data.sensors`)
✅ FastAPI provides an API (`/sensors`) to fetch latest data
✅ Flutter app shows real-time data from FastAPI API

---

## 📁 Components

###1️⃣ ESP32

Located in: `esp32/esp32_health_monitor.ino`

* Reads:

  * Heart rate
  * Temperature
  * Humidity
  * SpO2
  * Blood pressure (Sys/Dia)
* Sends HTTP POST to FastAPI

⚙️ Configure these in your `.ino` file:

* WiFi SSID & Password
* FastAPI Server IP (`http://<your_server_ip>:8000/data`)

---

### 2️⃣ FastAPI Backend

Located in: `fastapi/main.py`

✅ Features:

* Endpoint `/data` (POST): ESP32 sends data here.
* Endpoint `/sensors` (GET): Flutter app fetches latest 10 readings.

---

#### 📦 Setup FastAPI

On your server/laptop:

```bash
cd fastapi
python -m venv venv
source venv/bin/activate      # Linux/Mac
venv\Scripts\activate         # Windows

pip install -r requirements.txt
```

✅ Start server:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

You should see:

```
Uvicorn running on http://0.0.0.0:8000
```

---

### 3️⃣ MySQL Database

* Create database: `esp32_data`
* Create table:

```sql
CREATE TABLE sensors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  heart_rate INT,
  temperature FLOAT,
  humidity FLOAT,
  spo2 INT,
  bp_sys INT,
  bp_dia INT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

### 4️⃣ Flutter App

Located in: `flutter/`

✅ Features:

* Polls FastAPI `/sensors` endpoint every 5 seconds.
* Displays latest readings beautifully.

⚙️ Change API URL in Flutter app:

```dart
const String apiUrl = "http://<your_server_ip>:8000/sensors";
```

Then run:

```bash
cd flutter
flutter pub get
flutter run
```

---

## 🖥️ FastAPI endpoints

| Method | URL        | Description             |
| ------ | ---------- | ----------------------- |
| POST   | `/data`    | ESP32 posts sensor data |
| GET    | `/sensors` | Returns last 10 rows    |

---

## 🔷 Which files to modify for a new deployment?

✅ In ESP32 code: update WiFi credentials & FastAPI server IP
✅ In Flutter app: update `apiUrl` with FastAPI server IP
✅ On FastAPI server: update `db_config` in `main.py` with your MySQL username/password if different

---

## 📦 Requirements

* ESP32 board
* MySQL database
* Python 3.9+ (with FastAPI & uvicorn)
* Flutter SDK

---

## 💻 Contributors

⭐ You!

---

## 📷 Screenshots

✅ Add screenshots of your Flutter app UI and API response.

---

# 📄 fastapi/main.py (final)

Here’s the full final **FastAPI main.py:**

```python
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import mysql.connector
from typing import List
from pydantic import BaseModel
from datetime import datetime

db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "esp32_data"
}

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SensorData(BaseModel):
    heart_rate: int
    temperature: float
    humidity: float
    spo2: int
    bp_sys: int
    bp_dia: int

class SensorResponse(SensorData):
    id: int
    timestamp: str

@app.post("/data")
async def post_sensor_data(data: SensorData):
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO sensors 
        (heart_rate, temperature, humidity, spo2, bp_sys, bp_dia)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (data.heart_rate, data.temperature, data.humidity, data.spo2, data.bp_sys, data.bp_dia)
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Data inserted successfully"}

@app.get("/sensors", response_model=List[SensorResponse])
def read_sensor_data():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM sensors ORDER BY timestamp DESC LIMIT 10")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    for row in rows:
        if isinstance(row['timestamp'], datetime):
            row['timestamp'] = row['timestamp'].strftime("%Y-%m-%d %H:%M:%S")
    return rows
```

---

## 📄 fastapi/requirements.txt

```
fastapi
uvicorn
mysql-connector-python
```

---

✅ You now have everything to upload to GitHub:

* ESP32 `.ino`
* Flutter `/`
* FastAPI `/`
* README.md with clear instructions

---
