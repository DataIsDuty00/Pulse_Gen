%% FSR Kuvvet Ölçüm Sistemi - Toolbox Gerekmez
clear; close all; clc;

% Seri Port Ayarları
port_name = "COM3";       % Portu kontrol edin
baud_rate = 9600;
s = serialport(port_name, baud_rate);
configureTerminator(s, "LF");
flush(s);

% Donanım Parametreleri
R_fixed = 10000;    % 10kΩ sabit direnç
Vcc = 5;            % Arduino voltajı

%% Kalibrasyon Prosedürü (Önce Çalıştırın)
%--------------------------------------------------
known_forces = [0.08 0.4 1.6];  % 0 N hariç (log 0 tanımsız)
measured_adc = [70 350 480];     % Karşılık gelen ADC değerleri

% Direnç Hesaplama
Vout = (measured_adc / 1023) * Vcc;
R_fsr = (Vcc * R_fixed ./ Vout) - R_fixed;

% Lineer Regresyon ile Power Law Optimizasyonu
X = log(R_fsr(:));         % ln(R_fsr)
Y = log(known_forces(:));  % ln(Force)

A_matrix = [ones(length(X),1), -X];
coefficients = A_matrix \ Y;

% Katsayıları çıkar
B = coefficients(2);
A = exp(coefficients(1));

fprintf('Kalibrasyon Tamamlandı:\nA = %.2e\nB = %.2f\n', A, B);
%--------------------------------------------------

%% Gerçek Zamanlı Ölçüm Sistemi
buffer_size = 300;  % 30 saniye (0.1s örnekleme)
fsr_time = nan(1, buffer_size);
fsr_force = nan(1, buffer_size);

% Grafik Hazırlığı
figure;
h = plot(nan, nan, 'b-', 'LineWidth', 1.5);
hold on;
plot(xlim, [20 20], 'r--', 'LineWidth', 2, 'DisplayName', '20N Limit');
grid on;
xlabel('Zaman (s)');
ylabel('Kuvvet (N)');
title('Gerçek Zamanlı Kuvvet İzleme');
ylim([0 25]);
xlim([0 30]);
legend('Location', 'northwest');

% Performans Optimizasyonları
persistent last_warning;  % 20N uyarıları için
last_warning = 0;

disp('Sistem aktif... (Durdurmak için Ctrl+C)');

%% Ana Ölçüm Döngüsü
t0 = tic;
idx = 1;
while ishandle(h)
    try
        if s.NumBytesAvailable > 0
            raw = readline(s);
            adc = str2double(raw);
            
            % Geçerli ADC kontrolü
            if ~isnan(adc) && adc >= 0 && adc <= 1023
                % Kuvvet Hesaplama
                if adc == 0
                    Force_N = 0;
                else
                    Vout = (adc / 1023) * Vcc;
                    R_fsr = (Vcc * R_fixed / Vout) - R_fixed;
                    Force_N = A * (R_fsr ^ -B);
                end
                
                % Sınırlamalar
                Force_N = max(min(Force_N, 25), 0);
                
                % Veriyi Kaydet
                current_time = toc(t0);
                fsr_time(idx) = current_time;
                fsr_force(idx) = Force_N;
                
                % Grafik Güncelleme
                set(h, 'XData', fsr_time, 'YData', fsr_force);
                
                % 20N Uyarısı (10 saniyede bir)
                if Force_N >= 20 && (current_time - last_warning) > 10
                    fprintf('[%s] 20N SINIRI! >> ADC: %d, Kuvvet: %.1fN\n',...
                        datestr(now), adc, Force_N);
                    last_warning = current_time;
                end
                
                % Dizin Yönetimi
                idx = mod(idx, buffer_size) + 1;
                drawnow limitrate;
            end
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
            break; % Figure kapatıldığında döngüyü sonlandır
        else
            fprintf('Hata: %s\n', ME.message);
        end
    end
end

%% Temizlik
clear s;
disp('Sistem güvenli şekilde durduruldu.');