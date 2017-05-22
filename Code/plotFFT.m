function plotFFT(plot_count,chData,lf,uf,Fs)
% PLOTFFT  Plot FFT of data (single channel).
% Usage:    plotFFT(plot_count,chData,fa,fb,Fs)
%           plotFFT(plot_count,chData)
% Inputs:   plot_count      -idx for plot
%           chData          -single channel data
%           lf(opt)         -lower bound of frequency range (default:0)
%           uf(opt)         -upper bound of frequency range (default:256)
%           Fs(opt)         -sample rate (default:256)

if nargin < 5
    Fs = 256;
end
if nargin < 4
    uf = 256;
end
if nargin < 3
    lf = 0;
end

x = chData(1,:); % time segment
N = length(x);
X = fft(x);
fax = [0:N-1]*Fs/N; % frequency range in Hertz
fax_picked = fax(lf/Fs*N+1:uf/Fs*N);
X_picked = X(lf/Fs*N+1:uf/Fs*N);
dB = mag2db(abs(X_picked));

figure(plot_count)
plot(fax_picked,dB); % plot fft 
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title(['FFT of EEG data']);
grid on

end