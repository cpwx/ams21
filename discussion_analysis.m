% discussion_analysis.m // Charles Powell, NOAA/NESDIS/OPPA (AUG 2020)
% charles.powell@noaa.gov 
% PRE-RELEASE VERSION 0.4
% ************************************************************************
% Conducts Analysis of TC FDs

clear; clc;

% MWD and MSD functions utilize T, nDiscussions as global
global nDiscussions T

% read tables

disp('Loading Forecast Discussions');

T = readtable('fd_v04.xls');

nDiscussions = height(T);


% convert cell arrays from loaded table to string arrays
T.discussion = string(T.discussion);
T.storm = string(T.storm);
T.fd_date = string(T.fd_date);
T.forecaster = string(T.forecaster);
T.fd_time = string(T.fd_time);
T.storm_no = string(T.storm_no);
T.basin = string(T.basin);


%% Load Expression Tokens

disp('Loading Token Rules');

reg_exp = readtable('reg_exp.xls','preservevariablenames',1);
custom_tokens = readtable('custom_tokens.xls','preservevariablenames',1);

%% Strip Body of discussions


pattern12 = strcat(" ",string(T.stormyear));
pattern13 = repmat("$$",nDiscussions,1);

% Hurricane Zeta crosses from 2005 to 2006, breaks the code!
% This hard-indexed, will need to fix if add new years
for ZetaFix = 642:664
    pattern12(ZetaFix) = " 2006";
end

Stripped_Disc = extractBetween(T.discussion,pattern12,pattern13)';
Stripped_Disc = lower(Stripped_Disc);

clear pattern* ZetaFix


%% Tokenize Discussions

disp('Tokenizing Forecast Discussions...');

tic; 
docs = tokenizedDocument(Stripped_Disc,'regularexpressions',reg_exp,'customtokens',custom_tokens);
docs = addPartOfSpeechDetails(docs);
docs = removeStopWords(docs);
docs = normalizeWords(docs,'Style','stem');
details = tokenDetails(docs);
toc;

disp('Tokenization Complete');

%% Create Extra Table Vars for Token Classifier Levels 

disp('Creating Token Hierarchies');

Level1Merge_obs = {'obs-air','obs-sat','obs-sat-alt','obs-sat-geo','obs-sat-scat',...
    'obs-sat-pol','obs-surf'};
Level1Merge_mod = {'mod','mod-dyn','mod-dyn-glob','mod-dyn-reg','mod-ens',...
    'mod-ints'};
Level1Merge_ints = {'ints','ints-det','ints-rapid'};
Level1Merge_trak = {'track','track-fix'};

Level1Merge_other = {'other','letters','digits','punctuation','email-address',...
    'web-address','hashtag','at-mention','emoticon','emoji','custom',...
    'lat','lon','dir-speed','distance','duration',...
    'fd-date','fd-time','fd-tz','forecast-datetime','forecast-time','pressure',...
    'speed-kt','speed-mph','storm-no','disc-no'};

B = mergecats(details.Type,Level1Merge_obs,'obs');
B = mergecats(B,Level1Merge_mod);
B = mergecats(B, Level1Merge_ints);
B = mergecats(B, Level1Merge_trak);
B = removecats(B,Level1Merge_other);
details.inType1 = B;

Level2Merge_sat = {'obs-sat','obs-sat-alt','obs-sat-geo','obs-sat-scat',...
    'obs-sat-pol'};
Level2Merge_mod_dyn = {'mod-dyn','mod-dyn-glob','mod-dyn-reg'};

Level2Merge_other = {'other','letters','digits','punctuation','email-address',...
    'web-address','hashtag','at-mention','emoticon','emoji','custom','converge',...
    'diverge','intensity','lat','lon','track','dir-speed','distance','duration',...
    'fd-date','fd-time','fd-tz','forecast-datetime','forecast-time','pressure',...
    'speed-kt','speed-mph','storm-no','mod', 'disc-no','ints','track', ...
    'ofc', 'sst', 'struct'};

C = mergecats(details.Type,Level2Merge_sat);
C = mergecats(C,Level2Merge_mod_dyn);
C = removecats(C,Level2Merge_other);

details.inType2 = C;

Level3Merge_other = {'other','letters','digits','punctuation','email-address',...
    'web-address','hashtag','at-mention','emoticon','emoji','custom','converge',...
    'diverge','intensity','lat','lon','track','dir-speed','distance','duration',...
    'fd-date','fd-time','fd-tz','forecast-datetime','forecast-time','pressure',...
    'speed-kt','speed-mph','storm-no','mod','obs-air','obs-surf','obs-sat',...
    'mod-dyn','mod-ens','mod-ints', 'ofc', 'sst', 'struct', 'ints',...
    'ints-rapid', 'ints-det', 'track-fix', 'disc-no'};

D = removecats(details.Type,Level3Merge_other);

details.inType3 = D;

details = movevars(details, 'Type', 'Before', 'inType1');


clear B C D Level*


%% has key token in FD?

key_tokens = custom_tokens;
key_tokens_string = string(key_tokens.Token);
numTokens = length(key_tokens_string);

types0 = custom_tokens.Type;
types0 = categorical(types0);
types0 = categories(types0);

inType1 = categories(details.inType1);
inType2 = categories(details.inType2);
inType3 = categories(details.inType3);

numTypes0 = length(types0);
numTypes1 = length(inType1);
numTypes2 = length(inType2);
numTypes3 = length(inType3);

% Find the context for each token in our custom tokens document
disp('Searching Forecasts for Token Context');
for kk = 1:numTokens
    tmpWord = key_tokens_string(kk);
    hasWord{kk,1} = context(docs,tmpWord);
end

clear tmpWord key_tokens_string

% Frequency by Key Token (word, not classified)
disp('Performing Frequency Analysis of Key Tokens');
tmp_token_word_Freq = cellfun(@height,hasWord);

token_word_Freq = table(key_tokens.Token, tmp_token_word_Freq, ...
    'variablenames',{'Token','Freq'});

clear tmp_*

Freq_varnames = {inType1{1}, inType1{2},...
    inType1{3}, inType1{4}, inType1{5},...
    inType1{6}, inType1{7}, inType1{8}, inType1{9}, ...
inType2{1}, inType2{2}, inType2{3}, ...
inType2{4}, inType2{5}, inType2{6}, ...
inType2{7}, inType2{8}, inType2{9}, ...
inType3{1}, inType3{2}, inType3{3}, ...
inType3{4}, inType3{5}, inType3{6}, ...
};

%% Build index of Tokens against classifiers

key_tokens.Type = categorical(key_tokens.Type);

Level1Merge_obs = {'obs-air','obs-sat','obs-sat-alt','obs-sat-geo','obs-sat-scat',...
    'obs-sat-pol','obs-surf'};
Level1Merge_mod = {'mod','mod-dyn','mod-dyn-glob','mod-dyn-reg','mod-ens',...
    'mod-ints'};
Level1Merge_ints = {'ints','ints-det','ints-rapid'};
Level1Merge_trak = {'track','track-fix'};

Level1Merge_other = {'other','letters','digits','punctuation','email-address',...
    'web-address','hashtag','at-mention','emoticon','emoji','custom',...
    'lat','lon','dir-speed','distance','duration',...
    'fd-date','fd-time','fd-tz','forecast-datetime','forecast-time','pressure',...
    'speed-kt','speed-mph','storm-no','disc-no'};

B = mergecats(key_tokens.Type,Level1Merge_obs,'obs');
B = mergecats(B,Level1Merge_mod);
B = mergecats(B, Level1Merge_ints);
B = mergecats(B, Level1Merge_trak);
B = removecats(B,Level1Merge_other);

key_tokens.inType1 = B;

Level2Merge_sat = {'obs-sat','obs-sat-alt','obs-sat-geo','obs-sat-scat',...
    'obs-sat-pol'};
Level2Merge_mod_dyn = {'mod-dyn','mod-dyn-glob','mod-dyn-reg'};

Level2Merge_other = {'other','letters','digits','punctuation','email-address',...
    'web-address','hashtag','at-mention','emoticon','emoji','custom','converge',...
    'diverge','intensity','lat','lon','track','dir-speed','distance','duration',...
    'fd-date','fd-time','fd-tz','forecast-datetime','forecast-time','pressure',...
    'speed-kt','speed-mph','storm-no','mod', 'disc-no','ints','track', ...
    'ofc', 'sst', 'struct'};

C = mergecats(key_tokens.Type,Level2Merge_sat);
C = mergecats(C,Level2Merge_mod_dyn);
C = removecats(C,Level2Merge_other);

key_tokens.inType2 = C;

Level3Merge_other = {'other','letters','digits','punctuation','email-address',...
    'web-address','hashtag','at-mention','emoticon','emoji','custom','converge',...
    'diverge','intensity','lat','lon','track','dir-speed','distance','duration',...
    'fd-date','fd-time','fd-tz','forecast-datetime','forecast-time','pressure',...
    'speed-kt','speed-mph','storm-no','mod','obs-air','obs-surf','obs-sat',...
    'mod-dyn','mod-ens','mod-ints', 'ofc', 'sst', 'struct', 'ints',...
    'ints-rapid', 'ints-det', 'track-fix', 'disc-no'};

D = removecats(key_tokens.Type,Level3Merge_other);

key_tokens.inType3 = D;



clear B C D Level*

%% has token type in FD?

disp('Creating Boolean Indices')

for jj = 1:numTypes0
    tmp_docnos = details.DocumentNumber(details.Type == types0(jj));
    tmp_docnos = unique(tmp_docnos);
    hasType0{jj,1} = tmp_docnos;
end

clear jj tmp_*

for jj = 1:numTypes1
   
    tmp_docnos = details.DocumentNumber(details.inType1 == inType1(jj));
    tmp_docnos = unique(tmp_docnos);
    hasType1{jj,1} = tmp_docnos;
end

clear jj tmp_*

for jj = 1:numTypes2
   
    tmp_docnos = details.DocumentNumber(details.inType2 == inType2(jj));
    tmp_docnos = unique(tmp_docnos);
    hasType2{jj,1} = tmp_docnos;
end

clear jj tmp_*

for jj = 1:numTypes3
   
    tmp_docnos = details.DocumentNumber(details.inType3 == inType3(jj));
    tmp_docnos = unique(tmp_docnos);
    hasType3{jj,1} = tmp_docnos;
end

clear jj tmp_*

global hasType;
hasType = {hasType0; hasType1; hasType2; hasType3};



%% Create Indices
%Level0
types0 = categorical(types0);

%Level1
types1 = categorical(inType1);

ints_idx = find(types1 == 'ints');
track_idx = find(types1 == 'track');
conv_idx = find(types1 == 'converge');
div_idx = find(types1 == 'diverge');
mod_idx = find(types1 == 'mod');
obs_idx = find(types1 == 'obs');
ofc_idx = find(types1 == 'ofc');
sst_idx = find(types1 == 'sst');
struct_idx = find(types1 == 'struct');

%Level2
types2 = categorical(inType2);
det_idx = find(types2 == 'ints-det');
rapid_idx = find(types2 == 'ints-rapid');
dyn_idx = find(types2 == 'mod-dyn');
ens_idx = find(types2 == 'mod-ens');
mints_idx = find(types2 == 'mod-ints');
air_idx = find(types2 == 'obs-air');
surf_idx = find(types2 == 'obs-surf');
sat_idx = find(types2 == 'obs-sat');
fix_idx = find(types2 == 'track-fix');

%Level3
types3 = categorical(inType3);
glob_idx = find(types3 == 'mod-dyn-glob');
reg_idx = find(types3 == 'mod-dyn-reg');
alt_idx = find(types3 == 'obs-sat-alt');
geo_idx = find(types3 == 'obs-sat-geo');
pol_idx = find(types3 == 'obs-sat-pol');
scat_idx = find(types3 == 'obs-sat-scat');

global types;
types = {types0; types1; types2; types3};

%% Create Freq table of Tokens by FD


tmp_freq1 = cellfun(@length, hasType1);
tmp_freq2 = cellfun(@length, hasType2);
tmp_freq3 = cellfun(@length, hasType3);


tmp_freq = [tmp_freq1(1), tmp_freq1(2), tmp_freq1(3), ...
    tmp_freq1(4), tmp_freq1(5), tmp_freq1(6),...
    tmp_freq1(7), tmp_freq1(8), tmp_freq1(9),...
    tmp_freq2(1), tmp_freq2(2), tmp_freq2(3), ...
    tmp_freq2(4), tmp_freq2(5), tmp_freq2(6), ...
    tmp_freq2(7), tmp_freq2(8), tmp_freq2(9), ...
    tmp_freq3(1), tmp_freq3(2), tmp_freq3(3), ...
    tmp_freq3(4), tmp_freq3(5), tmp_freq3(6)]';

tokenFreq_FD = table(Freq_varnames', tmp_freq, ...
    'variablenames', {'type', 'frequency'});



%% Reshape details for Processing

disp('Optimizing Filestructures...(takes a few minutes)...');

tic;
global detailsRe
for kk = 1:nDiscussions
    detailsRe{kk,1} = details(details.DocumentNumber == kk,:);
end
toc;

%% Reshape hasWord based on key_tokens leveling

for zz = 1:numTypes0
    tmp_cell_idx = find(key_tokens.Type == types0(zz));
    
    tmp_T = hasWord{1}(1,:);

    for jj = 1:length(tmp_cell_idx)
        
        tmp_T = vertcat(tmp_T, hasWord{tmp_cell_idx(jj)});
        
    end
    
    tmp_T(1,:) = [];
    tmp_T = sortrows(tmp_T,'Word','ascend');
    tmp_T = sortrows(tmp_T,'Document','ascend');
    
    Level0_Cell{zz,1} = tmp_T;
    
    clear tmp_T jj tmp_cell_idx
end

for zz = 1:numTypes1
    tmp_cell_idx = find(key_tokens.inType1 == inType1{zz});
    
    tmp_T = hasWord{1}(1,:);

    for jj = 1:length(tmp_cell_idx)
        
        tmp_T = vertcat(tmp_T, hasWord{tmp_cell_idx(jj)});
        
    end
    
    tmp_T(1,:) = [];
    tmp_T = sortrows(tmp_T,'Word','ascend');
    tmp_T = sortrows(tmp_T,'Document','ascend');
    
    Level1_Cell{zz,1} = tmp_T;
    
    clear tmp_T jj tmp_cell_idx
end

  
for zz = 1:numTypes2
    tmp_cell_idx = find(key_tokens.inType2 == inType2{zz});
    
    tmp_T = hasWord{1}(1,:);

    for jj = 1:length(tmp_cell_idx)
        
        tmp_T = vertcat(tmp_T, hasWord{tmp_cell_idx(jj)});
        
    end
    
    tmp_T(1,:) = [];
    tmp_T = sortrows(tmp_T,'Word','ascend');
    tmp_T = sortrows(tmp_T,'Document','ascend');
    
    Level2_Cell{zz,1} = tmp_T;
    
    clear tmp_T jj tmp_cell_idx
end              


for zz = 1:numTypes3
    tmp_cell_idx = find(key_tokens.inType3 == inType3{zz});
    
    tmp_T = hasWord{1}(1,:);

    for jj = 1:length(tmp_cell_idx)
        
        tmp_T = vertcat(tmp_T, hasWord{tmp_cell_idx(jj)});
        
    end
    
    tmp_T(1,:) = [];
    tmp_T = sortrows(tmp_T,'Word','ascend');
    tmp_T = sortrows(tmp_T,'Document','ascend');
    
    Level3_Cell{zz,1} = tmp_T;
    
    clear tmp_T jj tmp_cell_idx
end              

global mwdCell
mwdCell = {Level0_Cell; Level1_Cell; Level2_Cell; Level3_Cell};




%% Housekeeping

disp('Cleaning Up');

clear numT* intsVars trakVars kk zz
clear *_idx types1 types2 types3 inType1 inType2 inType3
clear hasType0 hasType1 hasType2 hasType3 types0
clear Level* tmp_* tz_lookup custom_tokens Freq_varnames
clear Stripped_Disc 



