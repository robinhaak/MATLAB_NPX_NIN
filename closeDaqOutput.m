function closeDaqOutput(objDAQ)
	%% set LEDs off
	%set variables
	try
	%queueOutputData(objDAQ,[0 0]);
	%startBackground(objDAQ);
	pause(0.1);
	catch
	end
	
	%% close connection
	try,stop(objDAQ);catch,end
	daqreset;
end