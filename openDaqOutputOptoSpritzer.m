function objDAQOut = openDaqOutputOptoSpritzer(intUseDevice,dblSampRate)
	%% process input
	if ~exist('intUseDevice','var') || isempty(intUseDevice)
		intUseDevice = 1;
	end
	if ~exist('dblSampRate','var') || isempty(dblSampRate)
		dblSampRate = 10000;
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
	objDAQOut.Rate=round(dblSampRate); %1ms precision
	objDAQOut.NotifyWhenScansQueuedBelow = 100;
	
	%add picospritzer output channels
	[chOut0,dblIdx0] = addAnalogOutputChannel(objDAQOut, strID, 'ao0', 'Voltage');
	
	%add opto LED output channels
	[chOut1,dblIdx1] = addAnalogOutputChannel(objDAQOut, strID, 'ao1', 'Voltage');
	
	%% set spritzer off
	dblStartT = 0.1;
	queueOutputData(objDAQOut,repmat([0 0],[ceil(objDAQOut.Rate*dblStartT) 1]));
	startBackground(objDAQOut);
	pause(dblStartT);
%{
%% pulse
 outputData1 = cat(1,linspace(1.5, 1.5, 500)',linspace(0, 0, 500)');
 outputData2 = linspace(3, 3, 1000)';
 queueOutputData(objDAQ,repmat([outputData1 outputData2],[5 1]));
	startBackground(objDAQ);
%}

end

