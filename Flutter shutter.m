%% TP2: Optimization of a Flutter Shutter

% Load PSFs
psf1 = load('PSF1.txt');
psf2 = load('PSF2.txt');



%% Visualize the two PSFs
psf1 = load('PSF1.txt');
psf2 = load('PSF2.txt');

figure;
subplot(2, 1, 1);
stem(psf1, 'b', 'DisplayName', 'PSF1');
xlabel('Index');
ylabel('Value');
title('PSF1');
grid on;

subplot(2, 1, 2);
stem(psf2, 'r', 'DisplayName', 'PSF2');
xlabel('Index');
ylabel('Value');
title('PSF2');
grid on;

saveas(gcf, 'psf_visualization.png');


%% 3.1 Plot the power spectral densities (PSDs) of the two PSFs
nfft = 1024; % Zero-padding length
psd1 = abs(fft(psf1, nfft)).^2;
psd2 = abs(fft(psf2, nfft)).^2;

f = linspace(0, 1, nfft/2 + 1); % Frequency axis
figure;
semilogy(f, psd1(1:nfft/2+1), 'b', 'DisplayName', 'PSF1');
hold on;
semilogy(f, psd2(1:nfft/2+1), 'r', 'DisplayName', 'PSF2');
xlabel('Frequency (normalized)');
ylabel('Power Spectral Density (log scale)');
title('Power Spectral Density of PSFs');
legend;
grid on;
saveas(gcf, 'psf_psd_comparison.png');

%% 3.2 Simulate blurred images using PSFs and add Gaussian noise
ground_truth = imread('boat_groundtruth.png');
ground_truth = im2gray(ground_truth); % Convert to grayscale (compatible with RGB and grayscale images)
ground_truth = double(ground_truth) / 255; % Normalize to [0, 1]

% Add blur and noise
sigma_b = 10 / 255; % Convert noise level to normalized range
blurred1 = imfilter(ground_truth, psf1, 'conv', 'circular') + sigma_b * randn(size(ground_truth));
blurred2 = imfilter(ground_truth, psf2, 'conv', 'circular') + sigma_b * randn(size(ground_truth));

figure;
imshow(blurred1, []);
title('Blurred Image with PSF1');
saveas(gcf, 'blurred_image_psf1.png');

figure;
imshow(blurred2, []);
title('Blurred Image with PSF2');
saveas(gcf, 'blurred_image_psf2.png');

%% Deconvolve images using Wiener filter
% Assumed noise-to-signal ratio for Wiener filter
nsr1 = var(sigma_b) / var(psf1);
nsr2 = var(sigma_b) / var(psf2);

deblurred1 = deconvwnr(blurred1, psf1, nsr1);
deblurred2 = deconvwnr(blurred2, psf2, nsr2);

figure;
imshow(deblurred1, []);
title('Deblurred Image with PSF1');
saveas(gcf, 'deblurred_image_psf1.png');

figure;
imshow(deblurred2, []);
title('Deblurred Image with PSF2');
saveas(gcf, 'deblurred_image_psf2.png');

%% Quantitative comparison of results (e.g., Mean Squared Error)
% MSE calculation (ground truth vs deblurred images)
mse1 = mean((ground_truth(:) - deblurred1(:)).^2);
mse2 = mean((ground_truth(:) - deblurred2(:)).^2);
fprintf('\n');
fprintf('MSE for PSF1: %f\\n', mse1);
fprintf('MSE for PSF2: %f\\n', mse2);
save('mse_results.mat', 'mse1', 'mse2');

%% Generate codes using gene_code function
n = 12;
s = n / 2;
codes = gene_code(n, s);

% Normalize codes to represent PSFs
codes = codes ./ sum(codes, 1);

% Calculate spectral metrics for each code
min_values = zeros(1, size(codes, 2));
std_devs = zeros(1, size(codes, 2));

for i = 1:size(codes, 2)
    psf = codes(:, i);
    psd = abs(fft(psf, nfft)).^2;
    min_values(i) = min(psd);
    std_devs(i) = std(psd);
end

% Plot results
figure;
scatter(std_devs, min_values, 'filled');
xlabel('Standard Deviation of PSD');
ylabel('Minimum Value of PSD');
title('Spectral Metrics for Generated Codes');
saveas(gcf, 'code_metrics.png');


%% Part 4: Extended Analysis for First Co-Design Criterion (RAT06)
% Load the gene_code function
n = 20; % Length of the code
s = n / 2; % Number of '1's in the code
codes = gene_code(n, s); % Generate binary codes

% Normalize codes to represent valid PSFs
codes = codes ./ sum(codes, 1);

% Initialize arrays for spectral metrics
min_values = zeros(1, size(codes, 2));
std_devs = zeros(1, size(codes, 2));

% Compute spectral metrics for each code
nfft = 1024; % Zero-padding length
psds = zeros(nfft, size(codes, 2)); % Store all PSDs for visualization
for i = 1:size(codes, 2)
    psf = codes(:, i);
    psd = abs(fft(psf, nfft)).^2; % Compute PSD
    psds(:, i) = psd; % Store PSD for this code
    min_values(i) = min(psd); % Minimum value of PSD
    std_devs(i) = std(psd); % Standard deviation of PSD
end

% Plot scatter plot of standard deviation vs minimum PSD value
figure;
scatter(std_devs, min_values, 'filled');
xlabel('Standard Deviation of PSD');
ylabel('Minimum Value of PSD');
title('Spectral Metrics for Generated Codes');
grid on;
saveas(gcf, 'part4_code_metrics.png');

% Find the optimal code based on RAT06 criteria
[~, optimal_idx] = max(min_values ./ std_devs); % Maximize min(PSD)/std(PSD)
optimal_code_rat06 = codes(:, optimal_idx);

% Find the PSF with the lowest standard deviation and highest minimum PSD
[~, min_std_idx] = min(std_devs);
[~, max_min_idx] = max(min_values);

% Save and display these PSFs and their spectral densities
figure;
subplot(2, 1, 1);
stem(codes(:, min_std_idx), 'b', 'DisplayName', 'Lowest Std Dev PSF');
xlabel('Index');
ylabel('Value');
title('PSF with Lowest Std Dev');
grid on;

subplot(2, 1, 2);
semilogy(abs(fftshift(fft(codes(:, min_std_idx), nfft))).^2, 'r', 'DisplayName', 'PSD');
xlabel('Frequency Index');
ylabel('Power');
title('Spectral Density of Lowest Std Dev PSF');
grid on;
saveas(gcf, 'psf_lowest_std.png');


% flipped A
figure;
subplot(2, 1, 1);
stem(flip(codes(:, min_std_idx)), 'b', 'DisplayName', 'Lowest Std Dev PSF');
xlabel('Index');
ylabel('Value');
title('PSF with Lowest Std Dev');
grid on;

subplot(2, 1, 2);
semilogy(abs(fftshift(fft(flip(codes(:, min_std_idx)), nfft)).^2), 'r', 'DisplayName', 'PSD');
xlabel('Frequency Index');
ylabel('Power');
title('Spectral Density of Lowest Std Dev PSF');
grid on;
saveas(gcf, 'psf_lowest_std.png');


%%%%%%%%
figure;
subplot(2, 1, 1);
stem(flip(codes(:, max_min_idx)), 'b', 'DisplayName', 'Highest Min Value PSF');
xlabel('Index');
ylabel('Value');
title('PSF with Highest Min Value');
grid on;

subplot(2, 1, 2);
semilogy(abs(fftshift(fft(flip(codes(:, max_min_idx)), nfft))).^2, 'r', 'DisplayName', 'PSD');
xlabel('Frequency Index');
ylabel('Power');
title('Spectral Density of Highest Min Value PSF');
grid on;
saveas(gcf, 'psf_highest_min.png');



% flipped B

figure;
subplot(2, 1, 1);
stem(codes(:, max_min_idx), 'b', 'DisplayName', 'Highest Min Value PSF');
xlabel('Index');
ylabel('Value');
title('PSF with Highest Min Value');
grid on;

subplot(2, 1, 2);
semilogy(abs(fftshift(fft(codes(:, max_min_idx), nfft))).^2, 'r', 'DisplayName', 'PSD');
xlabel('Frequency Index');
ylabel('Power');
title('Spectral Density of Highest Min Value PSF');
grid on;
saveas(gcf, 'psf_highest_min_flipped.png');

% Randomly select and save 5 PSFs and their spectral densities
random_indices = randperm(size(codes, 2), 5);
for k = 1:5
    idx = random_indices(k);
    figure;
    subplot(2, 1, 1);
    stem(codes(:, idx), 'b', 'DisplayName', sprintf('Random PSF #%d', k));
    xlabel('Index');
    ylabel('Value');
    title(sprintf('Random PSF #%d', k));
    grid on;

    subplot(2, 1, 2);
    semilogy(abs(fftshift(fft(codes(:, idx), nfft))).^2, 'r', 'DisplayName', sprintf('PSD #%d', k));
    xlabel('Frequency Index');
    ylabel('Power');
    title(sprintf('Spectral Density of Random PSF #%d', k));
    grid on;

    saveas(gcf, sprintf('random_psf_%d.png', k));
end

%% Re-simulate Blurring and Deconvolution with Optimal PSF
% Load reference image
ground_truth = imread('boat_groundtruth.png');
ground_truth = im2gray(ground_truth); % Convert to grayscale
ground_truth = double(ground_truth) / 255; % Normalize to [0, 1]

% Blur with optimal PSF and add noise
sigma_b = 10 / 255; % Convert noise level to normalized range
optimal_blurred = imfilter(ground_truth, optimal_code_rat06, 'conv', 'circular') + ...
    sigma_b * randn(size(ground_truth));

figure;
imshow(optimal_blurred, []);
title('Blurred Image with Optimal PSF');
saveas(gcf, 'optimal_blurred_image.png');

% Wiener deconvolution
nsr_optimal = var(sigma_b) / var(optimal_code_rat06); % Noise-to-signal ratio
optimal_deblurred = deconvwnr(optimal_blurred, optimal_code_rat06, nsr_optimal);

figure;
imshow(optimal_deblurred, []);
title('Deblurred Image with Optimal PSF');
saveas(gcf, 'optimal_deblurred_image.png');


%%
mse1 = mean((ground_truth(:) - deblurred1(:)).^2);
mse2 = mean((ground_truth(:) - optimal_deblurred(:)).^2);
fprintf('\n');
fprintf('MSE for PSF1: %f', mse1);
fprintf('\n');
fprintf('MSE for optimal deblured: %f', mse2);
save('mse_results_part 4.mat', 'mse1', 'mse2');



%% Part 5: Second Co-Design Criterion (AR09)
%% Extended Part 5: Varying n and Normalized RSB Curves
%% RSB for the Example PSFs
% Extended Part 5: Using RSB as Defined in the TP
n_values = 12; % Values of n to iterate over
delta_t = 1e-3; % Time interval (1 ms)
C = 100; % Photon flux constant (photons per second)
sigma_e = 0.01; % Electronic noise variance
m = 320; % Scene length

calc_rsb= @(psf, s, n) (s * delta_t / n) / ...
    (sqrt(trace((convmtx(psf, m)' * convmtx(psf, m))^-1) / m) * ...
    sqrt(sigma_e^2 + (C * s / n)));

% Load example PSFs
psf1 = load('PSF1.txt');
psf2 = load('PSF2.txt');
psf1 = psf1 / sum(psf1); % Normalize
psf2 = psf2 / sum(psf2); % Normalize



% Calculate RSB
rsb_psf1 = calc_rsb(psf1,s,n)
rsb_psf2 = calc_rsb(psf2,s,n)
rsb_psf_optimal = calc_rsb(optimal_code_rat06,s,n)

rsb_0 = rsb_psf2;

fprintf('Delta RSB for PSF1: %.2f dB\n', 10*log(rsb_psf1) - 10 * log(rsb_0)) ;
fprintf('RSB for PSF2: %.2f dB\n', 10*log(rsb_psf2));
fprintf('Delta RSB for PSF_optimal: %.2f dB\n', 10*log(rsb_psf_optimal ) - 10 * log(rsb_0)) ;


% Function to calculate RSB for a given PSF
calc_rsb = @(psf, s, n) (s * delta_t / n) / ...
    (sqrt(trace((convmtx(psf, m)' * convmtx(psf, m))^-1) / m) * ...
    sqrt(sigma_e^2 + (C * s / n)));



% Initialize variables for plotting
all_curves = {}; % To store normalized curves for each n
legend_entries = {}; % To store legend labels

figure(40);
figure(50);% Create figure for normalized RSB curves
max_rsb_yet = 0;

for n_idx = 1:length(n_values)
    n = n_values(n_idx); % Current value of n
    s_values = 2:n-2; % Possible values of 's' for this n
    max_rsb_values = zeros(size(s_values)); % To store max RSB for each s

    % Iterate over s values to compute RSB
    for j = 1:length(s_values)
        s = s_values(j); % Current number of '1's
        codes = gene_code(n, s); % Generate binary codes
        codes = codes ./ sum(codes, 1); % Normalize codes

        % Calculate RSB for each code
        rsb_values = zeros(1, size(codes, 2));
        for i = 1:size(codes, 2)
            rsb_values(i) = calc_rsb(codes(:, i),s,n);
            if rsb_values(i) > max_rsb_yet
                 max_rsb_yet = rsb_values(i);
                 max_rsb_code = codes(:, i);
            end
        end

        % Store the maximum RSB value for this s
        max_rsb_values(j) = max(rsb_values)/rsb_0;
    end
    figure(40);
    plot(s_values, max_rsb_values, '-o', 'DisplayName', sprintf('n = %d', n));
    hold on;

    % Normalize x-axis for this curve
    normalized_x = linspace(2/n, (n-2)/n, length(s_values)); % x-axis from 0 to 1
    all_curves{n_idx} = [normalized_x; max_rsb_values]; % Store curve data
    
  
    figure(50);
    % Plot normalized curve
    plot(normalized_x, max_rsb_values, '-o', 'DisplayName', sprintf('n = %d', n));
    hold on;

    % Store legend entry
    legend_entries{end+1} = sprintf('n = %d', n);
end


figure(50);
% Add labels and legend
xlabel('s/n');
ylabel('Maximum Maximum \Delta RSB ');
title('Maximum \Delta RSB vs Normalized s for different n');
grid on;
legend(legend_entries, 'Location', 'Best');
saveas(gcf, 'part5_rsb_normalized.png');

% Compare results for all n
fprintf('Comparison of Maximum RSB Curves Across n:\n');
fprintf('Comparison of Maximum RSB Curves Across n:\n');
for n_idx = 1:length(n_values)
    n = n_values(n_idx);
    [max_rsb, max_idx] = max(all_curves{n_idx}(2, :)); % Get max RSB and its index
    fprintf('n = %d: max_Index = %d\n', n,  max_idx);
    % fprintf('n = %d: Max RSB = %.2f dB (Index = %d)\n', n, max_rsb, max_idx);
end


figure(40);
% Add labels and legend
xlabel('s');
ylabel('Maximum Maximum \Delta RSB ');
title('Maximum \Delta RSB vs s for different n');
grid on;
legend(legend_entries, 'Location', 'Best');
saveas(gcf, 'part5_rsb.png');

% Compare results for all n
fprintf('Comparison of Maximum RSB Curves Across n:\n');
fprintf('Comparison of Maximum RSB Curves Across n:\n');
for n_idx = 1:length(n_values)
    n = n_values(n_idx);
    [max_rsb, max_idx] = max(all_curves{n_idx}(2, :)); % Get max RSB and its index
    fprintf('n = %d: max_Index = %d\n', n,  max_idx);
    % fprintf('n = %d: Max RSB = %.2f dB (Index = %d)\n', n, max_rsb, max_idx);
end



%% Generate a Deblurred Image with AR09 Optimal Code
% Blur reference image with the AR09 optimal PSF
optimal_blurred_ar09 = imfilter(ground_truth, max_rsb_code, 'conv', 'circular') + ...
    sigma_b * randn(size(ground_truth));

figure;
imshow(optimal_blurred_ar09, []);

title('Blurred Image with AR09 Optimal PSF');
saveas(gcf, 'optimal_blurred_ar09.png');

% Wiener deconvolution
nsr_optimal_ar09 = var(sigma_b) / var(max_rsb_code); % Noise-to-signal ratio
optimal_deblurred_ar09 = deconvwnr(optimal_blurred_ar09, max_rsb_code, nsr_optimal_ar09);

figure;
imshow(optimal_deblurred_ar09, []);
title('Deblurred Image of the Optimal PSF with RSB criteria');
saveas(gcf, 'optimal_deblurred_ar09.png');

%% MSE calculation (ground truth vs deblurred images)
mse1 = mean((ground_truth(:) - optimal_deblurred(:)).^2);
mse2 = mean((ground_truth(:) - optimal_deblurred_ar09 (:)).^2);
fprintf('\n');
fprintf('MSE for optimal_deblurred: %f', mse1);
fprintf('\n');
fprintf('MSE for optimal_deblurred_ar09: %f', mse2);
save('mse_results.mat', 'mse1', 'mse2');


%%
figure;
subplot(2, 1, 1);
stem(flip(max_rsb_code), 'b', 'DisplayName', 'Highest Min Value PSF');
xlabel('Index');
ylabel('Value');
title('psf_best_RSB.png');
grid on;

subplot(2, 1, 2);
semilogy(abs(fftshift(fft (max_rsb_code, nfft))).^2, 'r', 'DisplayName', 'PSD');
xlabel('Frequency Index');
ylabel('Power');
title('Spectral Density of Highest Min Value PSF');
grid on;
saveas(gcf, 'Spectral_Density_best_RSB.png');






