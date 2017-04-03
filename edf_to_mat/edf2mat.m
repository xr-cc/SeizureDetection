function labelInOrder = edf2mat(patientID,fileID,channels)
% EDF2MAT  Transform edf. file to mat. file and save it under ../Data/.
% Usage:    labelInOrder = edf2mat(patientID,fileID)
%           labelInOrder = edf2mat(patientID,fileID,channels) 
% Inputs:   patientID       -char array of patient ID
%           fileID          -char array of file ID
%           channels(opt)   -cell array of user-specified channels to be used
% Outputs:  labelInOrder    -array of names of channels used in order

% default channels to be used
if nargin < 3
  channels = {'FP1F7','F7T7','T7P7','P7O1','FP1F3','F3C3',...
    'C3P3','P3O1', 'FP2F4','F4C4','C4P4','P4O2',...
    'FP2F8','F8T8','T8P8','P8O2','FZCZ','CZPZ'};
end

%%
% addpath('D:/Data/Scalp EEG data/physionet.org/pn6/chbmit/chb01/');
addpath(['../Data/chb',patientID,'/']);
N = [patientID,'_',fileID];
f = ['chb',N];
filename = [f,'.edf'] % e.g. 'chb01_01.edf';
[hdr,rec]= edfread(filename);
D = rec;
 
%%
labels = hdr.label; % all channels provided by data
channels_used = ismember(labels,channels); % indices of channels used
used_channels = labels(channels_used); % channels used
% used channels and their corresponding indices
[A I] = unique(used_channels);
% not_used_channels = labels(~channels_used);
% not_used_idx = find(~channels_used);
used_idx = I;
% D(not_used_idx,:) = [];
% D(5,:)=[];D(10-1,:)=[];D(13-2,:)=[];D(18-3,:)=[];D(23-4,:)=[];
D = D(used_idx,:); %follow the order in A
% SNchb01_01 = D-D(1,2);
A = A';
varname = matlab.lang.makeValidName(['SN',f]);
eval([varname '= {A,D-D(1,2)};']);
fileName = ['SN',f,'.mat'];
savePath = ['../Data/chb',patientID,'mat'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
save([savePath,'/',fileName],['SN',f]);
labelInOrder=A;
end