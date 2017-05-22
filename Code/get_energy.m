function bandsEnergy = get_energy(data_seg,Fs,M,lf,uf,overlap)
% GET_ENERGY  Compute bandwidth-energy of provided data.
% Usage:    bandsEnergy = get_energy(data_seg)
%           bandsEnergy = get_energy(data_seg,Fs,M,lf,uf)
% Inputs:   data_seg    -segment of data (chN x (T*Fs)) 
%           Fs(opt)     -sample rate (default:256)
%           M(opt)      -number of bands (default:8)
%           lf(opt)     -lower bound of frequency range (default:0)
%           uf(opt)     -upper bound of frequency range (default:24)
%           overlap(opt)-overlap (in Hz) of bands next ot each other
% Outputs:  bandsEnergy -M x chN matrix (chN: number of channels)

if nargin < 6
    overlap = 0;
end
if nargin < 5
    uf = 24;
end
if nargin < 4
    lf = 0;
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
% Xmag = abs(X);
% Xmag(:,1) = 0; % set DC component to 0
% X = X(1:N/2+1);
fax = [0:N-1]*Fs/N; % ftemprequency range in Hertz

% power spectrum: magnitude squared 
Xmag = (1/(Fs*N)) * abs(X).^2;

% frequency bands
lvl = linspace(max(lf-overlap,0),min(uf+overlap,Fs),M+1);   % frequency levels in Hz +/-overlap
lseg = round(N/Fs*lvl)+1;    % segments corresponding to frequency bands
    
bands = zeros(chN, length(lvl)-1); % 1 for single channel
for n=1:length(lvl)-1
    bands(:,n) = 2*sum(Xmag(:,lseg(n):lseg(n+1)),2);
end
bandsEnergy = bands';
end