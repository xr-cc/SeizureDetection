fs = 256; % sampling rate
freq = 24;

file = load('SNchb01_01.mat');
fName = fieldnames(file);
eegData = file.(fName{1});
[nc,nt] = size(eegData)
channel = eegData(9,:);

%% single chanel process
N=length(channel);
fx=fft(channel)/N;
f=(0:N-1)*fs/N;
figure(1);
plot(f(1:end/2),10*log10(abs(fx(1:end/2))));
% Find the power spectrum at each frequency bands
    chfft = abs(fftshift(fft(channel)));                  % take FFT of each channel
    chfft(:,1) = 0;                             % set DC component to 0
    chfft = bsxfun(@rdivide,chfft,sum(chfft)); 
    figure(2);
    plot((1:length(chfft)),chfft);
    
    %frequency
    dF = fs/N;
    f2 = -fs/2:dF:fs/2-dF;
    %plot
    figure(3)
    plot(f,abs(chfft)/N);
    xlabel('Frequency (in hertz)');
    title('Magnitude Response');
    
    %another version
%     t = fft(channel);
%     z=ifft(t);
%     figure; plot(abs(t))
%     figure; plot(real(t))
%     figure; plot(imag(t))
    
%% plot eeg data
% sig = eegData;
% mi = min(sig,[],2); 
% ma = max(sig,[],2);
% shift = cumsum([0; abs(ma(1:end-1))+abs(mi(2:end))]);
% shift = repmat(shift,1,size(sig,2));
% t = linspace (0,2,size(sig,2));
% plot(t,sig+shift)

%% fourier transform
% fftsig = abs(fft(eegData));
% fftsig = fftshift(fftsig);
% plot(fftsig)

