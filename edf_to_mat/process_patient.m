function labelInOrder = process_patient(patient)
%num2str([0:20].','%02d')

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
        
        % process file
%         labelInOrder = edf2mat(char(patientID),char(fileID));
        
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
        % number of seizures
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
%     disp(seg)
    info = [info; seg];
    tline = fgets(fid);
end
fclose(fid);

%% save info
savePath = ['../Data/chb',patient,'mat'];
if ~exist(savePath, 'dir')
  mkdir(savePath);
end
% info = num2cell(info)
fileName = ['SNchb',char(patient),'summary.mat'];
save([savePath,'/',fileName],'info')

end