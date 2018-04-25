% Last updated: Nov 27, 2017
% Author: Dan Dillon

% This script should be run after MLM_ERP_PreProc_Step2 has been completed.
% It runs the 'runica' in eeglab, looping over the subjects listed below.
% Subject is prompted to identify and enter a list of bad channels for each subject;
% these will be excluded from the ICA.

% User should update the subject list and the location of the data ('dataloc') below, as needed.
% ------------------------------------------------
% USER EDIT THESE LINES
base_dir = '/Users/mlm2/Work/Expts/StressMem/'
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

% Ask user to verify subject list
fprintf('\nThis script will run an ICA in eeglab for the following subjects:\n\n')
for i=1:length(subjects)
    fprintf('%s ',subjects{i})
end
fprintf('\n\nIf that is INCORRECT, type "999" and edit the subject list in this script.\n')
fprintf('\nIf that is CORRECT, type "1".\n')

% Wait for user input
while 1
    pause = input('\nPlease type in your response and press ENTER:\n');
    if pause == 1   
        break
    else
        return
    end
end



% Prompt user to enter bad channels for each subject; these will be
% excluded from the ICA
badchans = cell(size(subjects));
badchans_new = cell(size(subjects));

for i=1:length(subjects)
     
    if strcmp(session, 'enc')
        sfolder = sprintf('%s%s/Analysis/',dataloc,subjects{i});
        mgdfile = sprintf('%s_enc_events_aref_filt_ar1.set',subjects{i});  
    end
    if strcmp(session, 'ret')
        sfolder = sprintf('%s%s/Analysis/',dataloc,subjects{i});
        mgdfile = sprintf('%s_ret_mgd_events_aref_filt_ar1.set',subjects{i});  
    end
    
    EEG = pop_loadset('filename',mgdfile,'filepath',sfolder);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
        % Identify bad channels, prompt user to enter them, and the interpolate
    eeglab redraw;
    pop_eegplot(EEG)
    
    % Prompt user to enter bad channels for each subject; these will be
    % excluded from the ICA
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
    
    if strcmp(session, 'enc')
        bc_name = sprintf('%s%s_enc_badchans.csv',sfolder,subjects{i});
    elseif strcmp(session, 'ret')
        bc_name = sprintf('%s%s_ret_badchans.csv',sfolder,subjects{i});
    end
    csvwrite(bc_name,badchans)
end

% Launch eeglab
%[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

fprintf('\nBADCHANS HERE 1.');
disp(badchans{1});
    
% Loop over subjects
for i=1:length(subjects)
    fprintf('\nBADCHANS HERE 2.');
    disp(badchans{i});
    sfolder = sprintf('%s%s/Analysis/',dataloc,subjects{i});
    chdir(sfolder);
    infile = dir('*ar1.set');
    infile = infile.name;
    chdir(dataloc);
    
    EEG = pop_loadset('filename',infile,'filepath',sfolder);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
     
    % TODO: fix this and check
    chans = [1:95];
    badchans_new{i} = badchans{i} - 1;
    fprintf('\nBADCHANS HERE 3.');
    disp(badchans{i});
    chans(badchans_new{i}) = [];
    disp(chans);
    EEG = pop_runica(EEG,'chanind',chans);
    
    % Update dataset name
    fname = strsplit(infile,'.set')
    fname = fname{1}
    setname = sprintf('%s_ICA',fname)
    EEG = pop_editset(EEG, 'setname', setname);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
      
    % Save the dataset to disk
    EEG = pop_saveset( EEG, 'filename',setname,'filepath',sfolder);
    
    % Clear all datasets from memory
    nsets = length(ALLEEG);
    ALLEEG = pop_delset(ALLEEG, nsets);
end

