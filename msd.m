% msd.m // Charles Powell, NOAA/NESDIS/OPPA (AUG 2020)
% charles.powell@noaa.gov 
% PRE-RELEASE VERSION 0.4
% ************************************************************************
% Calculates MSD of matching token

function [MSD]= msd(tokenA,levelA,tokenB,levelB)

% **** INPUT ****
    % tokenA = string value of Type in key_tokens
    % levelA = numeric level 0-3; tokenA must exist at this hierarchy level; 
    %           the heighest level is recommended to ensure full counting
    %
    % tokenB = string value of Type in key_tokens
    % levelB = numeric level 0-3;

% **** OUTPUT ****
    % MSD = double of nDiscussion length; each value corresponds to the minimum
    %       sentence distance between the two selected tokens for each forecast
    %       discussion. 
    %       NaNs = one or both tokens do not appear in the particular forecast
    %       discussion
    
% **** GLOBALS ****
    % Currently, we pass nDiscussions, types, hasType and detailsRe from
    % initailizaton script here as a global. This means we don't have to
    % call it for every calculation. 

global nDiscussions types hasType detailsRe


A_idx = find(types{levelA+1} == tokenA);
B_idx = find(types{levelB+1} == tokenB);

init_MSD = nan(nDiscussions,1);

% Boolean Comparison

for kk = 1:nDiscussions
    
    tmpBool(kk) = sum(hasType{levelA + 1}{A_idx} == kk) & ...
        sum(hasType{levelB + 1}{B_idx} == kk);
end


for kk = 1:nDiscussions

        if tmpBool(kk) == 1
            tmp_T = detailsRe{kk};
            tmp_idx_A = tmp_T{:,levelA+7} == tokenA;

            % find the sentence in a FD where the first token appears

            tmp_sentA = tmp_T.SentenceNumber(tmp_idx_A);
            
            % Error Handling
            if isempty(tmp_sentA) == 1
                tmp_match = NaN;
                init_MSD(kk) = tmp_match;
                
            else
                 %find the sentence in a FD where the second token appears

                tmp_idx_B = tmp_T{:,levelB+7} == tokenB;
                tmp_sentB = tmp_T.SentenceNumber(tmp_idx_B);

                % Either token can appear multiple times in a FD, so the    
                % number of pairwise "distances" grows ~#A X #B. 
                
                % This loops through all of the values in B and collapses
                % to a min distance.
            
                for jj = 1:length(tmp_sentB)
                    tmp_matchDiff(jj) = min(abs(tmp_sentB(jj) - tmp_sentA));
                    tmp_minMatch = min(tmp_matchDiff);

                    init_MSD(kk) = tmp_minMatch;
                end
                clear tmp_*
            end
        end
end

MSD = init_MSD;
end


                
                

            