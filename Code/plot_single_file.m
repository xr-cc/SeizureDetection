function [eegData]=plot_single_file(patientID,segID,Fs)
% EXTRACT_SINGLE_FILE  Plot and save EEG data of a single file.
%                      (If seizure, also plot EEG data around seizure onset.)
%                      (Figure will be closed automatically.)
% Usage:    [eegData,featureOutput,labelOutput]=extract_single_file(patientID,segID,Fs)
%           [eegData,featureOutput,labelOutput]=extract_single_file(patientID,segID)
% Inputs:   patientID       -char array of patient ID
%           segID           -char array of segment (file) ID
%           Fs(opt)         -sample rate (default:256)
% Outputs:  eegData         -EEG Data

%% default value for optinal arguments
if nargin < 3
  Fs = 256; % sample rate
end

%% load data
filePath = ['../Data/chb',patientID,'mat'];
labels = [];
segIDs = {};
startTs = {};
endTs = {};
seizureInfos = {};
% summary
summaryFile = [filePath,'/','SNchb',patientID,'summary'];
summary = load(summaryFile);
[nseg,~] = size(summary.info);

for i = 1:nseg
    segIDs = [segIDs,summary.info{i,2}];
    startTs = [startTs,summary.info{i,3}];
    endTs = [endTs,summary.info{i,4}];
    labels = [labels,summary.info{i,5}];
    seizureInfos = [seizureInfos,summary.info{i,6}];
end
baseTime = time2sec(startTs{1}); % starting time

% index of specified segment
idx = find(strcmp(segIDs,segID));
% load data from file
fileName = ['SNchb',patientID,'_',segID,'.mat'];
file = load([filePath,'/',fileName]);
fName = fieldnames(file);
channels = (file.(fName{1}){1})';
eegData = file.(fName{1}){2};

%% PARAMETERS
% EEG
% relative starting and ending time
ta = 1/Fs;
tb = size(eegData,2)/Fs-1;
plot_count = 0;

%% plot EEG data (of specified time range)
data = eegData(:,ta*Fs:tb*Fs);
plot_count = plot_count+1;
fig = plotEEG(plot_count,data,channels);
hold on
title(['EEG Data of ',patientID,'\_',segID]);
fig_save_path = ['..\Measurements\plots\',patientID];
if ~exist(fig_save_path, 'dir')
  mkdir(fig_save_path);
end

%% seizure or non-seizure
 if labels(idx)==0 % non-seizure    
    disp('Non-Seizure');
    
 else % seizure   
     disp('Seizure')
     sInfo = seizureInfos{idx};
     seizureI = fieldnames(sInfo);
     for j = 1:length(seizureI)
        seizurePeriod = sInfo.(seizureI{j});
        seizureStart = seizurePeriod{1};
        seizureEnd = seizurePeriod{2};
        line([seizureStart seizureStart],get(gca,'YLim'),'Color','r');
        line([seizureEnd seizureEnd],get(gca,'YLim'),'Color','r');
        hold off
     end
     for j = 1:length(seizureI)
        seizurePeriod = sInfo.(seizureI{j});
        seizureStart = seizurePeriod{1};
        seizureEnd = seizurePeriod{2};
        
        % plot EEG data around seizure onset
        ta = seizureStart-20;
        tb = seizureEnd+20;
        data = eegData(:,ta*Fs:tb*Fs);       
        plot_count = plot_count+1;
        s = plotEEG(plot_count,data,channels,ta);
        hold on 
        line([seizureStart seizureStart],get(gca,'YLim'),'Color','r');
        line([seizureEnd seizureEnd],get(gca,'YLim'),'Color','r');
        title(['EEG Data of ',patientID,'\_',segID,' (Seizure Onset: ',num2str(seizureStart),', Offset: ',num2str(seizureEnd),')']);
        print(s,[fig_save_path,'\',patientID,segID,'s',num2str(j)],'-dpng');       
        hold off          
        close(s);
     end    
 end

print(fig,[fig_save_path,'\',patientID,segID],'-dpng');
close(fig)

end