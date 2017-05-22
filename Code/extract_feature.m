function [features,labels]=extract_feature(patientID,Fs,L,W,S,H)
% Note:     used function: time2sec(), get_energy()

%% default value for optinal arguments
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
featureOutput = [];
labelOutput = [];
featureIdx = 1;

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
[nseg,ninfo] = size(summary.info);

% number of time segments of data to use
nsegUsed = nseg;

for i = 1:nsegUsed
    segIDs = [segIDs,summary.info{i,2}];
    startTs = [startTs,summary.info{i,3}];
    endTs = [endTs,summary.info{i,4}];
    labels = [labels,summary.info{i,5}];
    seizureInfos = [seizureInfos,summary.info{i,6}];
end
baseTime = time2sec(startTs{1}); % starting time
t = [];
data = [];

for i = 1:nsegUsed
%     i
    %% load data from file
    segID = segIDs{i};
    fileName = ['SNchb',patientID,'_',segID,'.mat'];
    file = load([filePath,'/',fileName]);
    fName = fieldnames(file);
    channels = (file.(fName{1}){1})';
    eegData = file.(fName{1}){2};
%     idx = find(strcmp(channels,targetChan));
%     chanData = eegData(idx,:);
%     data = [data, chanData];
    
    if labels(i)==0
    %% non-seizure        
        baseT = time2sec(startTs{i});
        startT = 0;
        endT = time2sec(endTs{i})-baseT;
        if endT<startT % one day more
            endT = endT+time2sec('24:00:00');
        end
        timeMin = startT;
%         timeMax = min(startT+H*3600,endT);
        timeMax = endT;
        T_tilt = W*L; % time idx for first X_T_tilt        
        while (T_tilt<=timeMax-L)
            epoch_count = 1;
            W_epoch_energy = [];
            for k = 1:W % loop through each of W epochs (L-second long)
                epoch_startT = T_tilt-(W-k+1)*L;
                epoch_endT = epoch_startT+L;
                % porcess data
                epoch_energy = get_energy(eegData(:,(epoch_startT*Fs+1):epoch_endT*Fs));
                % concatenate
                W_epoch_energy(:,:,epoch_count) = epoch_energy;
                epoch_count = epoch_count+1;
            end            
            % W_epoch_energy: M*N*W
            
            % append to feature and label output
            featureOutput(:,:,:,featureIdx) = W_epoch_energy;
            labelOutput(featureIdx) = labels(i);
            featureIdx = featureIdx+1;
            
            % increment
            T_tilt  = T_tilt+1;
        end
    else
    %% seizure
        % first S seconds
        seizureInfo = seizureInfos{i};
        seizureI = fieldnames(seizureInfo);
        for j = 1:length(seizureI)
            seizurePeriod = seizureInfo.(seizureI{j})
            seizureStart = seizurePeriod{1};
            seizureEnd = seizurePeriod{2};              
            
            baseT = time2sec(startTs{i})+seizureStart-(W-1)*L;
            timeMin = baseT;
            timeMax = min(seizureEnd,seizureStart+S);
            
            T_tilt = seizureStart+L; % time idx for first X_T_tilt
            while (T_tilt<=timeMax-L)
                epoch_count = 1;
                W_epoch_energy = [];
                for k = 1:W % loop through each of W epochs (L-second long)
                    epoch_startT = T_tilt-(W-k+1)*L;
                    epoch_endT = epoch_startT+L;
                    % porcess data
                    epoch_energy = get_energy(eegData(:,(epoch_startT*Fs):epoch_endT*Fs));
                    % concatenate
                    W_epoch_energy(:,:,epoch_count) = epoch_energy;
                    epoch_count = epoch_count+1;
                end
                % W_epoch_energy: M*N*W
            
                % append to feature and label output
                featureOutput(:,:,:,featureIdx) = W_epoch_energy;
                labelOutput(featureIdx) = labels(i);
                featureIdx = featureIdx+1;
                
                % increment
                T_tilt  = T_tilt+1;
            end            
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
featureFileName = ['SNchb',char(patientID),'feature.mat'];
save([savePath,'/',featureFileName],'featureOutput')
labelFileName = ['SNchb',char(patientID),'label.mat'];
save([savePath,'/',labelFileName],'labelOutput')


end