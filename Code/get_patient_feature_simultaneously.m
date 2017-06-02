% Generate features and corresponding labels at the same time.
% Generated Files:  SNchb(xx)features0.mat 
%                   SNchb(xx)labels0.mat
%                   SNchb(xx)nsidx0.mat (beginning indicies of each non-seizure data segment)
%                   SNchb(xx)sidx0.mat (beginning indicies of each seizure data segment)
% Used Functions:   time2sec(), get_energy(),
patientID = '01'

H = 1;    % default hours of non-seizure data % currently not used
S = 20;   % default seconds into seizure
W = 3;    % default number of intervals
L = 2;    % default interval length 
Fs = 256; % default sample rate
pre_seizure = 10; % time before seizure onset

%%
features = [];
labels = [];

%% load data
filePath = ['../Data/chb',patientID,'mat'];
seizureFlags = [];
patIDs = {};
segIDs = {};
startTs = {};
endTs = {};
seizureInfos = {};
% summary
summaryFile = [filePath,'/','SNchb',patientID,'summary']
summary = load(summaryFile);
[nseg,ninfo] = size(summary.info);
num_nonseizure = 0;

for i = 1:nseg
    patIDs = [patIDs,summary.info{i,1}];
    segIDs = [segIDs,summary.info{i,2}];
    startTs = [startTs,summary.info{i,3}];
    endTs = [endTs,summary.info{i,4}];
    seizureFlags = [seizureFlags,summary.info{i,5}];
    if summary.info{i,5}==0
        num_nonseizure = num_nonseizure+1;
    end
    seizureInfos = [seizureInfos,summary.info{i,6}];
end

% length of non-seizure data segment
time_nonseizure = H*3600;
time_per_nonseizure = ceil(time_nonseizure/num_nonseizure);

ns_seg_indices = [];
ns_count = 0;
s_seg_indices = [];
s_count = 0;

% process each file
num_segs = length(segIDs)
for seg_i = 1:num_segs
try
    %% load data from file
    patID = char(patIDs(seg_i));
    segID = char(segIDs(seg_i));
    idx = seg_i
    fileName = ['SNchb',patID,'_',segID,'.mat']
    file = load([filePath,'/',fileName]);
    fName = fieldnames(file);
    channels = (file.(fName{1}){1})';
    eegData = file.(fName{1}){2};

    if sum(any(isnan(eegData),1))~= 0
        disp('input eegdata NaN');
    end

    %% seizure or non-seizure
     if seizureFlags(idx)==0 % non-seizure    
        disp('Non-Seizure');
        baseT = time2sec(startTs{idx});
        startT = 0;
        endT = time2sec(endTs{idx})-baseT;
        if endT<startT 
            endT = endT+time2sec('24:00:00');
        end   
        % randomly select a segment
        range = endT-startT-time_per_nonseizure-W*L;
        if range<0
            range = 1;
        end
        T_rand = double(randi(range));
        a = W*L+T_rand;
        b = min(a+double(time_per_nonseizure)-1,endT);
        if b<0
            b = a+double(time_per_nonseizure)-1;
        end
        data_idx = 1;
        seg_start_idx = length(labels)+data_idx;
        while (a<=b)
            epoch_count = 1;
            W_epoch_energy = [];
            for k = 1:W % loop through each of W epochs (L-second long)
                epoch_startT = a-(W-k+1)*L;
                epoch_endT = epoch_startT+L;
                % process data
                epoch_energy = get_energy(eegData(:,(epoch_startT*Fs+1):epoch_endT*Fs));
                % concatenate W_epoch_energy: M*N*W
                W_epoch_energy(:,:,epoch_count) = epoch_energy;
                epoch_count = epoch_count+1;
            end
            % append to feature and label output
            features = cat(4, features, W_epoch_energy);
            labels = [labels,0];
            data_idx = data_idx+1;
            % increment
            a  = a+1;   
        end
        seg_end_idx = seg_start_idx+data_idx-2;
        ns_seg_indices = [ns_seg_indices,[seg_start_idx;seg_end_idx]];       
        ns_count = ns_count + data_idx - 1;       

     else % seizure            
         disp('Seizure');
         sInfo = seizureInfos{idx};
         seizureI = fieldnames(sInfo);
         for j = 1:length(seizureI)
            seizurePeriod = sInfo.(seizureI{j});
            seizureStart = seizurePeriod{1};
            seizureEnd = seizurePeriod{2};
            % also take 10s non-seizure data before onset
            a = max(seizureStart-pre_seizure,W*L);
            b = min(seizureEnd,seizureStart+S-1);
            
            data_idx = 1;
            seg_start_idx = length(labels)+data_idx;
            while (a<=b)%-L
                epoch_count = 1;
                W_epoch_energy = [];
                for k = 1:W % loop through each of W epochs (L-second long)
                    epoch_startT = a-(W-k+1)*L;
                    epoch_endT = epoch_startT+L;
                    % process data
                    epoch_energy = get_energy(eegData(:,(epoch_startT*Fs+1):epoch_endT*Fs));
                    % concatenate W_epoch_energy: M*N*W
                    W_epoch_energy(:,:,epoch_count) = epoch_energy;
                    epoch_count = epoch_count+1;
                end
                % append to feature and label output
                features = cat(4, features, W_epoch_energy);
                if (epoch_endT>=seizureStart) && (epoch_endT<=seizureEnd)
                    seizureFlag = 1;
                else
                    seizureFlag = 0;
                end
                labels = [labels,seizureFlag];
                data_idx = data_idx+1;
                % increment
                a  = a+1;   
            end
            seg_end_idx = seg_start_idx+data_idx-2;
            s_seg_indices = [s_seg_indices,[seg_start_idx;seg_end_idx]];       
            s_count = s_count + data_idx - 1;      
         end
         
     end
catch ME
    disp([segID,'ERROR!'])
end
end
% labels: 1*T
% features: M*chN*W*T

%% save feature and label
savePath = ['../Feature/chb',patientID,'feature'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
featureFileName = ['SNchb',char(patientID),'features0.mat'];
save([savePath,'/',featureFileName],'features');
labelFileName = ['SNchb',char(patientID),'labels0.mat'];
save([savePath,'/',labelFileName],'labels');
nsidxFileName = ['SNchb',char(patientID),'nsidx0.mat'];
save([savePath,'/',nsidxFileName],'ns_seg_indices');
sidxFileName = ['SNchb',char(patientID),'sidx0.mat'];
save([savePath,'/',sidxFileName],'s_seg_indices');

disp('total number of non-seizure data(s)')
disp(ns_count)
disp('total number of seizure data(s)')
disp(s_count)
