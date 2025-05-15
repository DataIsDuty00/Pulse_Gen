%% 1. Arduino'dan Veri Okuma
% Seri portu ayarla (Kendi COM portuna göre değiştir!)
s = serialport("COM3", 9600);

% Önceki verileri temizle
flush(s);

% Veri dizisi oluştur
data = [];
for i = 1:500
    if s.NumBytesAvailable > 0
        raw = readline(s);
        value = str2double(raw);
        data(end+1) = value;
        fprintf("Veri [%d]: %f\n", i, value);  % VERİLERİ GÖSTER
    end
    pause(0.05);
end

% Seri portu kapat
clear s;

%% 2. Ham Veriyi Çiz
% Zaman dizisi oluştur (500 örnek, 50ms aralıkla)
time = (0:length(data)-1) * 0.05;

% Ham veriyi zamanla grafiğe dök
figure;
plot(time, data, 'b');
xlabel('Zaman (saniye)');
ylabel('FSR Okuması (0-1023)');
title('Ham FSR Verisi');
grid on;

%% 3. Veriyi Lineerleştirme (örnek kuvvet tahmini)
% Bu örnek değerleri senin kalibrasyonuna göre değiştireceğiz
fsr_val = [900, 700, 500, 400, 300];   % örnek FSR çıkışları
force_val = [0, 5, 10, 15, 20];        % karşılık gelen kuvvet (Newton)

% 2. dereceden polinom eğrisi uydur
p = polyfit(fsr_val, force_val, 2);

% Tüm FSR verisini kuvvete dönüştür
estimated_force = polyval(p, data);

% Lineerleştirilmiş kuvvet verisini çiz
figure;
plot(time, estimated_force, 'r');
xlabel('Zaman (saniye)');
ylabel('Kuvvet (tahmini - N)');
title('Lineerleştirilmiş Kuvvet Verisi');
grid on;


