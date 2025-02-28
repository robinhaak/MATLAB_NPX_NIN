function objDAQOut = openDaqOutput(intUseDevice)
	%% process input
	if ~exist('intUseDevice','var') || isempty(intUseDevice)
		intUseDevice = 1;
	end
	
	%% setup connection
	%query connected devices
	objDevice = daq.getDevices;
	strCard = objDevice.Model;
	strID = objDevice.ID;
	
	%create connection
	objDAQOut = daq.createSession(objDevice(intUseDevice).Vendor.ID);
	
	%set variables
	objDAQOut.IsContinuous = true;
	objDAQOut.Rate=1000; %1ms precision
	objDAQOut.NotifyWhenScansQueuedBelow = 100;
	
	%add IR LED output channels
	[chOut1,dblIdx1] = addAnalogOutputChannel(objDAQOut, strID, 'ao0', 'Voltage');
	[chOut2,dblIdx2] = addAnalogOutputChannel(objDAQOut, strID, 'ao1', 'Voltage');
	
	%% set LED1 off and LED2 on
	queueOutputData(objDAQOut,repmat([0 0],[100 1]));
	startBackground(objDAQOut);
	pause(0.1);
%{
%% pulse
 outputData1 = cat(1,linspace(1.5, 1.5, 500)',linspace(0, 0, 500)');
 outputData2 = linspace(3, 3, 1000)';
 queueOutputData(objDAQ,repmat([outputData1 outputData2],[5 1]));
	startBackground(objDAQ);
%}

end

