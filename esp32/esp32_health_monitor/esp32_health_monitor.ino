#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "WALPAD8G_V2";
const char* password = "Emon1877530";

void setup() {
  Serial.begin(115200);
  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("Connected!");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    int heart_rate = random(60, 100);
    int spo2 = random(95, 100);
    int bp_sys = random(110, 130);
    int bp_dia = random(70, 90);

    String postData = 
      "heart_rate=" + String(heart_rate) +
      "&temperature=" + String(temp) +
      "&humidity=" + String(hum) +
      "&spo2=" + String(spo2) +
      "&bp_sys=" + String(bp_sys) +
      "&bp_dia=" + String(bp_dia);

    HTTPClient http;
    http.begin("http://192.168.81.187:8000/upload");
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    int responseCode = http.POST(postData);
    Serial.println("HTTP Response: " + String(responseCode));
    http.end();
  }

  delay(5000);
}
