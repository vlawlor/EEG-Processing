%Last updated: Nov 27, 2017
%Author: Elyssa Barrick, Michelle Basta, and the Danimal
%This script runs first ERP processing step after ICA correction.

% ------------------------------------------------

% USER EDIT THESE LINES
base_dir = '/Users/mlm2/Work/Expts/StressMem/'
epoch = [-200 2000] % Epoch to be used for segmenting and printing
% ------------------------------------------------
% ------------------------------------------------
dataloc = sprintf('%sData/',base_dir)
analysis_loc = sprintf('%sAnalysis/',base_dir)
% Make a GUI that prompts the user to enter session type & subject IDs
prompt = {'Type ret for retrieval or enc for encoding','Enter space-separated subject IDs:'};
dlg_title = 'Enter Info';
num_lines = 1;
answer = inputdlg(prompt,dlg_title,num_lines);
session = (answer{1})
strsubjects = (answer{2})
fprintf(strsubjects)
subjects = strsplit(strsubjects) % Turn the string into an array of subjects
% I think it will be easier to do a batch of encoding then a batch of retrieval,
% instead of trying to do them at the same time
% ------------------------------------------------
% Launch eeglab
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
badchans = cell(size(subjects));
badchans_new = cell(size(subjects));

% Loop through subjects
for i = 1:length(subjects);
    sfolder = sprintf('%s%s/Analysis/',dataloc,subjects{i});
    out_folder = sprintf('%sERPs_%d_to_%d',sfolder,epoch(1),epoch(2))
    mkdir(out_folder)
    disp(sfolder);
    chdir(sfolder);
    infile = dir('*_ICA.set');
    infile = infile.name;    
    chdir(dataloc);

    %Loads ICA into EEGLAB (does not display on GUI)
    EEG = pop_loadset('filename',infile,'filepath',sfolder);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    % View Components
    eeglab redraw;
    pop_topoplot(EEG,0, [1:20] ,'filename',[3 4] ,0,'electrodes','off');
    pop_eegplot( EEG, 0, 1, 1);

    % Prompting user to check and reject components
    fprintf('\nCheck component maps and plot. Identify blink and eye movement components.\nWhen done, write down identified components and close EEG display.\n');

    subcomp = zeros(1,4); % Assuming no more than 4 identified components
    ct = 0;
    while 1
        ct = ct+1;
        subcomp(ct) = input('\nType in the components one at a time, pressing "ENTER" after each one.\nWhen done--type "999", then "ENTER".\n');
        if subcomp(ct) > 128
            break;
        end
    end
    subcomp = subcomp(1:ct);
    subcomp(end) = [];

    % If there are any bad components, reject them.
    if  length(subcomp) > 0
        fprintf('\nRejecting components\n');   
        EEG = pop_subcomp( EEG, subcomp, 0);

    % Rename set with ar2
        fname = strsplit(infile,'.set');
        fname = fname{1};
        setname = sprintf('%s_ar2',fname);
        EEG = pop_editset(EEG, 'setname', setname);
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

     % Save the dataset to disk
        EEG = pop_saveset( EEG, 'filename',setname,'filepath',out_folder);

    end

    % If there were bad channels, interpolate and add "itp". Otherwise, do
    % not interpolate and add "noitp"
    
    % TODO: MAKE SUBJECTS ENTER THE BAD CHANNELS HERE.
    % TODO: MAKE SUBJECTS ENTER THE BAD CHANNELS HERE.
    % TODO: MAKE SUBJECTS ENTER THE BAD CHANNELS HERE.
    fprintf('\nNow you need to input the list of bad channels for subject %s.\n',subjects{i})
    bcs = zeros(25); % Allowing user to enter up to 24 bad channels; last slot is for the terminal '999'
    ct = 0;
    while 1
        ct = ct+1;
        bcs(ct) = input('\nType in the bad channels one at a time, pressing "ENTER" after each one.\nWhen done, type "999", then "ENTER".\n');
        if bcs(ct) > 96
            break
        end
    end
    bcs = bcs(1:ct);
    bcs(end) = [];
    badchans{i} = bcs;    

    % Prompt user to check that the bad channels have been entered correctly
    while 1
    fprintf('\nBad channels for subject %s:',subjects{i})
    disp(badchans{i})

    pause = input('Type "1" if correct, "999" if incorrect, then hit "ENTER".\n');
        if pause == 1
            break
        else
            return
        end
    end
    badchans_new{i} = badchans{i} - 1;
    
    if length(badchans) > 0
        % Interplotate the bad channels.
        fprintf('Interpolating bad channels for subject %s ',subjects{i})
        EEG = eeg_interp(EEG,badchans_new{i});
        setname = sprintf('%s_itp',setname);
    else
        setname = sprintf('%s_noitp',setname);
    end
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    % Prompting user to overwrite file and choose numeric labels
    fprintf('\nOverwrite file when prompted.\nApply numeric codes when prompted.\n');
    
    if strcmp(session, 'enc')     
        % Updating events in ERPlab to numeric codes
        elist_name = sprintf('%s/elist.txt',out_folder)
        EEG  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'ExportEL', ...
        elist_name, 'List', '/Users/mlm2/Work/Expts/StressMem/Analysis/elist_equations_enc.txt', 'SendEL2', 'EEG&Text', 'UpdateEEG', 'on', 'Warning', 'on' );
        EEG = eeg_checkset( EEG );
    end
    
    if strcmp(session, 'ret')     
        % Updating events in ERPlab to numeric codes
        elist_name = sprintf('%s/elist.txt',out_folder)
        EEG  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'ExportEL', ...
        elist_name, 'List', '/Users/mlm2/Work/Expts/StressMem/Analysis/elist_equations_ret.txt', 'SendEL2', 'EEG&Text', 'UpdateEEG', 'on', 'Warning', 'on' );
        EEG = eeg_checkset( EEG );
    end   
    % Rename set with elist
    setname = sprintf('%s_elist',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

    if strcmp(session, 'enc')
        % Sort trials into bins based on numeric events codes previously created
        elist2_name = sprintf('%s/elist2.txt',out_folder)
        EEG  = pop_binlister( EEG , 'BDF', '/Users/mlm2/Work/Expts/Stressmem/Analysis/enc_binlist_grouped.txt', 'ExportEL', elist2_name, ...
            'ImportEL', elist_name, 'IndexEL',  1, 'SendEL2', 'EEG&Text', 'UpdateEEG', 'on', 'Voutput', 'EEG' );
        EEG = eeg_checkset( EEG );
    end
    
    if strcmp(session, 'ret')
        % Sort trials into bins based on numeric events codes previously created
        elist2_name = sprintf('%s/elist2.txt',out_folder)
        EEG  = pop_binlister( EEG , 'BDF', '/Users/mlm2/Work/Expts/Stressmem/Analysis/ret_binlist_grouped.txt', 'ExportEL', elist2_name, ...
            'ImportEL', elist_name, 'IndexEL',  1, 'SendEL2', 'EEG&Text', 'UpdateEEG', 'on', 'Voutput', 'EEG' );
        EEG = eeg_checkset( EEG );
    end 
    % Rename set with bins
    setname = sprintf('%s_bins',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

    % Break data into epochs: 200ms pre-stim, 2000ms post-stim
    fprintf('\nComputing bin-based epochs.\n');
%     EEG = pop_epochbin( EEG , [-200.0  2000.0],  'pre');
    EEG = pop_epochbin( EEG , epoch,  'pre');

    % Rename set with bin-epoched
    setname = sprintf('%s_be',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
     
    
%     % Artifact Rejection: ERPs
%     EEG  = pop_artmwppth( EEG , 'Channel',  1:128, 'Flag', [ 1 2], 'Threshold',  100, 'Twindow', [ -200 1999], 'Windowsize',  200, 'Windowstep', 100 );
%     EEG  = pop_artmwppth( EEG , 'Channel',  1:128, 'Flag', [ 1 2], 'Threshold',  100, 'Twindow', [ epoch(1) (epoch(2)-1)], 'Windowsize',  200, 'Windowstep', 100 );
%     EEG = eeg_checkset( EEG );
%     pop_eegplot( EEG, 1, 1, 0);
%     
%     % Wait for user to mark (or unmark) artifacts by hand. Then synchronize
%     % the marked epochs across eeglab and erplab.
%     uiwait
%     EEG = pop_syncroartifacts(EEG);
% 
%     % Rename set with ar3
%     setname = sprintf('%s_ar3',setname);
%     EEG = pop_editset(EEG, 'setname', setname);
%     [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    % Artifact Detection: Epoched Data
    EEG  = pop_artextval( EEG , 'Channel',  1:95, 'Flag', [ 1 3], 'Threshold', [ -100 100], 'Twindow', [ epoch(1) (epoch(2)-1)] );
    EEG = eeg_checkset( EEG );
    pop_eegplot( EEG, 1, 1, 0);
    
    % Wait for user to mark (or unmark) artifacts by hand. Then synchronize
    % the marked epochs across eeglab and erplab.
    uiwait
    EEG = pop_syncroartifacts(EEG);
    
    % Rename set with ar4
    setname = sprintf('%s_ar4',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

    % Save the dataset to disk
    EEG = pop_saveset( EEG, 'filename',setname,'filepath',out_folder);     

    eeglab redraw;

    % Save artifact detection summary 
    fname= sprintf('%s/%s_artifacts.txt', out_folder, subjects{i});
    EEG = pop_summary_AR_eeg_detection(EEG, fname);

    % Compute ERP Averages
    ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );

    % Save ERP set
    erpname = [subjects{i} '_ERPs'];  % name for erpset menu
    fname_erp = fullfile(out_folder, [erpname '.erp']);
    pop_savemyerp(ERP, 'erpname', erpname, 'filename', fname_erp);

  
end
