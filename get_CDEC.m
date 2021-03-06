% This function will retrieve data from the California Data Exchange Center
% (CDEC) into Matlab arrays. Requires that user knows sensor numbers and
% associated duration codes.
% R. Walters, HHWP, June 2018
% Updated Jul 2018 with additional error traps for sensor number alignment
% Updated Aug 27 2018 to account for CDEC url changes (dynamicapp)
% Updated Sept 5 2018 to account for CDEC date changes
% Updated Sept 6 2018 to account for additional CDEC changes
% Updated Sept 26 2018 to accommodate additional CDEC changes
% Updated Oct 9 2018 to accommodate additional CDEC changes
% Updated Aug 23 2019 to add error trap for irregular data streams
% Updated Nov 6 2019 to include variable arg input to turn on/off error
%                    string display to command line
%
%
%%% USAGE:
%   >> get_CDEC(station_ID, dur_code, sensor_Num, StartDate, EndDate)
%
%%% INPUTS:
%   'station_ID': three-letter station identification (from CDEC)
%   'dur_code':   duration code [e.g., 'd'=daily data, 'e'=event (15-minute)]
%   'sensor_Num': one- or two-digit sensor number (from CDEC)
%   'StartDate':  beginning date in the following format: mm/dd/yyyy
%   'EndDate':    ending date in same format as StartDate
%                 or enter 'now' for today's date
%
%%% OUTPUTS:
% 'Data':         data output array as Nx1 column vector
% 'date':         Matlab serial date array conciding with each 'Data' entry
%
%%% EXAMPLES:
% >> [t_pp, day] = get_CDEC('TUM', 'd', '45', '10/01/2010', '9/30/2011');
% gets daily incremental precipitation for the Tuolumne Meadows Met Station
% for the 2011 water year
%
% >> [Ta_moc, dt] = get_CDEC('mhh', 'e', '4', '10/01/2017', 'now');
% gets event (15-minute) air temperature for the Moccasin Met Station from
% the beginning of WY 2018 through the most current available entry

function [Data, date] = get_CDEC(station_ID, dur_code, sensor_Num, StartDate, EndDate, varargin)
% grabs cdec data and fills missing data with NaN values
% r. walters, hetch hetchy water and power, july 2018
% all inputs in single quotes. use 'now' for EndDate to run thru current
%
if ~isempty(varargin)
    dispFlag = 1;
else
    dispFlag = 0;
end

floorNow = floor(now);
if isnumeric(EndDate)
    if floor(EndDate) == floorNow
        EndDate = 'now';
    end
end

if  ( strncmpi('now', EndDate, 3) ) == 1
    furl = ['https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet?Stations=', ...
        station_ID,'&SensorNums=',sensor_Num,'&dur_code=',dur_code, ...
        '&Start=',datestr(StartDate,'yyyy-mm-dd'), ...
        '&end_date=Now'];   
else
    furl = ['https://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet?Stations=', ...
        station_ID,'&SensorNums=',sensor_Num,'&dur_code=',dur_code, ...
        '&Start=',datestr(StartDate,'yyyy-mm-dd'), ...
        '&end_date=',datestr(EndDate,'yyyy-mm-dd')];
end

catch_str = ['**cannot find cdec vars with specified parameters** \n', ...
        '**please check syntax or try again later** \n'];
try
    s = webread(furl, weboptions('CertificateFilename',''));
catch
    if dispFlag == 1
        fprintf(catch_str)
    end
    return
end

if length(s) < 100
    if dispFlag == 1
        fprintf(catch_str)
    end
    return
end

A = textscan(s,'%s %s %d %s %s %s %s %s %s','headerlines',1,'Delimiter',',');
nT = length(A{1});

dCell = ([A{5}]);          dMat = cell2mat(dCell);
date  = datenum(dMat,'yyyymmddHHMM');
dInd = ~cellfun(@isempty,dCell);

Data = str2double(A{7});
Data = Data(dInd);
Data(Data<-100) = NaN;
