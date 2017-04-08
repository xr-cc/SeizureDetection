function plotEEG(plot_count,data,channels,startTime,Fs)
% PLOTEEG  Plot EEG data.
% Usage:    plotEEG(plot_count,data,channels,startTime,Fs)
%           plotEEG(plot_count,data,channels)
% Inputs:   plot_count      -idx for plot
%           data            -EEG data
%           channels        -corresponding channel names
%           startTime(opt)  -starting time of data (default:0)
%           Fs(opt)         -sample rate (default:256)

if nargin < 5
    Fs = 256;
end
if nargin < 4
    startTime = 0;
end

[num_chn,num_point] = size(data);
mi = min(data,[],2);
ma = max(data,[],2);
width = max(abs(ma(1:end-1))+abs(mi(2:end)));
shift = (linspace(0,width*(num_chn-1),num_chn))';
shift = repmat(shift,1,num_point);
% t = (1:num_point)/Fs+baseTime+ta;
t = (1:num_point)/Fs+startTime;

figure(plot_count)
plot(t,data+shift)
% edit axes
set(gca,'ytick',mean(data+shift,2),'yticklabel',channels)
grid on
ylim([mi(1)-width max(max(shift+data))+width])
title(['EEG Data']);
ylabel('Channels')
xlabel('Time')

end