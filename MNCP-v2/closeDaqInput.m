function closeDaqInput(objDAQ)
	%% get handle
	global ptrPhotoDiodeFile;
	
	%% close file
	try,fclose(ptrPhotoDiodeFile);catch,end
	
	%% close connection
	try,stop(objDAQ);catch,end
	daqreset;
end