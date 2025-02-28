%test DAQ
intUseDaqDevice = 1;

%% open
dblSampRate = 10000;
objDAQOut = openDaqOutputOptoSpritzer(intUseDaqDevice,dblSampRate);

%% prepare
dblV1 = 0;
dblV2 = 3;
dblV3 = 0;
dblDur1 = 0.010;
dblDur2 = 0.500;

outputData0 = cat(1,linspace(dblV1, dblV1, round(dblSampRate*dblDur1))',linspace(dblV2, dblV2, round(dblSampRate*dblDur2))',linspace(dblV3, dblV3, round(dblSampRate*dblDur1))');


%prepare 
dblStimReps = 5;
dblHz = 10;
vecOff = dblV1*ones(round(dblSampRate/(dblHz*2)),1);
vecOn = dblV2*ones(round(dblSampRate/(dblHz*2)),1);
vecStim = repmat(cat(1,vecOff,vecOn),[dblStimReps 1]);
outputData1 = cat(1,vecStim,vecOff);

stop(objDAQOut);
queueOutputData(objDAQOut,[outputData1 outputData1]);
prepare(objDAQOut);

%wait & send
pause(0.1);
startBackground(objDAQOut)
disp('signal start');
pause(numel(outputData1)/dblSampRate);
disp('signal end');

%% close
closeDaqOutput(objDAQOut);

try
	queueOutputData(objDAQOut,[0 0]);
	startBackground(objDAQOut);
	pause(0.1);
catch
end

%% close connection
try,stop(objDAQOut);catch,end

closeDaqOutput(objDAQOut);
