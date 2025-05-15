%% Kalibrasyon Verileri (ÖNCE BU KISMI ÇALIŞTIRIN)
% --------------------------------------------------
 known_forces = [0 0.08 0.4 1.6];      % Kalibre edilen kuvvetler (N)
 measured_adc = [0 70 350 480];  % Ölçülen ADC değerleri
 
 % Eğri uydurma
 Vout = (measured_adc / 1023) * Vcc;
 R_fsr = (Vcc * R_fixed ./ Vout) - R_fixed;
 R_fsr(1) = 1e6; % 0 N için yüksek direnç
 
 ft = fittype('a*x^-b');
 [fit_result, gof] = fit(R_fsr(2:end)', known_forces(2:end)', ft,...
     'StartPoint', [1e4 1], 'Robust', 'Bisquare');
 
 A = fit_result.a;
 B = fit_result.b;
% --------------------------------------------------

    
