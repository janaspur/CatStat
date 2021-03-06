function [yrmageqcsv] = catmagdistrib(eqevents,sizenum)
% This function plots and compares the distribution of magnitude. 
%
% Input: eqevents - Earthquake events from the original catalog
%        sizenum - plot formatting option determined by catalogsize
%
% Output: yrmageqcsv - matrix contained year and magnitude information
% about the earthquake events in the catalog
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Display
%
disp('Magnitude statistics and distribution of earthquake events throughout the catalog. All other event types ignored.')
%
% Convert Time column to Years
%
time = datestr(eqevents(:,1),'yyyy');
time = str2num(time);
yrmageqcsv = horzcat(time,eqevents(:,2:5));
%
% Convert -9.9 mags to NaN
%
yrmageqcsv(yrmageqcsv(:,5)==-9.9,5) = NaN;
%
% Get data statistics
%
maxmag = max(eqevents(:,5));
minmag = min(eqevents(:,5));
zerocount = sum(eqevents(:,5) == 0);
nancount = sum(isnan(eqevents(:,5)));
%
% Remove NaN rows
%
yrmageqcsv(isnan(yrmageqcsv(:,5)),:) = [];
%
% Print Out
%
disp(['Minimum Magnitude: ',num2str(minmag)])
disp(['Maximum Magnitude: ',num2str(maxmag)])
disp([' ']);
disp(['Number of Events with Zero Magnitude: ',int2str(zerocount)])
disp(['Number of Events without a Magnitude: ',int2str(nancount)])
disp([' ']);
%
% Figure
%
figure
hold on
plot(datenum(eqevents(:,1)),eqevents(:,5),'.');
%
% Format Options
%
datetick('x')
% if sizenum == 1
%     datetick('x','yyyy')
% elseif sizenum == 2
%     datetick('x','mmmyy')
% else
%     datetick('x','mm-dd-yy')
% end
set(gca,'XTickLabelRotation',45)
set(gca,'fontsize',15)
title('All Magnitudes Through Catalog');
ylabel('Magnitude');
axis tight
hold off
drawnow
%
% End of Function
%
end