function [labels,info] = process_patient(patient,processFlag)
% PROCESS_PATIENT  Process edf files of a specified patient and save them properly.
% Usage:    process_patient(patient)
%           labels = process_patient(patient)
%           [labels,info] = process_patient(patient)
% Inputs:   patient         -char array of patient ID
%           processFlag(opt)-process files or not (default: false)
% Outputs:  labels          -array of names of channels used in order
%           info            -matrix of all infomation read for the patient 
%                            of format:
%                            [patientID,fileID,startTime,endTime,seizure,seizureInfo],
%                            where seizureInfo is [1x1 struct] with fields
%                            Seizure1, Seizure2, etc. (if ever), which
%                            contain 1x2 cell of seizure onset and end time.                            
% Note:     used function: edf2mat()

if nargin < 2
  processFlag = false;
end

S=sprintf('Processing Patient %s ...',patient);
disp(S);

labels = ''; % default value if not processing file

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
    seg = []; % store info of current segment of data (or, file)
    % File Name
    namePattern = 'File Name';
    if (strfind(str,namePattern))
        elems = regexp(str, '(\d+[a-z]*)_(\d+)', 'tokens');        
        patientID = elems{1}(1);
        fileID = elems{1}(2);
        %% process file of each time segment if processFlag is on
        if (processFlag)           
            fprintf(note_file, ['Processing edf',char(patientID),char(fileID),'...\n']);
            try
                labels = edf2mat(char(patientID),char(fileID));
            catch ME
                disp(['error in ',patientID,'_',fileID]);
            end
            fprintf(note_file, ['Done mat',char(patientID),char(fileID),'...\n']);  
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
            elems = regexp(str, ':\s*(\d+\:\d+\:\d+)', 'tokens');
            endTime = elems{1};
            seg = [seg, endTime]; 
        end
        tline = fgets(fid);
        str = tline;
        % Number of Seizures in File
        numSeizureInd = 'Number';
        if (strfind(str,numSeizureInd))
            elems = regexp(str, ':\s*(\d+)', 'tokens');
            num = str2double(elems{1});
            seg = [seg, num]; 
            seizureInfo = struct;
            if num>0  % if contain seizure
                for i=1:num  
                    tline = fgets(fid);
                    str = tline;
                    seizureInd = 'Seizure';
                    if (strfind(str,seizureInd))
                        elems = regexp(str, ':\s*(\d+) seconds', 'tokens');                        
                        seizureStartTime = str2double(elems{1});
                        tline = fgets(fid);
                        str = tline;
                        elems = regexp(str, ':\s*(\d+) seconds', 'tokens');                      
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
fileName = ['SNchb',char(patient),'summary.mat'];
save([savePath,'/',fileName],'info')

S=sprintf('Finish Processing Patient %s',patient);
disp(S);
end