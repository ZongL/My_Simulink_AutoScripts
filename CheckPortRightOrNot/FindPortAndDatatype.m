function FindPortAndDatatype(model_name)


HHH=load_system(model_name);

blks = find_system(HHH,'SearchDepth',1);
inport_num = 0;
outport_num = 0;

for i = 1:1:length(blks)
    try
        blocktype_handle = get_param(blks{i},'BlockType');
        if strcmp(blocktype_handle,'Inport')
            inport_num = inport_num+1;
        elseif strcmp(blocktype_handle,'Outport')
            outport_num = outport_num+1;
        end
    catch
    end
end

sheet_inport = cell(inport_num+1,3);
sheet_outport = cell(outport_num+1,3);

local_inport_num = 1;
local_outport_num = 1;
sheet_inport{1,1} = 'Index';
sheet_inport{1,2} = 'Name';
sheet_inport{1,3} = 'DataType';
sheet_outport{1,1} = 'Index';
sheet_outport{1,2} = 'Name';
sheet_outport{1,3} = 'DataType';

for i = 1:1:length(blks)
    try
        blocktype_handle = get_param(blks(i),'BlockType');
        if strcmp(blocktype_handle,'Inport')
            local_inport_num = local_inport_num+1;
            sheet_inport{local_inport_num,1} = num2str(local_inport_num-1);
            sheet_inport{local_inport_num,2} = get_param(blks(i),'Name');
            Inport_name=get_param(blks(i),'Name');
            result=findstr(Inport_name,' ');
            if isempty(result)~=1
                fprintf([' \n******',model_name,' model input signal  ',Inport_name,'  contains space******']);
            end
            
            result2=findstr(Inport_name,char(10));
            if isempty(result2)~=1
                fprintf([' \n******',model_name,' model input signal  ',Inport_name,'  contains newline******']);
            end
            
            sheet_inport{local_inport_num,3} = get_param(blks(i),'OutDataTypeStr');
            OutDataType=sheet_inport{local_inport_num,3};
            result=findstr(OutDataType,'auto');
            if ~isempty(result)
                fprintf(['\nInput signal ',Inport_name,' data type is ',OutDataType]);
            end
        elseif strcmp(blocktype_handle,'Outport')
            local_outport_num = local_outport_num+1;
            sheet_outport{local_outport_num,1} = num2str(local_outport_num-1);
            sheet_outport{local_outport_num,2} = get_param(blks(i),'Name');
            Outport_name=get_param(blks(i),'Name');
            result=findstr(Outport_name,' ');
            if isempty(result)~=1
                fprintf([' \n******',model_name,' model output signal  ',Outport_name,'  contains space******']);
            end
            
            result1=findstr(Outport_name,char(10));
            if isempty(result1)~=1
                fprintf([' \n******',model_name,' model output signal  ',Outport_name,'  contains newline******']);
            end
            
            sheet_outport{local_outport_num,3} = get_param(blks(i),'OutDataTypeStr');
            OutDataType=sheet_outport{local_outport_num,3};
            result=findstr(OutDataType,'auto');
            if ~isempty(result)
                fprintf(['\nOutput signal ',Outport_name,' data type is ',OutDataType]);
            end
        end
    catch
    end
end

clear sheet_para result
end
