% example of transfering edf to mat
%%
clear; clc
addpath('D:/Data/Scalp EEG data/physionet.org/pn6/chbmit/chb01/');
% filename = 'chb12_19.edf';
N = '01_01';
f = ['chb',N];
filename = [f,'.edf'];
[hdr,rec]= edfread(filename);
D = rec;
 
%%
D(5,:)=[];D(10-1,:)=[];D(13-2,:)=[];D(18-3,:)=[];D(23-4,:)=[];
SNchb12_34 = D-D(1,2);

fileName = ['SN',f,'.mat'];
save(fileName,['SN',f])