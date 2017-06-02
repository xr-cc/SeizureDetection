% Processing patients(cases) one by one.
%%
n = 23;
fileID = fopen('process_note.txt','w');
fprintf(fileID, ['Start processing.\n']); 
for i = 1:n
    patient_id = num2str(i,'%02d');
    try
        % uncomment corresponding commands
        fprintf(fileID, ['Processing ',patient_id,' done.\n']);   
%         process_patient(patient_id,true);
%         get_patient_feature(patient_id);                    
    catch ME
        S=sprintf('----Error in Patient %s ...',patient_id);
        disp(S);
    end
    fclose(fileID);
end
%%
% patientID = '14'
% m = 42;
% for i = 1:m
%     fileID = num2str(i,'%02d');
%     try
%         edf2mat(patientID, fileID);
%     catch ME
%         S=sprintf('----Error in file %s ...',i);
%         disp(S);
%     end
% end

