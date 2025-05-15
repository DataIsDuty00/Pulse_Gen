void setup() {
  Serial.begin(9600);
}

void loop() {
  int fsrReading = analogRead(A0);
  Serial.println(fsrReading);
  delay(50); // 20 Hz örnekleme hızı
}
