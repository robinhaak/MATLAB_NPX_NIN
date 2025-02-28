
% Create connection (edit the IP address)
hSGL = SpikeGL('127.0.0.1');

%retrieve channels to save
warning('off','CalinsNetMex:connectionClosed');
vecSaveChans = GetSaveChans(hSGL, 0);
warning('on','CalinsNetMex:connectionClosed');

%set meta data, can be anything, as long as it's a numeric scalar or string
sMeta = struct();
sMeta.animal = 'Mr. Mouse';
SetMetaData(hSGL, sMeta);

%set run name
intBlock = 0;
boolAccepted = false;
while ~boolAccepted
	intBlock = intBlock + 1;
	strRunName = strcat('Exp',getDate,sprintf('R%02d',intBlock));
	try
		SetRunName(hSGL, strRunName);
		boolAccepted = true;
	catch
		boolAccepted = false;
	end
	if intBlock > 99
		error([mfilename ':NameNotAccepted'],'Run names are not accepted... Something is wrong');
	end
end

%get parameters for this run
sParamsSGL = GetParams(hSGL);

%set stream IDs
vecStreamIM = [0];
strStreamIM = sprintf( 'GETSCANCOUNT %d', vecStreamIM(1) );
intStreamNI = -1;
strStreamNI = sprintf( 'GETSCANCOUNT %d', intStreamNI );

%get probe ID
[cellSN,vecType] = GetImProbeSN(hSGL, vecStreamIM(1));

%get NI channels
vecChPerTypeNI = GetAcqChanCounts(hSGL, intStreamNI);
dblSampRateNI = GetSampleRate(hSGL, intStreamNI);

%get number of channels per type
vecChPerType = GetAcqChanCounts(hSGL, vecStreamIM(1));
vecChansAP = 1:vecChPerType(1);
dblSampRateIM = GetSampleRate(hSGL, vecStreamIM(1));
vecChansLFP = (vecChPerType(1)+1):(vecChPerType(1)+vecChPerType(2));
intChanPulse = sum(vecChPerType); %last channel

%start recording
SetRecordingEnable(hSGL, 1);
hTicStart = tic;
pause(1);

%check if output is being saved
boolSaving = IsSaving(hSGL);

%set initial retrieval count at current count when experiment starts
intLastFetchIM = GetScanCount(hSGL, vecStreamIM(1));

%set initial retrieval count at current count when experiment starts
intLastFetchNI = GetScanCount(hSGL, intStreamNI);

%set fetching variables IM
dblBufferT_IM = 5; %requested buffer size in seconds, TDT: 15
dblReqSampIM = 1000; %requested sampling rate in Hz
intDownsampleIM = round(dblSampRateIM/dblReqSampIM); %downsampling factor
intBufferN_IM = round(dblBufferT_IM*(dblSampRateIM/intDownsampleIM)); %buffer size
dblBufferSampIM = intBufferN_IM/dblBufferT_IM; %resultant buffer sampling rate
vecFetchChansIM = cat(2,vecChansLFP,intChanPulse) - 1; %channels start at 0, so deduct 1

%set fetching variables NI
dblBufferT_NI = 5; %requested buffer size in seconds, TDT: 15
dblReqSampNI = 1000; %requested sampling rate in Hz
intDownsampleNI = round(dblSampRateNI/dblReqSampNI); %downsampling factor
intBufferN_NI = round(dblBufferT_NI*(dblSampRateNI/intDownsampleNI)); %buffer size
dblBufferSampNI = intBufferN_NI/dblBufferT_NI; %resultant buffer sampling rate
vecFetchChansNI = [0 1]; %photodiode (0) and sync pulse (1)
	
%% loop
%pre-allocate IM
intBuffChansIM = numel(vecFetchChansIM);
intBuffPosIM = 0;
matAggDataIM = zeros(intBufferN_IM,intBuffChansIM,'int16');
vecTimeIM = zeros(intBufferN_IM,1,'int16');
%pre-allocate NI
intBuffChansNI = numel(vecFetchChansNI);
intBuffPosNI = 0;
matAggDataNI = zeros(intBufferN_NI,intBuffChansNI,'int16');
vecTimeNI = zeros(intBufferN_NI,1,'int16');
vecTimeTic = zeros(1,100000,'single');
intTicC = 0;
%run
while toc(hTicStart) < 10
	%pause(0.1)
	hTic = tic;
	
	%% get IMEC probe data; single iter takes ~1ms
	% get current scan number for IMEC probe
	intCurCountIM = str2double(DoFastQueryCmd(hSGL, strStreamIM)); %this is faster than "GetScanCount(hSGL, vecStreamIM(1));"
	
	%retrieve Neuropixels data
	intRetrieveSamplesIM = intCurCountIM - intLastFetchIM; %retrieve as many samples as acquired between previous fetch and now
	if intRetrieveSamplesIM > 0
		try
			%fetch "intRetrieveSamplesIM" samples starting at
			%"intFetchStartCountIM"; FastFatch is optimized version
			[matDataIM,intStartCountIM] = FastFetch(hSGL, vecStreamIM(1), intLastFetchIM, intRetrieveSamplesIM, vecFetchChansIM, intDownsampleIM);
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			ME
			matDataIM = [];
		end
		%process data outside try-catch (slightly faster)
		if ~isempty(matDataIM)
			%assign data
			vecUsePosIM = modx((intBuffPosIM+1):(intBuffPosIM+ceil(intRetrieveSamplesIM/intDownsampleIM)),intBufferN_IM);
			intBuffPosIM = vecUsePosIM(end);
			matAggDataIM(vecUsePosIM,:) = matDataIM;
			vecTimeIM(vecUsePosIM) = ((intLastFetchIM+1):intDownsampleIM:intCurCountIM)/dblSampRateIM;
			
			%update last fetch
			intLastFetchIM = intCurCountIM;
			dblCurTimeIM = intCurCountIM/dblSampRateIM;
		end
	end
	
	%% get NI I/O box data, single iter takes ~0.5ms
	%get current scan number for NI streams
	intCurCountNI = str2double(DoFastQueryCmd(hSGL, strStreamNI));%this is faster than "GetScanCount(hSGL, intStreamNI);"
	
	%get NI data
	intRetrieveSamplesNI = intCurCountNI - intLastFetchNI; %retrieve as many samples as acquired between previous fetch and now
	if intRetrieveSamplesNI > 0
		%fetch in try-catch block
		try
			%fetch "intRetrieveSamplesNI" samples starting at "intFetchStartCountNI"
			[matDataNI,intStartCountNI] = FastFetch(hSGL, intStreamNI, intLastFetchNI, intRetrieveSamplesNI, vecFetchChansNI, intDownsampleNI);
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			ME
			matDataNI = [];
		end
		%process data outside try-catch (slightly faster)
		if ~isempty(matDataNI)
			%assign data
			vecUsePosNI = modx((intBuffPosNI+1):(intBuffPosNI+ceil(intRetrieveSamplesNI/intDownsampleNI)),intBufferN_NI);
			intBuffPosNI = vecUsePosNI(end);
			matAggDataNI(vecUsePosNI,:) = matDataNI;
			vecTimeNI(vecUsePosNI) = ((intLastFetchNI+1):intDownsampleNI:intCurCountNI)/dblSampRateNI;
			
			%update last fetch
			intLastFetchNI = intCurCountNI;
			dblCurTimeNI = intCurCountNI/dblSampRateNI;
			
			%extract data
			vecPhotoDiode_mV = matDataNI(:,1);
			vecPulse = matDataNI(:,2);
		end
	end
	
	%save duration
	if toc(hTicStart) > 1
	intTicC = intTicC + 1;
	vecTimeTic(intTicC) = toc(hTic);
	end
end
vecTimeTic = vecTimeTic(vecTimeTic>0);
figure;histx(vecTimeTic);xlim([0 0.01]);mean(vecTimeTic)
sum(vecTimeTic(vecTimeTic>0.003))
%% stop recording
SetRecordingEnable(hSGL, 0);

%% check edge synchronization; note that this is not done online!
%IM
vecPulseIM = zscore(double(matAggDataIM(:,end)));
vecTimeIM = cell2mat(cellTimeIM)/dblSampRateIM;
hold on
plot(vecTimeIM,vecPulseIM);
%NI
vecPulseNI = double(matAggDataNI(:,end));
vecTimeNI = cell2mat(cellTimeNI)/dblSampRateNI;
plot(vecTimeNI,zscore(vecPulseNI));
hold off
