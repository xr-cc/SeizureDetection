% Plot EEG of all patients(cases) and all files of each. 
% Note: may change n and i to control the patients(cases) plotted.
n = 1;
for i = 1:n
    patientID = num2str(i,'%02d');
    try
        % load data
        filePath = ['../Data/chb',patientID,'mat'];
        seizureFlags = [];
        segIDs = {};
        startTs = {};
        endTs = {};
        seizureInfos = {};
        % summary
        summaryFile = [filePath,'/','SNchb',patientID,'summary.mat'];        
        summary = load(summaryFile);
        [nseg,ninfo] = size(summary.info);
        for i = 1:nseg
            segIDs = [segIDs,summary.info{i,2}];
            startTs = [startTs,summary.info{i,3}];
            endTs = [endTs,summary.info{i,4}];
            seizureFlags = [seizureFlags,summary.info{i,5}];
            seizureInfos = [seizureInfos,summary.info{i,6}];
        end
        for segID = segIDs
            segID = char(segID)
            plot_single_file(patientID,segID);
        end      
    catch ME
        S=sprintf('----Error in Patient %s ...',patientID);
        disp(S);
    end
end