function CloseSGL(hSGL,boolForceQuit)
	%CloseSGL Closes SGL
	%   CloseSGL(hSGL,boolForceQuit)
	
	%% get params
	if ~exist('boolForceQuit','var')
		boolForceQuit = false;
	end
	
	%% stop recording
	try
		if boolForceQuit
			warning('off','CalinsNetMex:connectionClosed');
			SetRecordingEnable(hSGL, 0);
			warning('on','CalinsNetMex:connectionClosed');
		else
			warning([mfilename ':NoForce'],'Force quit switch not enabled; will continue recording');
		end
	catch ME
		warning([mfilename ':CloseFailed'],'Failed to end recording, please disable recording manually!');
		ME
	end
end
