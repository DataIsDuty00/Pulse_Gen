s = serialport("COM3", 9600);

pause(2);  

N = 500;               
dt = 0.05;             
data = zeros(1, N);    
time = (0:N-1) * dt;  

% Veri Toplama
disp("Veri toplanıyor...");
for i = 1:N
    if s.NumBytesAvailable > 0
        raw = readline(s);
        value = str2double(raw);
        if ~isnan(value)
            data(i) = value;
            fprintf("Veri [%d]: %f\n", i, value);
        end
    end
    pause(dt);
end

% Grafikle Gösterim
figure;
plot(time, data, 'b-', 'LineWidth', 1.5);
xlabel('Zaman (s)');
ylabel('Basınç (FSR değeri)');
title('Ham FSR Verisi');
grid on;


threshold = 50;  % Gürültü eşiği (kendi sensörüne göre ayarla)???????
baseline = mean(data(1:10));
first_resp_idx = find(data > baseline + threshold, 1, 'first');
resp_time = time(first_resp_idx);


[max_val, max_idx] = max(data);
peak_time = time(max_idx);

    

response_window = data(first_resp_idx:max_idx);
variability = std(response_window);

% SONUÇLARI YAZDIR
fprintf("\n--- ANALİZ ---\n");
fprintf("Tepki süresi: %.2f saniye\n", resp_time);
fprintf("Zirve süresi: %.2f saniye (Max: %.1f)\n", peak_time, max_val);
fprintf("Tepki içi değişkenlik (kararsızlık): %.2f\n", variability);


save('fsr_ham_data.mat', 'data', 'time');
writematrix([time' data'], 'fsr_ham_data.csv');


clear s;
