%test DAQ
intUseDaqDevice = 1;

%% open
dblSampRate = 10000;
objDAQOut = openDaqOutputSpritzer(intUseDaqDevice,dblSampRate);

%% prepare
dblV1 = 0;
dblV2 = 5;
dblV3 = 0;
dblDur1 = 0.01;
dblDur2 = 0.01;
stop(objDAQOut);
outputData0 = cat(1,linspace(dblV1, dblV1, round(dblSampRate*dblDur1))',linspace(dblV2, dblV2, round(dblSampRate*dblDur2))',linspace(dblV3, dblV3, round(dblSampRate*dblDur1))');
queueOutputData(objDAQOut,outputData0);
prepare(objDAQOut);

%wait & send
pause(0.1);
startBackground(objDAQOut)
disp('signal start');
pause(dblDur1+dblDur2);
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
