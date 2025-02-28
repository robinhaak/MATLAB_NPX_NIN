function fPhotoDiodeCallback(objDAQ,objData)
	%fPhotoDiodeCallback Logs PhotoDiode data
	%   Detailed explanation goes here
	
	%get handle
	global ptrPhotoDiodeFile;

	%get data
	strTriggerTime = sprintf('%.3f',objData.TriggerTime);
	vecTimeStamps = objData.TimeStamps;
	%prep data
	vecData = round(objData.Data,3,'significant');
	dblMultFactor = (10.^(-floor(log10(mean(vecData)))));
	vecSelectData = dblMultFactor.*vecData;
	%strFields='"TriggerTime";"TimeStamp";"Data"';
	
	%write output
	strSaveRes = ['%.' num2str(ceil(log10(objDAQ.Rate))) 'f'];
	if ~isempty(vecData)
		vecWriteLines = [1 find(abs(diff(vecSelectData(:)))'>0.1)+1] ;
		for intLine=vecWriteLines
			strWrite = strcat(strTriggerTime,';',sprintf(strSaveRes,vecTimeStamps(intLine)),';',sprintf('%.3e',vecData(intLine)),'\n');
			fprintf(ptrPhotoDiodeFile,strWrite);
		end
	end
end

