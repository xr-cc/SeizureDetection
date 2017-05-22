% read edf to mat 
n = 1;
fileID = fopen('process_note.txt','w');
fprintf(fileID, ['Start processing.\n']); 
for i = 1:n
    patient_id = num2str(i,'%02d');
    try
%         process_patient(patient_id,true);
%         get_patient_feature(patient_id);        
        fprintf(fileID, ['Processing ',patient_id,' done.\n']);        
    catch ME
        S=sprintf('----Error in Patient %s ...',patient_id);
        disp(S);
    end
    fclose(fileID);
end
