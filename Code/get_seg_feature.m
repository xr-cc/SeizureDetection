function [featureOutput,labelOutput]=get_seg_feature(eegData,T_tilt,timeMax,seizureFlag,L,W,Fs)
% GET_SEG_FEATURE  Generate features and plot data for single segment.
% Usage:    [featureOutput,labelOutput]=get_seg_feature(eegData,T_tilt,timeMax,seizureFlag,L,W,Fs)
%           [featureOutput,labelOutput]=get_seg_feature(eegData,T_tilt,timeMax,seizureFlag,L,W)
% Inputs:   eegData         -EEG data of the segment
%           T_tilt          -time idx for first X_T_tilt
%           timeMax         -maximum time idx 
%           seizureFlag     -1 for seizure and 0 for non-seizure
%           L               -interval length
%           W               -number of intervals
%           Fs(opt)         -sample rate (default:256)
% Outputs:  featureOutput   -M*chN*W*T feature matrix
%           labelOutput     -1*T label vector
% Note:     used function: get_energy()

if nargin < 7
    Fs = 256;
end

featureOutput = [];
labelOutput = [];
featureIdx = 1;

while (T_tilt<=timeMax-L)
    epoch_count = 1;
    W_epoch_energy = [];
    for k = 1:W % loop through each of W epochs (L-second long)
        epoch_startT = T_tilt-(W-k+1)*L;
        epoch_endT = epoch_startT+L;
        % porcess data
        epoch_energy = get_energy(eegData(:,(epoch_startT*Fs+1):epoch_endT*Fs));
        % concatenate W_epoch_energy: M*N*W
        W_epoch_energy(:,:,epoch_count) = epoch_energy;
        epoch_count = epoch_count+1;
    end

    % append to feature and label output
    featureOutput(:,:,:,featureIdx) = W_epoch_energy;
    labelOutput(featureIdx) = seizureFlag;
    featureIdx = featureIdx+1;

    % increment
    T_tilt  = T_tilt+1;   
end
end