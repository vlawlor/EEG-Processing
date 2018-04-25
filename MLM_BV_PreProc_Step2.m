% This script should be run after MLM_BV_PreProc_Step1 has been completed
% This script completes the following steps of the MLM ERP processing stream:

% 1. Import updated event timing into merged EEG file
% 3. Re-reference the data to average reference
% 4. Bandpass filter the data
% 5. Prompt the user to identify bad channels
% 7. Prompt user to identify and exclude paroxysmal artifacts

% User should edit the subject list, location of the data ('dataloc'), and
% the filter settings listed below, as needed.
% ------------------------------------------------

% USER EDIT THESE LINES
base_dir = '/Users/mlm2/Work/Expts/StressMem/'
hp = 0.1; % High-pass filter
lp = 30; % Low-pass filter
% Note: If you change either filter setting, you may need to update the
% inputs to pop_eegfiltnew() below

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

% Loop over subjects
for i = 1:length(subjects)
    if strcmp(session, 'enc')
        sfolder = sprintf('%s%s/Analysis/',dataloc,subjects{i});
        mgdfile = sprintf('%s_enc.set',subjects{i});  
        
        % Load the merged dataset into eeglab
        EEG = pop_loadset('filename',mgdfile,'filepath',sfolder);
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
        % Import the event timing file from PsychoPy into eeglab
        tfile = sprintf('%s%s_enc_event_timing.csv',sfolder,subjects{i});
        EEG = pop_importevent( EEG, 'append','no','event',tfile,'fields',{'latency' 'code' 'type'},'skipline',1,'timeunit',1,'optimalign','off');
        setname = sprintf('%s_enc_events',subjects{i});
        EEG = pop_editset(EEG, 'setname', setname);
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    end
    if strcmp(session, 'ret')
        sfolder = sprintf('%s%s/Analysis/',dataloc,subjects{i});
        mgdfile = sprintf('%s_ret_mgd.set',subjects{i});
        
        % Load the merged dataset into eeglab
        EEG = pop_loadset('filename',mgdfile,'filepath',sfolder);
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
        % Import the event timing file from PsychoPy into eeglab
        tfile = sprintf('%s%s_ret_event_timing.csv',sfolder,subjects{i});
        EEG = pop_importevent( EEG, 'append','no','event',tfile,'fields',{'latency' 'code' 'type'},'skipline',1,'timeunit',1,'optimalign','off');
        setname = sprintf('%s_ret_mgd_events',subjects{i});
        EEG = pop_editset(EEG, 'setname', setname);
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    end


    % Re-reference to average of all channels
    EEG = pop_reref( EEG, []);
    setname = sprintf('%s_aref',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

    % Bandpass filter the data
    EEG = pop_eegfiltnew(EEG, hp, lp, 33000, 0, [], 0);
    setname = sprintf('%s_filt',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

      
    % Prompt user to scroll through and remove terrible data
    fprintf('\nNOW REJECT PAROXYSMAL ARTIFACTS . . . \nWhen done, press "REJECT" on the EEG display.')
    fprintf('\nEEGLAB will prompt you to rename the dataset.\nDo so by adding "_ar1" to the name.\nDo not save the dataset to disk yet.\n')
    eeglab redraw;
    pop_eegplot(EEG)
    
    % Wait for "999" so that user has time to remove bad data
    while 1
        pause = input('\nAfter you have rejected the bad data and added "_ar1", type "999" then "ENTER" to continue.\n');
        if pause > 128   
            break;
        end
    end
    
    % Update datasets
    setname = sprintf('%s_ar1',setname);
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
      
    % Save the dataset to disk
    EEG = pop_saveset( EEG, 'filename',setname,'filepath',sfolder);
    
    % Clear all datasets from memory
    nsets = length(ALLEEG);
    ALLEEG = pop_delset(ALLEEG, nsets);
end

fprintf('\nScript finished! These data are ready for the ICA.\n')
