% mwd.m // Charles Powell, NOAA/NESDIS/OPPA (AUG 2020)
% charles.powell@noaa.gov 
% PRE-RELEASE VERSION 0.4
% ************************************************************************
% Calculates MWD and Bool of matching token

function [MWD, Bool]= mwd(tokenA,levelA,tokenB,levelB)

% **** INPUT ****
    % tokenA = string value of Type in key_tokens
    % levelA = numeric level 0-3; tokenA must exist at this hierarchy level; 
    %           the heighest level is recommended to ensure full counting
    %
    % tokenB = string value of Type in key_tokens
    % levelB = numeric level 0-3;

% **** OUTPUT ****
    % MWD = double of nDiscussion length; each value corresponds to the minimum
    %       word distance between the two selected tokens for each forecast
    %       discussion. 
    %       NaNs = one or both tokens do not appear in the particular forecast
    %       discussion
    % Bool= bool of nDiscussion length;
    %       logical 1 = discussion has both tokens in a particular FD
    %       logical 0 = discussion does not have both tokens in a FD
    
    
% **** GLOBALS ****
    % Currently, we pass nDiscussions, types, hasType and mwdCell from
    % initailizaton script here as a global. This means we don't have to
    % call it for every calculation. 

global nDiscussions types hasType mwdCell


A_idx = find(types{levelA+1} == tokenA);
B_idx = find(types{levelB+1} == tokenB);

init_MWD = nan(nDiscussions,1);

% Boolean Comparison
for kk = 1:nDiscussions
    
    tmpBool(kk) = sum(hasType{levelA + 1}{A_idx} == kk) & ...
        sum(hasType{levelB + 1}{B_idx} == kk);
end

Bool = tmpBool;


for kk = 1:nDiscussions

        if tmpBool(kk) == 1 

            % find the sentence in a FD where the first token appears
            
            tmp_sentA = mwdCell{levelA+1}{A_idx}.Word(mwdCell{levelA+1}{A_idx}.Document == kk);

            % Error Handling
            if isempty(tmp_sentA) == 1
                tmp_match = NaN;
                init_MWD(kk) = tmp_match;
                
                %find the sentence in a FD where the second token appears
            else
                tmp_sentB = mwdCell{levelB+1}{B_idx}.Word(mwdCell{levelB+1}{B_idx}.Document == kk);
                
                
                % Either token can appear multiple times in a FD, so the    
                % number of pairwise "distances" grows ~#A X #B. 
                
                % This loops through all of the values in B and collapses
                % to a min distance.

                for jj = 1:length(tmp_sentB)
                    tmp_matchDiff(jj) = min(abs(tmp_sentB(jj) - tmp_sentA));
                    tmp_minMatch = min(tmp_matchDiff);

                    init_MWD(kk) = tmp_minMatch;
                end
                clear tmp_* jj
            end
        end
end

MWD = init_MWD;
end

