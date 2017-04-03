function [labels,info] = process_patient(patient,processFlag)
% PROCESS_PATIENT  Process edf files of a specified patient and save them properly.
% Usage:    process_patient(patient)
%           labels = process_patient(patient)
%           [labels,info] = process_patient(patient)
% Inputs:   patient         -char array of patient ID
%           processFlag(opt)-process files or not (default: false)
% Outputs:  labelInOrder    -array of names of channels used in order
%           info            -matrix of all infomation read for the patient 
%                            of format:
%                            [patientID,fileID,startTime,endTime,seizure,seizureInfo],
%                            where seizureInfo is [1x1 struct] with fields
%                            Seizure1, Seizure2, etc. (if ever), which
%                            contain 1x2 cell of seizure onset and end time.                            
% Note:     used function: edf2mat()

%num2str([0:20].','%02d')
if nargin < 2
  processFlag = false;
end

labels = '' % default value if not processing file

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
    seg = []; % to store info of current segment of data (or, file)
    % File Name
    namePattern = 'File Name';
    if (strfind(str,namePattern))
        elems = regexp(str, '(\d+)_(\d+)', 'tokens');        
        patientID = elems{1}(1);
        fileID = elems{1}(2);
        %% process file of each time segment if processFlag is on
        if (processFlag)           
            labels = edf2mat(char(patientID),char(fileID));
        end        
        %% move on 
        seg = [seg,[patientID,fileID]]; 
        tline = fgets(fid);
        str = tline;
        % File Start Time
        startTimePattern = 'File Start Time';
        if (strfind(str,startTimePattern))
            elems = regexp(str, '(\d+\:\d+\:\d+)', 'tokens');
            startTime = elems{1};
            seg = [seg, startTime]; 
        end
        tline = fgets(fid);
        str = tline;
        % File End Time
        endTimePattern = 'File End Time';
        if (strfind(str,endTimePattern))
            elems = regexp(str, ': (\d+\:\d+\:\d+)', 'tokens');
            endTime = elems{1};
            seg = [seg, endTime]; 
        end
        tline = fgets(fid);
        str = tline;
        % Number of Seizures in File
        numSeizureInd = 'Number';
        if (strfind(str,numSeizureInd))
            elems = regexp(str, ': (\d+)', 'tokens');
            num = str2double(elems{1});
            seg = [seg, num]; 
            seizureInfo = struct;
            if num>0  % if contain seizure
                for i=1:num  
                    tline = fgets(fid);
                    str = tline;
                    seizureInd = 'Seizure';
                    if (strfind(str,seizureInd))
                        elems = regexp(str, ': (\d+) seconds', 'tokens');                        
                        seizureStartTime = str2double(elems{1});
                        tline = fgets(fid);
                        str = tline;
                        elems = regexp(str, ': (\d+) seconds', 'tokens');                        
                        seizureEndTime = str2double(elems{1});
                        value = {seizureStartTime,seizureEndTime};
                        seizureInfo.(['Seizure',num2str(i)]) = value;                    
                    end                    
                end
                seg = [seg,seizureInfo];
            else
                seg = [seg,struct()];
            end
        end
        
    end
    info = [info; seg];
    tline = fgets(fid);
end
fclose(fid);

%% save info to file
savePath = ['../Data/chb',patient,'mat'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
% info = num2cell(info)
fileName = ['SNchb',char(patient),'summary.mat'];
save([savePath,'/',fileName],'info')

end