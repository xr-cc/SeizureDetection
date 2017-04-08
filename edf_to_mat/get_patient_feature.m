function [features,labels] = get_patient_feature(patientID,Fs,L,W,S,H,Hmulti)
% GET_PATIENT_FEATURE  Generate features from all files of a patient and save to file.
% Usage:    [features,labels] = get_patient_feature(patientID,Fs,L,W,S,H,Hmulti)
%           [features,labels] = get_patient_feature(patientID)
%           plotEEG(plot_count,data,channels)
% Inputs:   patientID       -char array of patient ID
%           Fs(opt)         -sample rate (default:256)
%           L(opt)          -interval length (default:2)
%           W(opt)          -number of intervals (default:3)
%           S(opt)          -seconds into seizure of data taken (default:20)
%           H(opt)          -hours of non-seizure data needed (default:1)
%           Hmulti(opt)     -multiples of non-seizure data taken with H equally 
%                            spread to each file (default:10; 0 for taking all data)
% Outputs:  features        -M*chN*W*T feature matrix
%           labels          -1*T label vector
% Note:     used function: get_seg_feature(), time2sec()

%% default value for optinal arguments
if nargin < 7
  Hmulti = 10;    
end
if nargin < 6
  H = 1;    % default hours of non-seizure data % currently not used
end
if nargin < 5
  S = 20;   % default seconds into seizure
end
if nargin < 4
  W = 3;    % default number of intervals
end
if nargin < 3
  L = 2;    % default interval length 
end
if nargin < 2
  Fs = 256; % default sample rate
end

%%
features = [];
labels = [];
featureIdx = 1;

%% load data
filePath = ['../Data/chb',patientID,'mat'];
labels = [];
segIDs = {};
startTs = {};
endTs = {};
seizureInfos = {};
% summary
summaryFile = [filePath,'/','SNchb',patientID,'summary']
summary = load(summaryFile);
[nseg,ninfo] = size(summary.info);

for i = 1:nseg
    segIDs = [segIDs,summary.info{i,2}];
    startTs = [startTs,summary.info{i,3}];
    endTs = [endTs,summary.info{i,4}];
    labels = [labels,summary.info{i,5}];
    seizureInfos = [seizureInfos,summary.info{i,6}];
end
% baseTime = time2sec(startTs{1}); % starting time
% t = [];
% data = [];

time_nonseizure = H*3600;
num_nonseizure = nseg-sum(labels);
time_per_nonseizure = int8(time_nonseizure/num_nonseizure)*Hmulti;

for segID = segIDs
    % index of specified segment
    idx = find(strcmp(segIDs,segID));
    % load data from file
    segID = char(segID)
    fileName = ['SNchb',patientID,'_',segID,'.mat'];
    file = load([filePath,'/',fileName]);
    fName = fieldnames(file);
    channels = (file.(fName{1}){1})';
    eegData = file.(fName{1}){2};

    %% seizure or non-seizure
     if labels(idx)==0 % non-seizure    
        disp('Non-Seizure');
        baseT = time2sec(startTs{idx});
        startT = 0;
        endT = time2sec(endTs{idx})-baseT;
        if endT<startT % one day more
            endT = endT+time2sec('24:00:00');
        end
%         timeMin = startT;
%         timeMax = endT; %TODO!!!
        if Hmulti==0
            timeMax = endT;
        else
            timeMax = min(startT+time_per_nonseizure,endT);
        end
        T_tilt = W*L; % time idx for first X_T_tilt
        [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,T_tilt,timeMax,0,L,W,Fs);
        features = cat(4, features, segFeatureOutput);
        labels = [labels,segLabelOutput];

     else % seizure   
         disp('Seizure')
         sInfo = seizureInfos{idx};
         seizureI = fieldnames(sInfo);
         for j = 1:length(seizureI)
            seizurePeriod = sInfo.(seizureI{j});
            seizureStart = seizurePeriod{1};
            seizureEnd = seizurePeriod{2};
            % energy band
            timeMax = min(seizureEnd,seizureStart+S);
            T_tilt = seizureStart+L; % time idx for first X_T_tilt
            [segFeatureOutput,segLabelOutput]=get_seg_feature(eegData,T_tilt,timeMax,1,L,W,Fs);
            features = cat(4, features, segFeatureOutput);
            labels = [labels,segLabelOutput];
         end

     end
end
% labelOutput: 1*T
% featureOuput: M*chN*W*T

%% save feature and label
savePath = ['../Feature/chb',patientID,'feature'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
% info = num2cell(info)
featureFileName = ['SNchb',char(patientID),'features.mat'];
save([savePath,'/',featureFileName],'features')
labelFileName = ['SNchb',char(patientID),'labels.mat'];
save([savePath,'/',labelFileName],'labels')

end
