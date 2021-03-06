function [missing, dist, dep, mags, both, matching, auth_cat1, non_auth_cat1,...
        nonauth_matching,nonauth_missing] = compareevnts_mp(cat1,cat2,tmax,...
    delmax,magdelmax,depdelmax,reg)
% This function compares entries in the catalog to determine events that
% either match or do not meet the matching criteria.  Those that do not
% meet the matching criteria as delineated into 3 subcategories: locations
% not close enough (dist), depth residual outside limit (dep), and
% magnitude residual outside limit (mag).  Ideally, the number of events
% not matching and the number of events matching should equal the number of
% events in the catalogs.  If this does not occur, duplicate events are
% present in either of the catalogs.  A later version of this function will
% address this issue, but for now a message will print out if duplicate
% events are possible.
%
% Inputs - 
%   cat1 - Catalog 1 information and data
%   cat2 - Catalog 2 information and data
%   tmax - Maximum time window for matching events
%   delmax - Maximum location difference for matching events
%   magdelmax - Maximum magnitude residual for matching events
%   depdelmax - Maximum depth residual for matching events
%
% Outputs -
%   missing - data for the events missing from either catalog
%   dist - data for the events that match in time but not location
%   dep - data for the events that match in time and location but not depth
%   mags - data for the events that match in time, location, and depth, but
%   not magnitude.
%   types - SECTION NOT COMPLETE YET
%   matching - data for the events that met all the matching criteria
%   dup - Possible list of duplicate events
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Begin function
%
% Useful variables
%
sec_per_day = 86400;
%
% Convert Time window
%
tmax = tmax/sec_per_day;
time_window =1*24*60*60; %1 day time window
time_window = time_window/sec_per_day;
%
% Empty matrices
%
missing.events1 = []; missing.ids1 = []; missing.type1=[];
missing.events2 = []; missing.ids2 = []; missing.type2=[];
dist.events1 = []; dist.ids1 = []; dist.type1 = [];
dist.events2 = []; dist.ids2 = []; dist.type2 = [];
dep.events1 = []; dep.events2 = []; dep.ids= []; dep.type = [];
mags.events1 = []; mags.events2 = []; mags.ids = []; mags.type = [];
both.events1 = []; both.events2 = []; both.ids = []; both.types = [];
matching.events1 =[]; matching.events2 = []; matching.ids = [];
used_ind1 = []; used_ind2 = []; 
matching_inds=[];
missing_ind1 = []; 
dep_inds = [];
mag_ind = [];
both_ind = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Get array of matching and mismatching event ids; using ismember will not
% work.  
%
% What is the best way to ensure events are parsed in more than one
% category.  First, check for duplicate events in each catalog by finding
% the number of unique events.  Remove these events and display them as
% duplicates not considered in the analysis.  Shouldn't be any, but just in
% case
%
% Catalog 1
%
[~,uniqueIdx1] = unique(cat1.id(:,1));
Cat1_dups = cat1.id(:,1);
Cat1_dups(uniqueIdx1) = [];
Cat1_dups = unique(Cat1_dups);
if ~isempty(Cat1_dups)
    Cat1_dups_ind = find(strcmpi(Cat1_dups, cat1.id));
    duplicates.ids1 = cat1.ids(Cat1_dups_ind);
    duplicates.events1 = cat1.data(Cat1_dups_ind);
    duplicates.type1 = cat1.evtype(Cat1_dups_ind);
    % Remove Duplicates from list
    cat1.id(Cat1_dups_ind,:) = [];
    cat1.data(Cat1_dups_ind,:) = [];
    cat1.evtype(Cat1_dups_ind,:) = [];
end
%
% Catalog 2
%
[~,uniqueIdx2] = unique(cat2.id(:,1));
Cat2_dups = cat2.id(:,1);
Cat2_dups(uniqueIdx2) = [];
Cat2_dups = unique(Cat2_dups);
if ~isempty(Cat2_dups)
    Cat2_dups_ind = find(strcmpi(Cat2_dups, cat2.id));
    duplicates.ids1 = cat2.ids(Cat2_dups_ind);
    duplicates.events1 = cat2.data(Cat2_dups_ind);
    duplicates.type1 = cat2.evtype(Cat2_dups_ind);
    % Remove duplicates from list
    cat2.id(Cat2_dups_ind,:) = [];
    cat2.data(Cat2_dups_ind,:) = [];
    cat2.evtype(Cat2_dups_ind,:) = [];
end
%
% Compare catalog 1 events with catalog 2 events
%
for ii = 1 : length(cat1.data)
    %
    % Find those events indices within 1 day
    %
    cat2_ind = find(abs((cat1.data(ii,1)-cat2.data(:,1)))<=time_window);
    %
    % Check for matching ids
    %
    cat2match_ind = find(strcmpi(cat1.id(ii,1),cat2.id(cat2_ind,:)));
    cat2match_ind = cat2_ind(cat2match_ind);
    if ~isempty(cat2match_ind) && ~isempty(cat2_ind) ...
            && ~ismember(ii,used_ind1) && ~ismember(cat2match_ind,used_ind2)
        matching_inds = [matching_inds;ii, cat2match_ind];
        used_ind1 = [used_ind1;ii];
        used_ind2 = [used_ind2;cat2match_ind];
    else
    %
    clear C;
    C(:,1) = (cat1.data(ii,1)-cat2.data(cat2_ind,1))./tmax;
    C(:,2) = distance_hvrsn(cat1.data(ii,2),cat1.data(ii,3),cat2.data(cat2_ind,2),cat2.data(cat2_ind,3))./delmax;
    C(:,3) = (cat1.data(ii,4) - cat2.data(cat2_ind,4))./depdelmax;
    C(:,4) = (cat1.data(ii,5) - cat2.data(cat2_ind,5))./magdelmax;
    %
    % Minimize L2 norm of each row
    %
    [~,ind] = min(sqrt(sum(abs(C).^2,2)));
    %
    % Event of Interest row index in catalog 2
    %
    EOI = cat2_ind(ind);
    %
    % Check to make sure C(ind,1)
    %
        if isempty(C)
%             m=m+1;
%             missing.events1(m,:) = cat1.data(ii,:);
%             missing.ids1{m,1} = char(cat1.id{ii,1});
              missing_ind1 = [missing_ind1;ii];
              used_ind1=[used_ind1;ii];
        elseif abs(C(ind,1)) > 1
%             m=m+1;
%             missing.events1(m,:) = cat1.data(ii,:);
%             missing.ids1{m,1} = char(cat1.id{ii,1});
              missing_ind1 = [missing_ind1;ii];
              used_ind1 = [used_ind1;ii];
        %
        % If time match, check distance
        %
%         elseif abs(C(ind,1)) <= 1 && C(ind,2) > 1 ...
%                 && ~ismember(ii,used_ind) && ~ismember(EOI,used_ind)
%             if isempty(find(strcmp(cat2.id{EOI,:},matching.ids(:,1))))
%                 d=d+1;
%                 dist.events1(d,:) = [cat1.data(ii,:),C(ind,2)*delmax];
%                 dist.events2(d,:) = cat2.data(EOI,:);
%                 dist.ids1{d,1} = char(cat1.id{ii,:});
%                 dist.ids1{d,2} = char(cat2.id{EOI,:});
%                 used_ind = [used_ind;ii,EOI];
%             end
%
% If event isn't missing, it has a match!!!
%
        elseif ~ismember(ii,used_ind1) && ~ismember(EOI,used_ind2)
        %
        % If both time and distance are within tolerance, we have a match
        %
%             M=M+1;
%             row = [cat1.data(ii,:),C(ind,2)*delmax,C(ind,3)*depdelmax,C(ind,4)*magdelmax,C(ind,1)*tmax*sec_per_day];
%             matching.data(M,:) = row;
%             matching.data2(M,:) = cat2.data(EOI,:);
%             matching.ids{M,1} = char(cat1.id{ii,1});
%             matching.ids{M,2} = char(cat2.id{EOI,1});
            matching_inds = [matching_inds;ii,EOI];
            used_ind1 = [used_ind1;ii];
            used_ind2 = [used_ind2;EOI];
            %
            % Now check matching events for differences in depth and
            % magnitude; these CAN be used indices!
            %
            if abs(C(ind, 3)) > 1 & abs(C(ind,4)) <= 1
                dep_inds = [dep_inds;ii, EOI];
%                 D=D+1;
%                 dep.events1(D,:) = [cat1.data(ii,:),C(ind,3)*depdelmax];
%                 dep.events2(D,:) = cat2.data(EOI,:);
%                 dep.ids{D,1} = char(cat1.id{ii,:});
%                 dep.ids{D,2} = char(cat2.id{EOI});
                %dep.type = [dep.type; char(cat1.evtype(ii,:))];
            elseif abs(C(ind, 3)) <= 1 && abs(C(ind,4)) > 1
                %
                % If magnitude residual is too great, but dep red in tolerance
                %
                mag_inds = [mag_ind;ii,EOI];
%                 G=G+1;
%                 mags.events1(G,:) = [cat1.data(ii,:),C(ind,4)*magdelmax];
%                 mags.events2(G,:) = cat2.data(EOI,:);
%                 mags.ids{G,1} = char(cat1.id{ii,1});
%                 mags.ids{G,2} = char(cat2.id{EOI,1});
                %mags.type = [mags.type; char(cat1.evtype(ii,:))];
            elseif abs(C(ind, 3)) > 1 && abs(C(ind, 4)) > 1
                %
                % If both mag res and dep res out of tolerance
                %
                both_inds = [both_inds;ii,EOI];
%                 B=B+1;
%                 both.events1(B,:) = [cat1.data(ii,:),C(ind,3)*depdelmax,C(ind,4)*magdelmax];
%                 both.events2(B,:) = (cat2.data(EOI,:));
%                 both.ids{B,1} = char(cat1.id{ii,1});
%                 both.ids{B,2} = char(cat2.id{EOI,1});
%                 %both.type = [both.type; char(cat1.evtype(ii,:))];
            end
        end
    end
end
%
% Those that don't match Cat1 to Cat2 will be missing from Cat2 or Cat1
% respectively.
%
missing_ind2 = find(~ismember(cat2.id(matching_inds(:,2),:),cat2.id));
% Parse out Matching data structure
% IDS
matching.ids = cell(size(matching_inds,1),2);
matching.ids(:,1) = cat1.id(matching_inds(:,1),:);
matching.ids(:,2) = cat2.id(matching_inds(:,2),:);
% Data
matching.data =[cat1.data(matching_inds(:,1),:), ...
            distance_hvrsn(cat1.data(matching_inds(:,1),2),cat1.data(matching_inds(:,1),3),cat2.data(matching_inds(:,2),2),cat2.data(matching_inds(:,2),3)),...
            cat1.data(matching_inds(:,1),4) - cat2.data(matching_inds(:,2),4),...
            cat1.data(matching_inds(:,1),5) - cat2.data(matching_inds(:,2),5),...
            cat1.data(matching_inds(:,1),1)-cat2.data(matching_inds(:,2),1)];
matching.data2 = cat2.data(matching_inds(:,2),:);
% Type
matching.type = cell(size(matching_inds,1),2);
matching.type(:,1) = cat1.evtype(matching_inds(:,1),:);
matching.type(:,2) = cat2.evtype(matching_inds(:,2),:);
%
% Missing Events!!!!
%
%
% Parse out Events from Catalog 1 that are missing from catalog 2
%
if ~isempty(missing_ind1)
    missing.ids1 = cell(size(missing_ind1,1),1);
    missing.events1 = cat1.data(missing_ind1,:);
    missing.ids1(:,1) = cat1.id(missing_ind1,:);
    missing.type = cell(size(missing_ind1,1),1);
    missing.type = cat1.evtype(missing_ind1,:);
end
% Parse out Events from Catalog 2 that are missing from catalog 1
if ~isempty(missing_ind2)
    missing.ids2 = cell(size(missing_ind2,1),1);
    missing.events2 = cat2.data(missing_ind2,:);
    missing.ids2(:,1) = cat2.id(missing_ind2,:);
    missing.type = cat2.evtype(missing_ind2,:);
end
%
% Authoritative ID Check; 
%
non_auth_cat1 = find(~strncmpi(reg,cat1.id(:,1),2));
if ~isempty(matching.ids)
auth_cat1 = find(strncmpi(reg,matching.ids(:,1),2)); 
nonauth_matching.ids = matching.ids(~strncmpi(reg,matching.ids(:,1),2),:);
nonauth_matching.data = matching.data(~strncmpi(reg,matching.ids(:,1),2),:);
nonauth_matching.data2 = matching.data2(~strncmpi(reg,matching.ids(:,1),2),:);
end
%
% Nonauthoritative missing
%
if ~isempty(missing.ids1)
nonauth_missing.ids = missing.ids1(~strncmpi(reg,missing.ids1(:,1),2),:);
nonauth_missing.data = missing.events1(~strncmpi(reg,missing.ids1(:,1),2),:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Summary Information
%
disp('-- Number of events after filtering --')
disp([num2str(length(cat1.data(:,1))),' ',cat1.name,' events in the target region.'])
disp([num2str(length(cat2.data(:,1))),' ',cat2.name,' events in the target region.'])
disp(' ')
%
%Matching Events
%
disp('      ---------------- MATCHING EVENTS ----------------    ')
if ~isempty(matching.data)
    disp([num2str(size(matching_inds,1)),' ',cat1.name,' and ',cat2.name, ' meet matching criteria.'])
else
    disp('No matching events')
end
disp(' ')
%
% Missing Events
%
disp('   -------------------- MISSING EVENTS --------------------   ')
disp(' ')
disp('                  ---Total Missing Events---')
if ~isempty(missing.events1) 
    disp(['There are ',num2str(size(missing.events1,1)),' event(s) in ',cat1.name])
    disp(['missing from ',cat2.name])
else
    disp(['There are 0 event(s) in ',cat1.name,' missing from ',cat2.name])
end
if ~isempty(missing.events2)
    disp(['There are ',num2str(size(missing.events2,1)),' event(s) in ',cat2.name])
    disp(['missing from ',cat1.name])
    disp(' ')
else
    disp(['There are 0 event(s) in ',cat2.name,' missing from ',cat1.name])
end
disp('---- No Similar Origin Times ----')
if ~isempty(missing.events1)
    disp([num2str(size(missing_ind1,1)),' event(s) in ', cat1.name, ' have origin times not in ', cat2.name])
else
    disp(['0 event(s) in ',cat1.name, ' have origin time not in ', cat2.name])
end
if ~isempty(missing.events2)
    disp([num2str(size(missing_ind2,1)), ' event(s) in ', cat2.name, ' have origin times not in ', cat1.name])
	disp(' ')
else
    disp(['0 event(s) in ',cat2.name, ' have origin time not in ', cat1.name])
	disp(' ')
end
% %
% %Locations not similar
% %
% if ~isempty(dist.events1)
% 	disp('---- Match in time but NOT location ----')
% 	disp([num2str(d),' events matched in time but location differences were greater than ',num2str(delmax),' km apart']);
% end
% disp(' ')
%
%Matching events that have possible data errors
%
disp(['-------------------- POSSIBLE PROBLEM EVENTS ---------------    '])
if ~isempty(dep.events1)
	disp([num2str(D),' events matched origin time, location, and magnitude, but depths were greater than ',num2str(depdelmax),' km apart']);
end
if ~isempty(mags.events1)
	disp([num2str(G),' events matched in origin time, location and depth, but magnitude residuals were greater than ',num2str(magdelmax),'.']);
end
if ~isempty(both.events1)
	disp([num2str(B),' events matched in origin time and location, but magnitude and depth residuals were greater than ',num2str(magdelmax),' and ',num2str(depdelmax),' km, respectively.']);
end
disp(' ')
%
%Possible Duplicate Events
%
FormatSpec1 = '%-20s %-20s %-8s %-9s %-7s %-7s %-7s %-7s %-7s %-7s\n';
FormatSpec2 = '%-20s %-20s %-8s %-9s %-7s %-7s \n';
if length(cat1.data(:,1)) < size(missing_ind1,1)+size(matching_inds,1)...
    || length(cat2.data(:,1)) < size(missing_ind2,1)+size(matching_inds,1)
    disp('--------MULTIPLE EVENT MATCHES-----------')
    disp('')
    %
    % Check for unique IDs in catalog 1
    %
    [~,uniqueIdx1] = unique(matching.ids(:,1));
    dups1 = matching.ids(:,1);
    dups1(uniqueIdx1) = [];
    dups1 = unique(dups1);
    if ~isempty(dups1)
        disp(['Multiple matches in ',cat1.name,' with events in ',cat2.name,'--------'])
        fprintf(FormatSpec1,'Event ID', 'Origin Time','Lat.','Lon.','Dep(km)','Mag','LocRes','DepRes','magRes','TimeRes')
        for ii = 1 : size(dups1,1)
            dups_idx1 = find(strcmpi(dups1(ii,1),matching.ids(:,1)));
            %
            % Only print the duplicate event once
            %
            fprintf(FormatSpec2,matching.ids{dups_idx1(1),1}, datestr(matching.data(dups_idx1(1),1),'yyyy/mm/dd HH:MM:SS'),num2str(matching.data(dups_idx1(1),2)),num2str(matching.data(dups_idx1(1),3)),num2str(matching.data(dups_idx1(1),4)),num2str(matching.data(dups_idx1(1),5)));
            disp('**')
            for jj = 1 : size(dups_idx1)
                %
                % Print the events from catalog 2
                %
                fprintf(FormatSpec1,matching.ids{dups_idx1(jj),2}, datestr(matching.data2(dups_idx1(jj),1),'yyyy/mm/dd HH:MM:SS'),num2str(matching.data2(dups_idx1(jj),2)),num2str(matching.data2(dups_idx1(jj),3)),num2str(matching.data2(dups_idx1(jj),4)),num2str(matching.data2(dups_idx1(jj),5)),num2str(matching.data(dups_idx1(jj),6)),num2str(matching.data(dups_idx1(jj),7)),num2str(matching.data(dups_idx1(jj),8)),num2str(matching.data(dups_idx1(jj),9)));
            end
            disp('--')
        end
    end
    %
    % Repeat for catalog 2 events
    %
    [~,uniqueIdx2] = unique(matching.ids(:,2));
    dups2 = matching.ids(:,1);
    dups2(uniqueIdx2) = [];
    dups2 = unique(dups2);
    if ~isempty(dups2)
        disp(['Multiple matches in ',cat2.name,' with events in ',cat1.name,'--------'])
        fprintf(FormatSpec1,'Event ID', 'Origin Time','Lat.','Lon.','Dep(km)','Mag','LocRes','DepRes','magRes','TimeRes')
        for ii = 1 : size(dups2,1)
            dups_idx2 = find(strcmpi(dups2(ii,1),matching.ids(:,2)));
            %
            % Only print the duplicate event once
            %
            fprintf(FormatSpec2,matching.ids{dups_idx2(1),2}, datestr(matching.data2(dups_idx2(1),1),'yyyy/mm/dd HH:MM:SS'),num2str(matching.data2(dups_idx2(1),2)),num2str(matching.data2(dups_idx2(1),3)),num2str(matching.data2(dups_idx2(1),4)),num2str(matching.data2(dups_idx2(1),5)));
            disp('***')
            for jj = 1 : size(dups_idx2)
                %
                % Print the events from catalog 2
                %
                fprintf(FormatSpec1,matching.ids{dups_idx2(jj),1}, datestr(matching.data(dups_idx2(jj),1),'yyyy/mm/dd HH:MM:SS'),num2str(matching.data(dups_idx2(jj),2)),num2str(matching.data(dups_idx2(jj),3)),num2str(matching.data(dups_idx2(jj),4)),num2str(matching.data(dups_idx2(jj),5)),num2str(matching.data(dups_idx2(jj),6)),num2str(matching.data(dups_idx2(jj),7)),num2str(matching.data(dups_idx2(jj),8)),num2str(matching.data(dups_idx2(jj),9)));
            end
            disp('--')
        end
    end      
end
% %
% %End of function
% %
end
