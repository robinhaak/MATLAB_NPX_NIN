function [hSGL,strRunName,sParamsSGL] = InitSGL(strRecording,strHostAddress,boolStart)
	%InitSGL Initializes SGL
	%   [hSGL,strRunName,sParamsSGL] = InitSGL(strRecording,strHostAddress,boolStart)


    %28 Feb 2025 - edited by Robin 
	
	%check input
	if nargin < 2 || isempty(strHostAddress)
		strHostAddress = '127.0.0.1';%'192.87.10.238'
	end
	if nargin < 3 || isempty(boolStart)
		boolStart = true;
	end
	
	% Create connection (edit the IP address)
	hSGL = SpikeGL(strHostAddress);
	
	%retrieve channels to save
	warning('off','CalinsNetMex:connectionClosed');
% 		vecSaveChans = GetSaveChans(hSGL, 0); %commented out, unused
	warning('on','CalinsNetMex:connectionClosed');
	
	if ~IsSaving(hSGL)
		%set run name
		intBlock = 0;
		boolAccepted = false;
		while ~boolAccepted
			intBlock = intBlock + 1;
			strRunName = strcat('Rec',strRecording,'_',getDate,sprintf('R%02d',intBlock));
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
	else
		strRunName = GetRunName(hSGL);
	end
	
	%set meta data, can be anything, as long as it's a numeric scalar or string
	sMeta = struct();
	strTime = strrep(getTime,':','_');
	strMetaField = sprintf('recording_%s',strTime);
	sMeta.(strMetaField) = strRecording;
	SetMetaData(hSGL, sMeta);
	
	%get parameters for this run
	sParamsSGL = GetParams(hSGL);
	
	%set stream IDs
% 	vecStreamIM = [0];
% 	intStreamNI = -1;
	
	%get probe ID
	% 	[cellSN,vecType] = GetImProbeSN(hSGL, vecStreamIM(1));
	[cellSN,vecType] = GetStreamSN(hSGL, 2, strHostAddress);
	
	sParamsSGL.cellSN = cellSN;
	
	%start recording if requested & not already recording
	if boolStart
		if ~IsSaving(hSGL)
			SetRecordingEnable(hSGL, 1);
		end
		hTicStart = tic;
		
		%check if output is being saved
		while ~IsSaving(hSGL) && toc(hTicStart) < 1
			pause(0.01);
		end
		if ~IsSaving(hSGL)
			error([mfilename ':NotSaving'],'Data is not being saved!')
		end
	end
end
