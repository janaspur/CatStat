function [nn,xx,maxlon] = catdensplot(catalog,compmag)
% This function creates a seismicity density map for the catalog
% Input: a structure containing normalized catalog data
%         cat.name   name of catalog
%         cat.file   name of file contining the catalog
%         cat.data   real array of origin-time, lat, lon, depth, mag 
%         cat.id     character cell array of event IDs
%         cat.evtype character cell array of event types 
%         ** Hoping to add polygon for catalog as well
% Output: None

maxlat = max(catalog.data(:,2)); 
minlat = min(catalog.data(:,2));     
maxlon = max(catalog.data(:,3));     
minlon = min(catalog.data(:,3));
latbuf = 0.1*(maxlat-minlat);
lonbuf = 0.1*(maxlon-minlon);

[nn,xx] = hist(catalog.data(:,3),[minlon:0.1:maxlon]);

%hist2d(datenum(catalog.data(:,1)),catalog.data(:,5),min(datenum(catalog.data(:,1))):365:max(datenum(catalog.data(:,1))),0:0.5:maxmag);

hist2d(catalog.data(:,3),catalog.data(:,2))
ax = gca;
ax.YDir = 'normal';
colormap([[1,1,1];jet(max(nn(:)))])
set(gca,'fontsize',15)
hold on

% load ./Data/coastline.data
% coastline(coastline == 99999) = NaN;
% clat = coastline(:,2);
% clon = coastline(:,1);
% clon(abs(diff(clon))>180) = NaN;
% plot(clon,clat,'color',[0.6 0.6 0.6],'linewidth',1)
% xlabel('Longitude');
% ylabel('Latitude');
% hold on

figure
hist3(catalog.data(:,2:3),[50 50])
ax = gca;
ax.YDir = 'reverse';

%figure
% % plot quakes
% plot(catalog.data(:,3),catalog.data(:,2),'r.')
% daspect([1,1,1]);
% set(gca,'fontsize',15)
% axis([minlon maxlon minlat maxlat]);
% hold on
% 
% % load, process, and plot coastline data
% load ./Data/coastline.data
% coastline(coastline == 99999) = NaN;
% clat = coastline(:,2);
% clon = coastline(:,1);
% clon(abs(diff(clon))>180) = NaN;
% plot(clon,clat,'k','linewidth',1)
% xlabel('Longitude');
% ylabel('Latitude');
% hold on