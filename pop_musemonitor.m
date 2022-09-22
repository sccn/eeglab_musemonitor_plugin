% pop_musemonitor() - import data from Muse Monitor Android or iOS app
%
% Usage:
%   >> [EEG, com] = pop_musemonitor; % pop-up window mode
%   >> [EEG, com] = pop_musemonitor(filename);
%
% Optional inputs:
%   filename  - name of Muse Monitor .csv file
%
% Outputs:
%   EEG       - EEGLAB EEG structure
%   com       - history string
%
% Author: Arnaud Delorme, 2017-

% Copyright (C) 2017 Arnaud Delorme, arno@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Id: pop_loadbv.m 53 2010-05-22 21:57:38Z arnodelorme $
% Revision 1.5 2010/03/23 21:19:52 roy
% added some lines so that the function can deal with the space lines in the ASCII multiplexed data file

function [EEG, com] = pop_musemonitor(fileName, varargin)

com = '';
EEG = [];

if nargin < 1
    [fileName, filePath] = uigetfile2({ '*.csv' '*.CSV' }, 'Select Muse Monitor .csv file - pop_musemonitor()');
    if fileName(1) == 0, return; end
    fileName = fullfile(filePath, fileName);
    
    promptstr    = { { 'style'  'checkbox'  'string' 'Import auxilary channel' 'tag' 'aux' 'value' 0 } ...
                     { 'style'  'checkbox'  'string' 'Import power values'     'tag' 'power' 'value' 0 } ...
                     { 'style'  'checkbox'  'string' 'Import accelerometer (and gyro) values' 'tag' 'acc' 'value' 0 } ...
                     { 'style'  'checkbox'  'string' 'Import everything' 'tag' 'importall' 'value' 0 } ...
                     { } ...
                     ...
                     { 'style'  'checkbox'  'string' 'High pass filter at 0.5 Hz and reject bad channel with' 'tag' 'rejchan' 'value' 0 } ...
                     { 'style'  'edit'  'string'   '25' 'tag' 'rejchanstr'  } ...
                     { 'style'  'text'  'string'   'threshold' } ...
                     ...
                     { 'style'  'checkbox'  'string' 'High pass filter at 0.5 Hz and reject bad data (ASR) with' 'tag' 'rejdata' 'value' 0 } ...
                     { 'style'  'edit'  'string'   '11' 'tag' 'rejdatastr' } ...
                     { 'style'  'text'  'string'   'threshold' } ...
                     {} ...
                     ...
                     { 'style'  'text'      'string' 'Sampling rate' } ...
                     { 'style'  'edit'      'string' 'auto' 'tag' 'srate' } ...    
                     { } ...
                     };
    geometry = { [1] [1] [1] [1] [1] [1 0.2 0.33] [1 0.2 0.33] [1] [1 1 1] };

    [~,~,~,res] = inputgui( 'geometry', geometry, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_musemonitor'')', 'title', 'Import muse monitor data -- pop_musemonitor()');
    if isempty(res), return; end
    
    options = { 'srate' res.srate };
    if res.aux,       options = { options{:} 'aux' 'on' }; end
    if res.power,     options = { options{:} 'power' 'on' }; end
    if res.acc,       options = { options{:} 'acc' 'on' }; end
    if res.importall, options = { options{:} 'importall' 'on' }; end
    if res.rejchan,   options = { options{:} 'rejchan' str2num(res.rejchanstr) }; end
    if res.rejdata,   options = { options{:} 'rejdata' str2num(res.rejdatastr) }; end
else
    options = varargin;
end

opt = finputcheck(options, { 'aux'       'string'    { 'on' 'off' }    'off';
                             'power'     'string'    { 'on' 'off' }    'off';
                             'acc'       'string'    { 'on' 'off' }    'off';
                             'srate'     { 'string' 'real' } { {} {} } 'auto';
                             'rejchan'   'float'     { }               [];
                             'rejdata'   'float'     { }               [];
                             'importall' 'string'    { 'on' 'off' }    'off' }, 'pop_importmuse');
if isstr(opt), error(opt); end

M = importdata(fileName, ',');
headerNames =  M.textdata(1,:);
if length(headerNames) == 1, headerNames = strsplit(headerNames{1}, ','); end

% fist column (time stamp is not imported as 0)
if size(M.data,2) < length(headerNames)-1, headerNames(1)   = []; end
if size(M.data,2) < length(headerNames)  , headerNames(end) = []; end

% unique time stamps
if isnan(str2double(opt.srate)) && ~isnumeric(opt.srate)
    fprintf('Figuring out optimal sampling rate...\n');
    try
        rng('default');
        uniqueTime = unique(M.textdata(2:end,1));
        shuffleInd = shuffle([1:length(uniqueTime)]);
        timeTmp    = uniqueTime(shuffleInd(1:20));
        [pointInd,unShuffleInd] = sort(shuffleInd(1:20));
        timeTmp    = timeTmp(unShuffleInd);
        timeNum    = datenum(timeTmp)*24*3600;
        [~, ~, ~, slope, ~] = fastregress(pointInd, timeNum, 0);
        opt.srate = 1/slope;
    catch
        disp('Error while calculating sampling rate, using default 300 Hz');
        opt.srate = 300;
    end
    fprintf('Sampling rate: %2.2f Hz\n', opt.srate);
elseif ~isnumeric(opt.srate)
    opt.srate = str2double(opt.srate);
end

EEG = eeg_emptyset;
if strcmpi(opt.importall, 'on')
    allChans = 1:length(headerNames);
else
    % import channels
    realChans   = find(cellfun(@(x)~isempty(strmatch('RAW', x)), headerNames));
    for iChan = 1:length(realChans)
        headerNames{realChans(iChan)} = headerNames{realChans(iChan)}(5:end);
    end
    
    % import aux
    auxChans = [];
    if strcmpi(opt.aux, 'on')
        auxChans    = find(cellfun(@(x)~isempty(strmatch('AUX', x)), headerNames));
    end

    % import accelerometer
    accChans = [];
    if strcmpi(opt.acc, 'on')
        accChans    = find(cellfun(@(x)~isempty(strmatch('Accelerometer', x)), headerNames));
        gyroChans   = find(cellfun(@(x)~isempty(strmatch('Gyro', x)), headerNames));
        accChans = [ accChans gyroChans];
    end
    
    % power channels
    powerChans = [];
    if strcmpi(opt.power, 'on')
        deltaChans    = find(cellfun(@(x)~isempty(strmatch('Delta', x)), headerNames));
        thetaChans    = find(cellfun(@(x)~isempty(strmatch('Theta', x)), headerNames));
        alphaChans    = find(cellfun(@(x)~isempty(strmatch('Alpha', x)), headerNames));
        betaChans     = find(cellfun(@(x)~isempty(strmatch('Beta' , x)), headerNames));
        gammaChans    = find(cellfun(@(x)~isempty(strmatch('Gamma', x)), headerNames));
        powerChans    = [ deltaChans thetaChans alphaChans betaChans gammaChans];
    end
    
    allChans = [ realChans auxChans accChans powerChans];
end

EEG.chanlocs = struct('labels', headerNames(allChans));
EEG.data = M.data(:,allChans)';

% should add discontinuity here for all the NaN segments
EEG.data(:,any(isnan(EEG.data))) = [];

%EEG.data = bsxfun(@minus, EEG.data, mean(EEG.data,2));
EEG.pnts   = size(EEG.data,2);
EEG.nbchan = size(EEG.data,1);
EEG.xmin = 0;
EEG.trials = 1;
EEG.srate = opt.srate;
EEG = eeg_checkset(EEG);

if EEG.pnts < 1000
    fprintf(2, 'Data is too short to apply artifact rejection')
else
    fprintf('\nApplying artifact rejection, please cite\n  A. Delorme and J. A. Martin, "Automated Data Cleaning for the Muse EEG,"\n  2021 IEEE International Conference on Bioinformatics and \n  Biomedicine (BIBM), 2021, pp. 1-5, doi: 10.1109/BIBM52615.2021.9669415.\n\n');
    if ~isempty(opt.rejchan) && ~isempty(opt.rejdata)
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion',opt.rejchan,'LineNoiseCriterion',5,'Highpass',[0.25 0.75],'BurstCriterion',opt.rejdata,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
    elseif ~isempty(opt.rejchan) 
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion',opt.rejchan,'LineNoiseCriterion',5,'Highpass',[0.25 0.75],'BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian','WindowCriterionTolerances','off');
    elseif ~isempty(opt.rejdata)
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass',[0.25 0.75],'BurstCriterion',opt.rejdata,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
    end
end

if isempty(options)
    com = sprintf('EEG = pop_musemonitor(''%s'');', fileName);
else
    com = sprintf('EEG = pop_musemonitor(''%s'', %s);', fileName, vararg2str(options));
end
