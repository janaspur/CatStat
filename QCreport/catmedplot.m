function [] = catmedplot(eqevents,ppa, min_count,reg)
% ppa=50;
% load('/Users/mrperry/Documents/MATLAB/Projects/Misc_Data/EQEVENTS.mat')
% min_count=4;
% reg = 'all';
%
% Remove NaN Magnitudes
%
eqevents(isnan(eqevents(:,5)),:) = [];
%
%
%
% Find min and max longitude of catalog events
%
maxlon = max(eqevents(:,3));
minlon = min(eqevents(:,3));
%
% Check to see if range goes over Pacific Transition Zone
%
if minlon < -170 & maxlon > 170
    %
    % Adjust event locations
    %
    for ii = 1:length(eqevents(:,3))
        if eqevents(ii,3) < 0
            eqevents(ii,3) = eqevents(ii,3)+360;
        end
    end
    %
    % Adjust World Map
    %
    load('Countries.mat');
    L = length(places);
    for ii = 1 : L
        clon=lon{ii,1};
        for jj = 1 : length(clon)
            if clon(jj) < 0
                clon(jj) = clon(jj) + 360;
            end
        end
        clon(abs(diff(clon))>359) = NaN;
        lon{ii,1}=clon;
    end
    %
    % Adjust Region
    %
    if strcmpi(reg,'all')
        poly = [];
    else
        load('regions.mat')
        ind = find(strcmpi(region,reg));
        poly = coord{ind,1};
        for ii = 1 : length(poly);
            if poly(ii,1) < 0
                poly(ii,1) = poly(ii,1)+360;
            end
        end
        poly(abs(diff(poly(:,1)))>359,1) = NaN;
    end
    %
    % Get Boundaries
    %
    maxlat = max(eqevents(:,2)); 
    minlat = min(eqevents(:,2));
    midlat = (maxlat+minlat)/2;
    maxlon = max(eqevents(:,3));
    minlon = min(eqevents(:,3));
    latbuf = 0.1*(maxlat-minlat);
    lonbuf = 0.1*(maxlon-minlon);
    mapminlon = max(minlon-lonbuf,0);
    mapmaxlon = min(maxlon+lonbuf,360);
    mapminlat = max(minlat-latbuf,-90);
    mapmaxlat = min(maxlat+latbuf,90); 
    %
    % Get XTickLabel
    %
    X = round(linspace(minlon,maxlon,10));
    X_Tick = X;
    X(X>180) = X(X>180)-360;
    X_label = num2str(X');
    %
    % Put Code here
    %
    N = sqrt(ppa);
    inc_x = 1/N;
    inc_y = 1/N;
    lower_y = min(eqevents(:,2))-inc_y;
    higher_y = max(eqevents(:,2))+inc_y;
    lower_x = min(eqevents(:,3))-inc_x;
    higher_x = max(eqevents(:,3))+inc_x;
    interval_y = [lower_y:inc_y:higher_y]';
    interval_x = [lower_x:inc_x:higher_x]';
    Median = zeros(size(interval_y,1),size(interval_x,1));
    for ii = 1 : length(interval_y)-1
        for jj = 1 : length(interval_x)-1
            Events = eqevents(eqevents(:,3) >= interval_x(jj) & ...
                eqevents(:,3) <= interval_x(jj+1) & ...
                eqevents(:,2) >= interval_y(ii) & ...
                eqevents(:,2) <= interval_y(ii+1),5);
            if size(Events,1) >= min_count
                Median(ii,jj) = median(Events);
            else
                Median(ii,jj) = NaN;
            end
        end
    end
    Median(Median == 0) = NaN;
    figure('Color','w')
    hold on
    %
    % Format Options
    %
    hchild=get(gca,'children'); %removes box outlines
    set(hchild,'edgecolor','none') %removes box outlines
    colormap(parula)
    colorbar
    set(gca,'fontsize',15)
    xlabel('Longitude','FontSize',14);
    ylabel('Latitude','FontSize',14);
    title('Median Magnitude Plot','FontSize',18)
    set(gca,'DataAspectRatio',[1,cosd(midlat),1])
    set(gca,'fontsize',15)
    %
    % Plot Adjusted World Map
    %
    for ii = 1 : L
        plot(lon{ii,1},lat{ii,1},'k')
    end
    %
    % Plot Adjusted Region
    %
    if ~isempty(poly);
        plot(poly(:,1),poly(:,2),'k--','LineWidth',2)
    end
    axis([mapminlon mapmaxlon mapminlat mapmaxlat]);
    set(gca,'XTick',X_Tick);
    set(gca,'XTickLabel',X_label);
    box on
    hold off
    drawnow  
else
    if strcmpi(reg,'all')
        X = 0;
        poly(1,1) = min(eqevents(:,3));
        poly(2,1) = max(eqevents(:,3)); 
        poly(1,2) = min(eqevents(:,2));
        poly(2,2) = max(eqevents(:,2));
    else
        X = 1;
        load('regions.mat')
        ind = find(strcmpi(region,reg));
        poly = coord{ind,1};
    end
    minlon = min(poly(:,1))-0.5;
    maxlon = max(poly(:,1))+0.5;
    minlat = min(poly(:,2))-0.5;
    maxlat = max(poly(:,2))+1.0;
    if minlon < -170 & maxlon > 170 & maxlat < 79 & minlat > -60
        maxlon = -1*min(abs(eqevents(:,3)));
        minlon = -180;
    end
    midlat = (maxlat + minlat)/2;
    %
    % Put Code Here
    %
    N = sqrt(ppa);
    inc_x = 1/N;
    inc_y = 1/N;
    lower_y = min(eqevents(:,2))-inc_y;
    higher_y = max(eqevents(:,2))+inc_y;
    lower_x = min(eqevents(:,3))-inc_x;
    higher_x = max(eqevents(:,3))+inc_x;
    interval_y = [lower_y:inc_y:higher_y]';
    interval_x = [lower_x:inc_x:higher_x]';
    Median = zeros(size(interval_y,1),size(interval_x,1));
%     Median = ones(size(interval_y,1),size(interval_x,1)).*NaN;
    for ii = 1 : length(interval_y)-1
        for jj = 1 : length(interval_x)-1
            Events = eqevents(eqevents(:,3) >= interval_x(jj) & ...
                eqevents(:,3) <= interval_x(jj+1) & ...
                eqevents(:,2) >= interval_y(ii) & ...
                eqevents(:,2) <= interval_y(ii+1),5);
            if size(Events,1) >= min_count
                Median(ii,jj) = median(Events);
%                     Median(ii,jj) = length(Events);
            else
                Median(ii,jj) = NaN;
%                 Median(ii,jj) = 0;
            end
        end
    end
%     Median(Median == 0) = NaN;
    figure; clf
    hold on
    pcolor(interval_x,interval_y,Median)
    %
    % Format Options
    %
    hchild=get(gca,'children'); %removes box outlines
    set(hchild,'edgecolor','none') %removes box outlines
    colormap(parula)
    colorbar
    set(gca,'fontsize',15)
    xlabel('Longitude','FontSize',14);
    ylabel('Latitude','FontSize',14);
    title('Median Magnitude Plot','FontSize',18)
    set(gca,'DataAspectRatio',[1,cosd(midlat),1])
    set(gca,'fontsize',15)
    plotworld
    if X == 1
        %
        % Plot region
        %
        plot(poly(:,1),poly(:,2),'k--','LineWidth',2)
    end
    axis([minlon maxlon minlat maxlat]);
    box on
    hold off
    drawnow
end
%
% End of Function
%
% end
    