% example of selecting certain channels when transfering edf to mat
%%
clear; clc
% addpath('D:/Data/Scalp EEG data/physionet.org/pn6/chbmit/chb01/');
addpath('../Data/chb01/');
% filename = 'chb01_01.edf';
N = '01_01';
f = ['chb',N];
filename = [f,'.edf']
[hdr,rec]= edfread(filename);
D = rec;
 
%%
% channels used
labels = hdr.label;
% 
channels = {'FP1F7','F7T7','T7P7','P7O1','FP1F3','F3C3','C3P3','P3O1', 'FP2F4','F4C4','C4P4','P4O2','FP2F8','F8T8','T8P8','P8O2','FZCZ','CZPZ'};
channels_used = ismember(labels,channels);
used_channels = labels(channels_used);
[A I] = unique(used_channels);
not_used_channels = labels(~channels_used);
% not_used_idx = find(~channels_used);
used_idx = I;
% D(not_used_idx,:) = [];
% D(5,:)=[];D(10-1,:)=[];D(13-2,:)=[];D(18-3,:)=[];D(23-4,:)=[];
D = D(used_idx,:); %follow the order in A
SNchb01_01 = D-D(1,2);
fileName = ['SN',f,'.mat'];
save(fileName,['SN',f])