# Last updated: 8/11/2017
# Author: Victoria Lawlor
# Creates psychopy event lists and merges them with EEG event lists for the StressMem project
# Made to be called directly from MATLAB in the MLM_BV_Step1 file

# User edit below
uname = 'mlm2'
# Can keep the rest

path2code = '/Users/' + uname + '/Work/Expts/Code/'
path2data = '/Users/' + uname + '/Work/Expts/StressMem/Data/'
path2analysis = '/Users/' + uname + '/Work/Expts/StressMem/Analysis/'
path2figs = '/Users/' + uname + '/Work/Expts/StressMem/Analysis/Figures/'
path2stims = '/Users/' + uname + '/Work/Expts/StressMem/PsychoPy/Stimuli/'

import sys
import argparse
import numpy as np
import os, re, glob
import pandas as pd

print('TESTTESTESTESTEST')
print(sys.path)

def main():
    # Parse arguments from command line
    parser = argparse.ArgumentParser()

    # Set up required arguments this script
    parser.add_argument('function', type=str, help='function to call')
    parser.add_argument('first_arg', type=str, help='the argument')
    #parser.add_argument('second_arg', type=str, help='second argument')

    # Parse the given arguments
    args = parser.parse_args()

    # Get the function based on the command line argument and 
    # call it with the other two command line arguments as 
    # function arguments
    eval(args.function)(args.first_arg)

def test(first_arg):
    print(first_arg)

def encEegCode(list_of_subjects):
    '''Goes through the given subjects and creates an event list file for each\
    one in the Data/Subject/Analysis folder by passing their data through to makePyEnc'''
    base_dir = path2data
    os.chdir(base_dir)
    #subjects = !ls -d STM0*
    print(list_of_subjects)
    list_of_subjects = list_of_subjects.split()
    for subject in list_of_subjects:
        print(subject)
        k = (glob.glob(path2data + subject + '/' + subject + '*_enc.csv'))
        file = k[0]
        data = pd.read_csv(file)
        p = (glob.glob(path2data + subject + '/' + subject + '*_ret.csv'))
        file = p[0]
        ret_data = pd.read_csv(file)
        ret_data = ret_data.rename(index = str, columns = {'item':'word'})
        makePyEnc(subject, data, ret_data)

def makePyEnc(subject, enc_data, ret_data):
    '''Makes the PsychoPy_enc.csv file for the given subject & their data. This later gets \
    merged with the events.csv'''
    # word codes for eeglab
    codes = pd.read_csv(path2analysis + 'enc_all_codes.csv')
    wcode_d= {}
    for i, row_i in codes.iterrows():
        wcode_d[row_i.Element] = row_i.Code
    old_ret_data = ret_data[ret_data['status'] == 'old']
    data = pd.merge(enc_data, old_ret_data, on = 'word', how='left') 
    
    d = {}
    trial = 1
    for i, row_i in data.iterrows():
        # Make the 'prompt' item either emotion or describes and assign appropriate code
        if row_i.task == 'Positive':
            enc_prompt = 'Quest_Emo'
            prompt = 'Emo_'# this becomes part of the word code
            pcode = 515
        elif row_i.task == 'Describes':
            enc_prompt = 'Quest_Desc'
            prompt = 'Desc_'
            pcode = 516
        
        # Grab the recog_reponse
        Rec_resp = '_Rec' + str(int(row_i.recog_resp)) + ''
        
        # Get the task respone
        if np.isfinite(row_i.task_resp):
            Task_resp = '_Sr' + str(int(row_i.task_resp)) + ''
        else:
            Task_resp = ''
        
        # Is this block 1 or 2?
        if row_i.block == 1:
            Block = '' 
        elif row_i.block == 2:
            Block = '_2'
        
        # Get the valence
        if row_i.valence_x == 0:
            valence = 'Neg_' # this starts the word code
        elif row_i.valence_x == 1:
            valence = 'Pos_'
            
        # At retrieval, do they see the word pre or post stress?
        if row_i.session == 1:
            When = '_Pre' # this starts the word code
        elif row_i.session == 2:
            When = '_Post'
        
        # What do they respond at encoding?
        if row_i.response == 'no':
            Resp = 'No' # this goes on the word code
            rcode = 518
        elif row_i.response == 'yes':
            Resp = 'Yes'
            rcode = 518
            
        if row_i.response == 'no_response':
            Resp = 'Error'
            wtype = 'Error'
            rcode = 519
        else:
            wtype = valence + prompt + Resp + Rec_resp + Task_resp + When + Block # put the word code together
            wcode = wcode_d[wtype]

        d[trial,1] = {'Type': enc_prompt, 'Code': pcode}
        d[trial,2] = {'Type': wtype, 'Code': wcode}
        d[trial,3] = {'Type': 'Rscr', 'Code': 517}
        d[trial,4] = {'Type': Resp, 'Code': rcode}
        # add the block information
        if trial > 100:
            Block = 2
        elif trial <= 100:
            Block = 1
        trial+=1
    df = pd.DataFrame(d).transpose()
    df.index.names = ['Trial','Element']
    df.reset_index(inplace=True)
    df.loc[df.Trial > 100, 'Block'] = 2
    df.loc[df.Trial <= 100, 'Block'] = 1
    df = df[['Block', 'Trial','Element','Type','Code']]

    if len(df) > 0:
        newfile = path2data + subject + '/Analysis/' + subject + '_PsychoPy_enc.csv'
        df.to_csv(newfile, index=False) # save the file
    else: 
        print ('No dfs for subject ' + subject)

def encEventMerge(list_of_subjects):
    list_of_subjects = list_of_subjects.split()
    for subject in list_of_subjects:
        outfile = path2data + subject + '/Analysis/' + subject + '_enc_event_timing.csv'# the file that gets written out
        eeg_elist = path2data + subject + '/Analysis/' + subject + '_enc_events.csv' # the eeg event list from eeglab
        pp_elist = path2data + subject + '/Analysis/' + subject + '_PsychoPy_enc.csv' # the behavioral events  
        
        eeg_df = pd.read_csv(eeg_elist, sep='\t')
        pp_df = pd.read_csv(pp_elist)
        
        eeg_df = eeg_df[~(eeg_df.type == 'boundary')] 
        eeg_df = eeg_df[~(eeg_df.type == 'Buffer Overflow')]
        
        eeg_df['type'] = eeg_df.type.apply(lambda row: row.lstrip('S'))
        eeg_df['type'] = eeg_df.type.apply(lambda row: int(row))

        # Drop response == "error" markers from the PsychoPy file b/c there is no corresponding event in the EEG file
        pp_df = pp_df[~((pp_df.Element == 4) & (pp_df.Type == 'Error'))] 

        # Next make latency series from the eeg event list
        # For the two prompts (Emotion + Describes)
        pmpts_eeg = eeg_df[(eeg_df.type == 201) | (eeg_df.type == 202)]['latency']
        pmpts_eeg.reset_index(inplace=True,drop=True)

        # For all of the items    
        items_eeg = eeg_df[eeg_df.type <= 200]['latency']
        items_eeg.reset_index(inplace=True,drop=True)

        rscrs_eeg = eeg_df[eeg_df.type == 204]['latency']
        rscrs_eeg.reset_index(inplace=True,drop=True)

        resps_eeg = eeg_df[(eeg_df.type == 205) | (eeg_df.type == 206)]['latency']
        resps_eeg.reset_index(inplace=True,drop=True)
        
        # Now make dfs with cols 'Type','Code' from the PsychoPy event list
        cue_types = ['Quest_Desc','Quest_Emo']
        pmpts = pp_df[pp_df.Type.isin(cue_types)][['Type','Code']]
        pmpts.reset_index(inplace=True)
        
        item_types = pd.read_csv(path2analysis + 'enc_item_codes.csv')
        item_types = item_types.Element
        #item_types = ['Pos_Desc_Yes', 'Pos_Desc_No', 'Pos_Emo_Yes', 'Pos_Emo_No', 'Neg_Desc_Yes', \
        #             'Neg_Desc_No', 'Neg_Emo_Yes', 'Neg_Emo_No']
        
        items = pp_df[pp_df.Type.isin(item_types)][['Type','Code']]
        items.reset_index(inplace=True)

        rscrs = pp_df[pp_df.Type == 'Rscr'][['Type','Code']]
        rscrs.reset_index(inplace=True)

        resps = pp_df[(pp_df.Type == 'Yes') | (pp_df.Type == 'No')][['Type','Code']]
        resps.reset_index(inplace=True)
        
        # Now compare the eeg and PsychoPy dfs for length. If they do not match, print an error and exit.
        # Otherwise merge Type, Code, Latency

        if len(pmpts_eeg) != len(pmpts):
            print (len(pmpts_eeg), len(pmpts))
            print("For subject , the number of EEG 'pmpt' codes does not equal number of probes\
            from PsychoPy! Quitting. It's likely that the recording was started too early or stopped\
            too late, causing extra triggers to be sent.")
        else:
            pmpts['Latency'] = pmpts_eeg

        if len(items_eeg) != len(items):
            print(len(items_eeg))
            print(len(items))
            print("For subject, the number of EEG 'item' codes does not equal number of items\
            from PsychoPy! Quitting")
        else:
            items['Latency'] = items_eeg

        if len(rscrs_eeg) != len(rscrs):
            print(len(rscrs))
            print("For subject the number of EEG 'rscr' codes does not equal number of\
            response screens from PsychoPy! Quitting")
        else:
            rscrs['Latency'] = rscrs_eeg

        if len(resps_eeg) != len(resps):
            print(len(resps))
            print("For subject  the number of EEG 'resp' codes does not equal the number of\
            responses from PsychoPy! Quitting")
        else:
            resps['Latency'] = resps_eeg

        # Put it all together
        out = pd.concat([pmpts,items,rscrs,resps])
        out.sort_values('Latency',inplace=True)
        out = out[['Latency','Code','Type']]
        new_cols = ['latency','code','type']
        out.columns = new_cols
        out['latency'] = out.latency/500
        out['code'] = out.code.apply(lambda x: int(x))
        out.to_csv(outfile,index=False,sep="\t")

def proc_ret(enc, ret):
    enc_run1 = {}
    enc_run2 = {}
    
    # get dictionaries of run 1 words & responses and run 2 words & responses
    for i, row_i in enc.iterrows():
        if row_i.block == 1:
            enc_run1[row_i.word] = row_i.response
        elif row_i.block == 2:
            enc_run2[row_i.word] = row_i.response
        else:
            print('Error: There is word not assigned to a block')
            
    # make two columns that say what the run 1 and run 2 responses are
    ret['enc_resp_run1'] = 'NaN'
    ret['enc_resp_run2'] = 'NaN'
    for word in enc_run1:
        ret.loc[ret.item == word, 'enc_resp_run1'] = enc_run1[word]
    for word in enc_run2:
        ret.loc[ret.item == word, 'enc_resp_run2'] = enc_run2[word]
        
    # make a column that says whether run 1 and run 2 responses are the same
    ret['congruent_response'] = 5
    for i, row_i in ret.iterrows():
        if row_i.enc_resp_run1 != row_i.enc_resp_run2:
            ret.loc[ret.item == row_i['item'], 'congruent_response'] = 0
        elif row_i.enc_resp_run1 == 'no_response':
            ret.loc[ret.item == row_i['item'], 'congruent_response'] = 0
        else:
            ret.loc[ret.item == row_i['item'], 'congruent_response'] = 1
    return(ret)

def retEegCode(list_of_subjects):
    '''Goes through the given subjects and creates an event list file for each\
    one in the Analysis/Event_Files folder by passing their data through to makePyEnc'''
    list_of_subjects = list_of_subjects.split()
    for subject in list_of_subjects:
        k = (glob.glob(path2data + subject + '/' + subject + '*_enc.csv'))
        file = k[0]
        enc_data = pd.read_csv(file)
        p = (glob.glob(path2data + subject + '/' + subject + '*_ret.csv'))
        file = p[0]
        ret_data = pd.read_csv(file)
        ret_data = proc_ret(enc_data, ret_data)
        ret_data = ret_data.rename(index = str, columns = {'item':'word'})
        makePyRet(subject, enc_data, ret_data)

def makePyRet(subject, enc_data, ret_data):
    '''Makes the PsychoPy_ret.csv file for the given subject & their data. This later gets \
    merged with the events.csv'''
    # word codes for eeglab
    codes = pd.read_csv(path2analysis + 'ret_all_codes.csv')
    wcode_d= {}
    for i, row_i in codes.iterrows():
        wcode_d[row_i.Element] = row_i.Code
    
    d = {}
    trial = 1
    for i, row_i in ret_data.iterrows():
        # is the word old or new?
        if row_i.status == 'old':
            status = 'Old_'
        elif row_i.status == 'new':
            status = 'New_'
            enc_task = ''

        # Get the valence
        if row_i.valence == 0:
            valence = 'Neg_' # this starts the word code
        elif row_i.valence == 1:
            valence = 'Pos_'
            
        # What is the encoding prompt
        if row_i.enc_task == 'Positive':
            enc_task = 'Emo_'# this becomes part of the word code
        elif row_i.enc_task == 'Describes':
            enc_task = 'Desc_'
            
        # What do they respond at encoding?
        # Provides _Error_ if the responses in runs 1 & 2 are not the same
        if row_i.congruent_response == 1:
            if row_i.enc_resp_run1 == 'no':
                Enc_resp = 'No_' # this goes on the word code
            elif row_i.enc_resp_run1 == 'yes':
                Enc_resp = 'Yes_'
            else:
                Enc_resp = ''
        else:
            Enc_resp = 'Err_'
            
        # Grab the recog_reponse
        if np.isfinite(row_i.recog_resp):
            Rec_resp = 'Rec' + str(int(row_i.recog_resp)) + '_'
        else:
            Rec_resp = 'Error'
            
        
        # Get the task respone
        if np.isfinite(row_i.task_resp):
            Task_resp = 'Sr' + str(int(row_i.task_resp)) + '_'
        elif Rec_resp == 'Rec1_':
            Task_resp = 'Err_'
        elif Rec_resp == 'Rec2_':
            Task_resp = 'Err_'
        else:
            Task_resp = ''
            
        # At retrieval, do they see the word pre or post stress?
        if row_i.session == 1:
            When = 'Pre' # this starts the word code
        elif row_i.session == 2:
            When = 'Post'
            
        if np.isfinite(row_i.recog_resp):
            wtype = status + valence + enc_task + Enc_resp + Rec_resp + Task_resp + When # put the word code together
            wcode = wcode_d[wtype]
        else:
            Resp = 'Error'
            wtype = 'Error'
            rcode = 1151

        d[trial,1] = {'Type': 'Recog_Prompt', 'Code': 1150}
        d[trial,2] = {'Type': wtype, 'Code': wcode}
        d[trial,3] = {'Type': 'Resr', 'Code': 1147}
        d[trial,4] = {'Type': 'Resp', 'Code': 1149}
        
        if Task_resp != '':
            d[trial,5] = {'Type': 'Src_Prompt', 'Code': 1149} # task prompt
            d[trial,6] = {'Type': 'Src_' + wtype, 'Code': wcode_d['Src_' + wtype]} # word
            d[trial,7] = {'Type': 'Resr', 'Code': 1147} # response options
            d[trial,8] = {'Type': 'Resp', 'Code': 1148} # response
        else:
            pass
        
        # add the block information
        if trial > 100:
            Block = 2
        elif trial <= 100:
            Block = 1
        trial+=1
    df = pd.DataFrame(d).transpose()
    df.index.names = ['Trial','Element']
    df.reset_index(inplace=True)
    df.loc[df.Trial > 100, 'Block'] = 2
    df.loc[df.Trial <= 100, 'Block'] = 1
    df = df[['Block', 'Trial','Element','Type','Code']]

    if len(df) > 0:
        newfile = path2data + subject + '/Analysis/' + subject + '_PsychoPy_ret.csv'
        df.to_csv(newfile, index=False) # save the file
    else: 
        print ('No dfs for subject ' + subject)

def RetEventMerge(list_of_subjects):
    '''Given a list of subjects, merges their EEG and pychopy event files to make the event_timing file for retrieval'''
    list_of_subjects = list_of_subjects.split()
    for subject in list_of_subjects:
        outfile = path2data + subject + '/Analysis/' + subject +  '_ret_event_timing.csv'# the file that gets written out
        eeg_elist = path2data + subject + '/Analysis/' + subject +  '_ret_events.csv' # the eeg event list from eeglab
        pp_elist = path2data + subject + '/Analysis/' + subject + '_PsychoPy_ret.csv' # the behavioral events
        
        eeg_df = pd.read_csv(eeg_elist, sep='\t')
        pp_df = pd.read_csv(pp_elist)
        
        eeg_df = eeg_df[~(eeg_df.type == 'boundary')] 
        eeg_df = eeg_df[~(eeg_df.type == 'Buffer Overflow')]
        
        eeg_df['type'] = eeg_df.type.apply(lambda row: row.lstrip('S'))
        eeg_df['type'] = eeg_df.type.apply(lambda row: int(row))
        
#-----------------------------------Make Lists from eeg events-------------------------------
        # Drop response == "error" markers from the PsychoPy file b/c there is no corresponding event in the EEG file
        #pp_df = pp_df[~(pp_df.Type == 'Error')] 

        # Next make latency series from the eeg event list: 201 is recog prompt, 209 is source prompt

        pmpts_eeg = eeg_df[(eeg_df.type == 201) | (eeg_df.type == 209)]['latency']
        pmpts_eeg.reset_index(inplace=True,drop=True)

        # For all of the items: they all have codes under 200
        items_eeg = eeg_df[eeg_df.type <= 200]['latency']
        items_eeg.reset_index(inplace=True,drop=True)
        
        # for the response screens: 202 for recog, 210 for source
        rscrs_eeg = eeg_df[(eeg_df.type == 202) | (eeg_df.type == 210)]['latency']
        rscrs_eeg.reset_index(inplace=True,drop=True)
        
        # now the responses: 1-6 for recog, 7:10 for source 
        resps_eeg = eeg_df[(eeg_df.type == 203) | (eeg_df.type == 204) | (eeg_df.type == 205) |
                           (eeg_df.type == 206) | (eeg_df.type == 207) | (eeg_df.type == 208) |
                           (eeg_df.type == 211) | (eeg_df.type == 212) | (eeg_df.type == 213) |
                           (eeg_df.type == 214) | (eeg_df.type == 215) | (eeg_df.type == 216) |
                           (eeg_df.type == 217)]['latency']#) | (eeg_df.type in range(7,10))
        resps_eeg.reset_index(inplace=True,drop=True)
        
#-----------------------------------Make Lists from PsychoPy events----------------------------
        # Now make dfs with cols 'Type','Code' from the PsychoPy event list
        cue_types = ['Recog_Prompt','Src_Prompt']
        pmpts = pp_df[pp_df.Type.isin(cue_types)][['Type','Code']]
        pmpts.reset_index(inplace=True)
        
        # Read in all of the retrieval codes
        item_types = pd.read_csv(path2analysis + 'ret_item_codes.csv')
        item_types = item_types.Element

        items = pp_df[pp_df.Type.isin(item_types)][['Type','Code']]
        items.reset_index(inplace=True)

        rscrs = pp_df[pp_df.Type == 'Resr'][['Type','Code']]
        rscrs.reset_index(inplace=True)

        resps = pp_df[(pp_df.Type == 'Resp')][['Type','Code']]
        resps.reset_index(inplace=True)
        
        # Now compare the eeg and PsychoPy dfs for length. If they do not match, print an error and exit.
        # Otherwise merge Type, Code, Latency

        if len(pmpts_eeg) != len(pmpts):
            print (len(pmpts_eeg), len(pmpts))
            print("For subject , the number of EEG 'pmpt' codes does not equal number of probes\
            from PsychoPy! Quitting. It's likely that the recording was started too early or stopped\
            too late, causing extra triggers to be sent.")
        else:
            pmpts['Latency'] = pmpts_eeg

        if len(items_eeg) != len(items):
            print(len(items_eeg), len(items))
            print("For subject, the number of EEG 'item' codes does not equal number of items\
            from PsychoPy! Quitting")
        else:
            items['Latency'] = items_eeg

        if len(rscrs_eeg) != len(rscrs):
            print(len(rscrs))
            print(len(rscrs_eeg))
            print("For subject the number of EEG 'rscr' codes does not equal number of\
            response screens from PsychoPy! Quitting")
        else:
            rscrs['Latency'] = rscrs_eeg

        if len(resps_eeg) != len(resps):
            print(len(resps_eeg),len(resps))
            print("For subject the number of EEG 'resp' codes does not equal the number of\
            responses from PsychoPy! Quitting")
        else:
            resps['Latency'] = resps_eeg

        # Put it all together
        out = pd.concat([pmpts,items,rscrs,resps])
        out.sort_values('Latency',inplace=True)
        out = out[['Latency','Code','Type']]
        new_cols = ['latency','code','type']
        out.columns = new_cols
        out['latency'] = out.latency/500
        out.to_csv(outfile,index=False,sep="\t")

if __name__ == '__main__':
    main()
