% demo.m // Charles Powell, NOAA/NESDIS/OPPA (AUG 2020)
% charles.powell@noaa.gov
%
% **********************************************************************
% DEMO FILE  -- Forecast Discussion TextScrape Project
%           
%           This demonstrates how to use the TextScrape 
%           Tools for Analysis of Forecast Discussions
%            
%           Written in Matlab 2019b
%           With Text Analytics Toolbox
%
%  REQUIRED FILES TO RUN -- Must be in current directory
%
%           discussion_analysis.m - Initialization Script
%           fd_vXX.xls - Forecast Discussion Source Data
%           reg_exp.xls - Expression Patterns Used in Tokenization
%           custom_tokens.xls - Pre-set tokens per classification schema
%           mwd.m - Calculates MWD and Bool
%           msd.m - Calculates MSD
%
% **********************************************************************

%% Initialize

% This takes several minutes. We do the heavy lifting upfront so we don't
% need to recompute everything for each MWD/MSD variant.

run discussion_analysis

%% DEMO


% Define your tokens and levels (see hierarchy guide)
%%%%%%%%
token1 = 'obs-sat';
level1 = 2;
token2 = 'ints';
level2 = 1;

% Calculate MWD and Boolean Pair
%%%%%%%
[temp_mwd,tmp_bool] = mwd(token1,level1,token2,level2);

% Calculate MSD
%%%%%%%
temp_msd = msd(token1,level1,token2,level2);


% Apply a filter (Use the T table to filter for a specific year)
%%%%%%%
selector1 = T.stormyear == 2009;
temp_mwd = temp_mwd(selector1);
temp_msd = temp_msd(selector1);

% Plot MSD and MWD histograms
%%%%%%%%
figure(1)
subplot(2,1,1)
h1 = histogram(temp_mwd,'edgecolor','none',...
    'facecolor','b','normalization','count');
ylabel('frequency')
xlabel('MWD')

subplot(2,1,2)
h2 = histogram(temp_msd,'edgecolor','none',...
    'facecolor','r','normalization','count');
ylabel('frequency')
xlabel('MSD')

titleStr = strcat("MWD and MSD between tokens  '", token1,"'  and  '", token2,"', year = 2009");
sgtitle(titleStr);

