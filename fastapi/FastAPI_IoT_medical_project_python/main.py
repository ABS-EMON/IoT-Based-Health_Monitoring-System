from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
import mysql.connector
from typing import List
from pydantic import BaseModel
from datetime import datetime

# DB Config
db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "esp32_data"
}

app = FastAPI()

# Allow CORS for Flutter frontend or any client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic model for reading data
class SensorData(BaseModel):
    id: int
    heart_rate: int
    temperature: float
    humidity: float
    spo2: int
    bp_sys: int
    bp_dia: int
    timestamp: str

@app.get("/")
def root():
    return {"message": "ESP32 Sensor API is running"}

@app.get("/sensors", response_model=List[SensorData])
def read_sensor_data():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM sensors ORDER BY timestamp DESC LIMIT 10")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    # Convert datetime to string for JSON
    for row in rows:
        if isinstance(row['timestamp'], datetime):
            row['timestamp'] = row['timestamp'].strftime("%Y-%m-%d %H:%M:%S")

    return rows

@app.post("/upload")
def upload_sensor_data(
    heart_rate: int = Form(...),
    temperature: float = Form(...),
    humidity: float = Form(...),
    spo2: int = Form(...),
    bp_sys: int = Form(...),
    bp_dia: int = Form(...)
):
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO sensors (heart_rate, temperature, humidity, spo2, bp_sys, bp_dia)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (heart_rate, temperature, humidity, spo2, bp_sys, bp_dia)
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"status": "success", "message": "Data inserted"}
