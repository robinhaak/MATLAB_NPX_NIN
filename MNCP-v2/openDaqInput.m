function objDAQIn = openDaqInput(intUseDevice,strDataOutFile,cellChannels,dblRate)
	%% set handle
	global ptrPhotoDiodeFile;
	
	%% process input
	if ~exist('intUseDevice','var') || isempty(intUseDevice)
		intUseDevice = 1;
	end
	if ~exist('strDataOutFile','var') || isempty(strDataOutFile)
		strDataOutFile = ['D:\PhotoDiodeData\PDD' getDate '_' strrep(getTime,':','-') '.csv'];
	end
	if ~exist('cellChannels','var')
		cellChannels = {'ai0'};
	end
	if ~exist('dblRate','var')
		dblRate = 1000;
	end
	
	%% setup connection
	%query connected devices
	objDevice = daq.getDevices;
	strCard = objDevice.Model;
	strID = objDevice.ID;
	
	%create connection
	objDAQIn = daq.createSession(objDevice(intUseDevice).Vendor.ID);
	
	%set variables
	objDAQIn.IsContinuous = true;
	objDAQIn.Rate=dblRate; %1ms precision
	
	%% add screen photodiode input
	for intChannel=1:numel(cellChannels)
		addAnalogInputChannel(objDAQIn,strID,cellChannels{intChannel},'Voltage');
	end
	hListener = addlistener(objDAQIn,'DataAvailable',@fPhotoDiodeCallback);
	
	%% open file
	try,fclose(ptrPhotoDiodeFile);catch,end
	ptrPhotoDiodeFile = fopen(strDataOutFile,'wt+');
	strWrite = '"TriggerTime";"TimeStamp";"Data"\n';
	fprintf(ptrPhotoDiodeFile,strWrite);
	
	%% start
	try
		startBackground(objDAQIn);
	catch ME
		%remove file
		fclose(ptrPhotoDiodeFile);
		delete(strDataOutFile);
		
		%rethrow
		rethrow(ME);
	end
end

