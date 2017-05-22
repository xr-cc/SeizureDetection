%%
clear; clc
%num2str([0:20].','%02d')

patient = '01';
S=sprintf('Reading Summary of Patient %s ...',patient);
disp(S);
path = ['../Data/chb',patient,'/'];
addpath(path);
summaryfile = ['chb',patient,'-summary.txt']; %chbxx-summary.txt

%% store information
info = [];

%% read file line by line
fid = fopen(summaryfile,'r');
tline = fgets(fid);
while ischar(tline)
    str = tline;
    seg = [];
    namePattern = 'File Name';
    if (strfind(str,namePattern))
        elems = regexp(str, '(\d+)_(\d+)', 'tokens');        
        patientID = elems{1}(1);
        fileID = elems{1}(2);
        seg = [seg,[patientID,fileID]]; 
        tline = fgets(fid);
        str = tline;
        startTimePattern = 'File Start Time';
        if (strfind(str,startTimePattern))
            elems = regexp(str, '(\d+\:\d+\:\d+)', 'tokens');
            startTime = elems{1};
            seg = [seg, startTime]; 
        end
        tline = fgets(fid);
        str = tline;
        endTimePattern = 'File End Time';
        if (strfind(str,endTimePattern))
            elems = regexp(str, ': (\d+\:\d+\:\d+)', 'tokens');
            endTime = elems{1};
            seg = [seg, endTime]; 
        end
        tline = fgets(fid);
        str = tline;
        seizureInd = 'Seizures';
        if (strfind(str,seizureInd))
            elems = regexp(str, ': (\d+)', 'tokens');
            num = str2double(elems{1});
            seg = [seg, num]; 
        end
        
    end
%     disp(seg)
    info = [info; seg];
    tline = fgets(fid);
end
fclose(fid);
% N = '01_01';
% f = ['chb',N];
% filename = [f,'.edf']

%% read from summary
