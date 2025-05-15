s = serialport("COM3", 9600);  
pause(2);  % Port stabilitesi için bekleme

N = 500;
dt = 0.05;
data = zeros(1, N);
time = (0:N-1) * dt;

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

% Otomatik threshold
baseline = mean(data(1:40));       % 2 saniye
noise_std = std(data(1:40));
threshold = baseline + 3 * noise_std;

% Tepki analizi
first_resp_idx = find(data > threshold, 1, 'first');
resp_time = time(first_resp_idx);
[max_val, max_idx] = max(data);
peak_time = time(max_idx);
response_window = data(first_resp_idx:max_idx);
variability = std(response_window);

% Sonuçları yazdır
fprintf("\n--- ANALİZ ---\n");
fprintf("Threshold: %.2f\n", threshold);
fprintf("Tepki süresi: %.2f saniye\n", resp_time);
fprintf("Zirve süresi: %.2f saniye (Max: %.1f)\n", peak_time, max_val);
fprintf("Kararsızlık (std): %.2f\n", variability);

% Dosya adlarını zaman etiketli oluştur
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
mat_filename = ['veri_' timestamp '.mat'];
csv_filename = ['veri_' timestamp '.csv'];
log_filename = ['rapor_' timestamp '.txt'];

save(mat_filename, 'data', 'time');
writematrix([time' data'], csv_filename);

% Otomatik Rapor
fid = fopen(log_filename, 'w');
fprintf(fid, 'FSR Davranış Raporu - %s\n\n', timestamp);
fprintf(fid, 'Toplam örnek: %d\n', N);
fprintf(fid, 'Threshold (gürültü + 3σ): %.2f\n', threshold);
fprintf(fid, 'Tepki süresi: %.2f s\n', resp_time);
fprintf(fid, 'Zirve süresi: %.2f s (Değer: %.1f)\n', peak_time, max_val);
fprintf(fid, 'Tepki değişkenliği (kararsızlık): %.2f\n', variability);
fclose(fid);

% Portu kapat
clear s;
