%% Example DAQ data acquisition live plot and data processing with parfeval
%
% This example uses:
% * MATLAB R2017b
% * NI 9230 DAQ device or another supported device (can be simulated in NI MAX)
% * averaging_filter.m (function included with "Averaging Filter" example)
% https://www.mathworks.com/help/releases/R2017b/coder/examples/averaging-filter.html
%
% 2017/11/30 AU

%% Configure acquisition session
s = daq.createSession('ni');
[ch,idx] = addAnalogOutputChannel(s, 'PXI1Slot3', 'ao0', 'Voltage');

s.Rate = 12800;

s.IsContinuous = false;
s.DurationInSeconds = 30;


%% Create live view plot
hFig = figure;
hAxes = axes(hFig);
hLines = line(hAxes, zeros(100,2), zeros(100,2));
xlabel(hAxes, 'Time (s)')
ylabel(hAxes, 'Voltage (V)')

%% Create parpool and DataQueue
p = gcp('nocreate');
if isempty(p)
    p = parpool(2, 'IdleTimeout', inf);
end
q = parallel.pool.DataQueue;
afterEach(q, @(data) updatePlot_Callback(data, hLines));

%% Configure session DataAvailable callback function
% Compare dataAvailable_Callback2 (uses parfeval) with dataAvailable_Callback

hl = addlistener(s, 'DataAvailable', ...
   @(src, event) dataAvailable2_Callback(src, event, hLines, q));

% hl = addlistener(s, 'DataAvailable', ...
%      @(src, event) dataAvailable_Callback(src, event, hLines));

s.NotifyWhenDataAvailableExceeds = 1024;

%% Start acquisition
startBackground(s);

wait(s, 3600)

%% Clean up
clear s q



%% Local functions
function dataAvailable_Callback(~, event, hLines)
%dataAvailable_Callback Callback function for session DataAvailable listener
%

x = event.Data(:,1);
timestamps = event.TimeStamps;

y = averaging_filter(x');

set(hLines(1), 'XData', timestamps, 'YData', x);
set(hLines(2), 'XData', timestamps, 'YData', y);
drawnow limitrate
end

function dataAvailable2_Callback(~, event, hLines, q)
%dataAvailable_Callback Callback function for session DataAvailable listener
%

x = event.Data(:,1);
timestamps = event.TimeStamps;

% Process data in parallel worker with parfeval
parfeval(@averaging_filter_par, 0, x', q);

% Update live plot
% Note that line hLines(2) is updated from updatePlot_Callback with results
% from parallel worker
set(hLines(1), 'XData', timestamps, 'YData', x);
set(hLines(2), 'XData', NaN, 'YData', NaN);
drawnow limitrate

end

function averaging_filter_par(x, q)
%averaging_filter_par Wrapper for averaging_filter.m, called via parfeval
%  x is data to be processed
%  q is the DataQueue handle

y = averaging_filter(x);

% Send result to DataQueue
send(q, y);
end

function updatePlot_Callback(data, hLines)
%updatePlot_Callback Callback function for DataQueue afterEach listener

y = data;
set(hLines(2), 'YData', y);
set(hLines(2), 'XData', hLines(1).XData);
% drawnow limitrate
end