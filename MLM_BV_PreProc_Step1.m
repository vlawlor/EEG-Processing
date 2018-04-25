% Last updated: August 8, 2017
% Authors: Dan Dillon & Victoria Lawlor

% This script completes the following steps of the MLM ERP processing stream:
% 1. Load raw files
% 2. Merge raw retrieval files
% 3. Export events
% 4. Create PsychoPy events
% 5. Merge EEG and PsychoPy eventlists to create an event_timing file

% USER EDIT THESE LINES
user = 'mlm2'
dataloc = '/Users/mlm2/Work/Expts/StressMem/Data/'
% ------------------------------------------------
TextInfo.FontSize = 300;
% Make a GUI that prompts the user to enter session type & subject IDs
prompt = {'Type ret for retrieval or enc for encoding','Enter space-separated subject IDs:'};
dlg_title = 'Enter Info';
num_lines = 1;
defaultans = {'enc','STM001'};
answer = inputdlg(prompt,dlg_title,[1.2, length(dlg_title)+ 55]);
session = (answer{1})
strsubjects = (answer{2})
fprintf(strsubjects)
subjects = strsplit(strsubjects) % Turn the string into an array of subjects
% I think it will be easier to do a batch of encoding then a batch of retrieval,
% instead of trying to do them at the same time

% Launch eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% loop through subjects
for i = 1:length(subjects)
    infolder = sprintf('%s%s/',dataloc,subjects{i});
    outfolder = sprintf('%sAnalysis/',infolder);
    mkdir(outfolder);
    fprintf('\n Loading data for subject %s . . .\n',subjects{i})
    
    % If working on the retrieval sessions, merge the two blocks
    if strcmp(session, 'ret')
        fname = sprintf('%s_ret1.vhdr',infolder,subjects{i});
        setname = sprintf('%s_ret1.vhdr',subjects{i});      
        EEG = pop_loadbv(infolder, setname);
        EET.setname = setname;
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
        fname = sprintf('%s_ret2.vhdr',infolder,subjects{i});
        setname = sprintf('%s_ret2.vhdr',subjects{i});      
        EEG = pop_loadbv(infolder, setname);
        EET.setname = setname;
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
        EEG = pop_mergeset( ALLEEG,[1:2],0);
        EEG.setname = sprintf('%s_mgd',subjects{i});
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    else
        fprintf('\n Loading data for subject %s . . .\n',subjects{i})
        fname = sprintf('%s%s_enc.vhdr',infolder,subjects{i});
        setname = sprintf('%s_enc.vhdr',subjects{i});
        EEG = pop_loadbv(infolder, setname);
        EET.setname = setname;
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    end
    
    % Export events
    fprintf('Exporting events for subject %s . . .',subjects{i});
    if strcmp(session, 'enc')
        efile = sprintf('%s_enc_events.csv',subjects{i});
    elseif strcmp(session, 'ret')
        efile = sprintf('%s_ret_events.csv',subjects{i});
    end
    fname = sprintf('%s%s',outfolder,efile);
    pop_expevents(EEG, fname, 'samples');
    
    % Save the file
    if strcmp(session, 'ret')
        mgdfile = sprintf('%s_ret_mgd.set',subjects{i});
        EEG = pop_saveset( EEG, 'filename',mgdfile,'filepath',outfolder);
    elseif strcmp(session, 'enc')
        file = sprintf('%s_enc.set',subjects{i});
        EEG = pop_saveset( EEG, 'filename',file,'filepath',outfolder);
    end
    
    % Clear all datasets from memory
    nsets = length(ALLEEG); 
    ALLEEG = pop_delset(ALLEEG, [1:nsets]);
end

% Make Psychopy events by calling the CreateEventLists.py file
if strcmp(session, 'enc')
    systemCommand = ['/Users/',user,'/anaconda/bin/python CreateEventLists.py encEegCode',' ','"',strsubjects,'"']
elseif strcmp(session, 'ret')
    systemCommand = ['/Users/',user,'/anaconda/bin/python CreateEventLists.py retEegCode',' ','"',strsubjects,'"']
end
system(systemCommand)

% Merge EEG & Psychopy events by calling the CreateEventLists.py file
if strcmp(session, 'enc')
    systemCommand = ['/Users/',user,'/anaconda/bin/python CreateEventLists.py encEventMerge',' ','"',strsubjects,'"']
elseif strcmp(session, 'ret')
    systemCommand = ['/Users/',user,'/anaconda/bin/python CreateEventLists.py RetEventMerge',' ','"',strsubjects,'"']
end
system(systemCommand)

eeglab redraw;
fprintf('\nScript finished! You should now have an events_timing file in the Subject/Analysis folders for the subjects you entered.\n')
