function labelInOrder = edf2mat(patientID,fileID,channels)
% EDF2MAT  Transform edf. file to mat. file and save it under ../Data/.
% Usage:    edf2mat(patientID,fileID,channels(opt))
%           labelInOrder = edf2mat(patientID,fileID)
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
numID = regexp(patientID, '(\d+)', 'tokens');
numID = char(numID{1});
addpath(['../Data/chb',numID,'/']);
N = [patientID,'_',fileID];
f = ['chb',N];
filename = [f,'.edf'] % e.g. 'chb01_01.edf';
[hdr,rec]= edfread(filename);
D = rec;
% remove all rows with NAN data
cut = ~any(isnan(D),2);
D(find(cut==0),:)=[];
 
%%
labels = hdr.label; % all channels provided by data
labels((find(cut==0)))=[]; % removing corresponding labels of NAN data
channels_used = ismember(labels,channels); % indices of channels used
used_channels = labels(channels_used); % channels used
[A I] = unique(used_channels); % used channels and corresponding indices
% not_used_channels = labels(~channels_used);
% not_used_idx = find(~channels_used);
used_idx = I;
D = D(used_idx,:); % follow the order in A
A = A';
varname = matlab.lang.makeValidName(['SN',f]);
eval([varname '= {A,D-D(1,2)};']); %e.g. SNchb01_01 = D-D(1,2);
%%
fileName = ['SN',f,'.mat'];
savePath = ['../Data/chb',numID,'mat'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
save([savePath,'/',fileName],['SN',f]);
labelInOrder=A;
end