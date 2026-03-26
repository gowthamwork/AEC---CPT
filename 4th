clc;
clear;
% --------------------------
% Parameters
% --------------------------
N = 64;              % Number of subcarriers
CP_len = 16;         % Cyclic prefix length
num_symbols = 100;   % Number of OFDM symbols per SNR
M = 4;               % QPSK (2 bits per symbol)
SNR_dB_range = 0:2:20; % SNR range in dB for BER plot
num_bits_per_symbol = log2(M);
num_total_bits = num_symbols * N * num_bits_per_symbol;

BER = zeros(length(SNR_dB_range), 1); % Initialize BER array

% --------------------------
% Start BER vs. SNR Simulation
% --------------------------
for idx = 1:length(SNR_dB_range)
    snr_db = SNR_dB_range(idx);
    
    % --------------------------------------
    % Transmitter: Generate random data bits
    % --------------------------------------
    bits = randi([0 1], num_total_bits, 1);

    % --------------------------------------
    % QPSK Modulation (manual)
    % --------------------------------------
    symbols = zeros(length(bits)/2, 1);
    for i = 1:2:length(bits)
        b1 = bits(i);
        b2 = bits(i+1);

        % QPSK mapping: Gray coding
        re = 2 * b1 - 1;
        im = 2 * b2 - 1;

        symbols((i+1)/2) = (re + 1i * im) / sqrt(2);
    end

    % --------------------------------------
    % OFDM Modulation
    % --------------------------------------
    ofdm_symbols = reshape(symbols, N, num_symbols);      % Reshape to N subcarriers
    tx_signal = ifft(ofdm_symbols);                       % IFFT for OFDM modulation
    tx_cp = [tx_signal(end - CP_len + 1:end, :); tx_signal]; % Add cyclic prefix
    tx_serial = tx_cp(:);                                 % Serialize

    % --------------------------------------
    % Add AWGN Noise (manual)
    % --------------------------------------
    signal_power = mean(abs(tx_serial).^2);
    snr_linear = 10^(snr_db / 10);
    noise_power = signal_power / snr_linear;
    noise = sqrt(noise_power / 2) * (randn(size(tx_serial)) + 1i * randn(size(tx_serial)));
    rx_serial = tx_serial + noise;
    % --------------------------------------
    % OFDM Demodulation
    % --------------------------------------
    rx_cp = reshape(rx_serial, N + CP_len, num_symbols);
    rx_signal = rx_cp(CP_len + 1:end, :);
    rx_ofdm_symbols = fft(rx_signal);
    rx_symbols = rx_ofdm_symbols(:);
    % --------------------------------------
    % QPSK Demodulation (manual)
    % --------------------------------------
    rx_bits = zeros(length(bits), 1);
    for k = 1:length(rx_symbols)
        re = real(rx_symbols(k));
        im = imag(rx_symbols(k));

        rx_bits(2*k - 1) = re > 0; % First bit (real part)
        rx_bits(2*k)     = im > 0; % Second bit (imag part)
    end

    % --------------------------------------
    % BER Calculation
    % --------------------------------------
    num_errors = sum(bits ~= rx_bits);
    BER(idx) = num_errors / length(bits);

    disp(['SNR = ' num2str(snr_db) ' dB, BER = ' num2str(BER(idx))]);
end

% --------------------------
% Plot BER vs. SNR
% --------------------------
figure;
semilogy(SNR_dB_range, BER, '-o', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs. SNR for QPSK-OFDM (No External Functions)');
legend('OFDM-QPSK');
