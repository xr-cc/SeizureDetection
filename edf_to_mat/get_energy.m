function X_T = get_energy(data_seg,Fs,M,lf,uf)
% Input  - data_seg: segment of data
%        - M: number of bands (8)
%        - Fs: sample rate
%        - lf~hf: frequency range (0.5~24Hz)
% Output - X_T: MxchN matrix (chN is number of channels)
if nargin < 5
    uf = 24;
end
if nargin < 4
    lf = 0.5;
end
if nargin < 3
    M = 8;
end
if nargin < 2
    Fs = 256;
end

x = data_seg;
[chN,N] = size(x);
X = fft(x);

Xmag = abs(X);
% Xmag(:,1) = 0; % set DC component to 0
% Xmag = bsxfun(@rdivide,Xmag,sum(Xmag)); % normalize channel
% X = X(1:N/2+1);
fax = [0:N-1]*Fs/N; % ftemprequency range in Hertz

% power spectrum: magnitude squared 
Xmag = (1/(Fs*N)) * abs(X).^2;

% frequency bands
lvl = linspace(max(lf-0.5,0),uf+0.5,M+1);   % frequency levels in Hz +/-0.5
lseg = round(N/Fs*lvl)+1;    % segments corresponding to frequency bands
    
X_T = zeros(chN, length(lvl)-1); % 1 for single channel
for n=1:length(lvl)-1
    X_T(:,n) = 2*sum(Xmag(:,lseg(n):lseg(n+1)),2);
end
X_T = X_T';
end