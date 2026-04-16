% ----------------------------------------------------------------------- %

%1. Extract Inports from the model, then check if they exist and if data types are consistent by searching in the data below:
% Columns X & Y of the table (CAN messages)
% All internal Outports of the model
%2. Extract Outports from the model, then check if they exist and if data types are consistent by searching in the data below:
% Column U of the table (CAN messages)
% All internal Inports of the model

% Read replace info from excel file
clear;
clc;
warning off
% Load interface library from Excel
[~, ~, raw] = xlsread('Interface.xlsx', 'P1');

% Display the size of the raw data for debugging
fprintf('Excel file contains %d rows and %d columns.\n\n', size(raw, 1), size(raw, 2));

% Verify the structure of the Excel file
if size(raw, 2) < 25
    error('The Excel file does not have enough columns. Please check the file structure.');
end

inputLibrary = raw(2:end, 24:25); % Columns X and Y for input ports
outputLibrary = raw(2:end, 21);   % Column U for output ports
dataTypeLibrary = raw(2:end, 18); % Column R for data types

selpath = uigetdir('*.slx','Select path contains slx format simulink model');
addpath(genpath(selpath))
slxList = dir([selpath,'\**\*.slx']);
slxNum = length(slxList);

% First pass: collect all outports and inports from all models
allOutports = containers.Map(); % Key: portName, Value: dataType
allInports = containers.Map(); % Key: portName, Value: dataType
for slx = 1:slxNum
    slxMdl = [slxList(slx).folder,'\',slxList(slx).name];
    slxHandle = load_system(slxMdl);
    slxName = get_param(slxHandle,'Name');
    mdlName = [slxName,'.slx'];
    
    inports = find_system(slxHandle, 'SearchDepth', 1, 'BlockType', 'Inport');
    outports = find_system(slxHandle, 'SearchDepth', 1, 'BlockType', 'Outport');
    
    for i = 1:length(inports)
        portName = get_param(inports(i), 'Name');
        dataType = get_param(inports(i), 'OutDataTypeStr');
        if ~isKey(allInports, portName)
            allInports(portName) = dataType;
        elseif ~strcmp(allInports(portName), dataType)
            fprintf('Warning: Inport "%s" has conflicting data types across models.\n', portName);
        end
    end
    
    for i = 1:length(outports)
        portName = get_param(outports(i), 'Name');
        dataType = get_param(outports(i), 'OutDataTypeStr');
        if ~isKey(allOutports, portName)
            allOutports(portName) = dataType;
        elseif ~strcmp(allOutports(portName), dataType)
            fprintf('Warning: Outport "%s" has conflicting data types across models.\n', portName);
        end
    end
    
    close_system(slxMdl);
end

% Second pass: check each model
for slx = 1:slxNum
    slxMdl = [slxList(slx).folder,'\',slxList(slx).name];
    slxHandle = load_system(slxMdl);
    slxName = get_param(slxHandle,'Name');
    mdlName = [slxName,'.slx'];
    FindSpaceAndNoDatatype(mdlName);
    
    
    % Check top-level ports only
    inports = find_system(slxHandle, 'SearchDepth', 1, 'BlockType', 'Inport');
    outports = find_system(slxHandle, 'SearchDepth', 1, 'BlockType', 'Outport');

    % Initialize result storage
    missingPorts = {};
    mismatchedPorts = {};

    % Validate inports
    if isempty(inports)
        fprintf('No inports found in the top-level model.\n');
    else
        for i = 1:length(inports)
            portName = get_param(inports(i), 'Name'); % Use parentheses for string array indexing
            dataType = get_param(inports(i), 'OutDataTypeStr');
            % Check if port exists in input library (columns X and Y)
            portExistsInLibrary = any(cellfun(@(x) strcmp(portName, x), inputLibrary(:)));
            if portExistsInLibrary
                % Find the row for the port
                [row, ~] = find(cellfun(@(x) strcmp(portName, x), inputLibrary));
                if ~isempty(row)
                    expectedDataType = dataTypeLibrary{row(1)};
                    if ~strcmp(dataType, expectedDataType)
                        fprintf('Error: Data type mismatch for Inport "%s". Expected: %s, Found: %s\n', portName, expectedDataType, dataType);
                        mismatchedPorts{end+1} = portName;
                    end
                end
            elseif ~isKey(allOutports, portName)
                fprintf('Error: Inport "%s" not found in library or internal outports.\n', portName);
                missingPorts{end+1} = portName;
            end
        end
    end

    % Validate outports
    if isempty(outports)
        fprintf('No outports found in the top-level model.\n');
    else
        for i = 1:length(outports)
            portName = get_param(outports(i), 'Name'); % Use parentheses for string array indexing
            dataType = get_param(outports(i), 'OutDataTypeStr');
            % Check if port exists in output library (column U)
            portExistsInLibrary = any(cellfun(@(x) strcmp(portName, x), outputLibrary));
            if portExistsInLibrary
                % Find the row for the port
                row = find(cellfun(@(x) strcmp(portName, x), outputLibrary), 1);
                if ~isempty(row)
                    expectedDataType = dataTypeLibrary{row};
                    if ~strcmp(dataType, expectedDataType)
                        fprintf('Error: Data type mismatch for Outport "%s". Expected: %s, Found: %s\n', portName, expectedDataType, dataType);
                        mismatchedPorts{end+1} = portName;
                    end
                end
            elseif ~isKey(allInports, portName)
                fprintf('Error: Outport "%s" not found in library or internal inports.\n', portName);
                missingPorts{end+1} = portName;
            end
        end
    end

    % Print summary of results
    fprintf('\nSummary of Check for %s:\n', mdlName);
    fprintf('Missing Ports:\n');
    for i = 1:length(missingPorts)
        fprintf('- %s\n', missingPorts{i});
    end
    fprintf('Mismatched Ports:\n');
    for i = 1:length(mismatchedPorts)
        fprintf('- %s\n', mismatchedPorts{i});
    end

    close_system(slxMdl);
    fprintf(['\n*************',mdlName,'检查完毕*************\n']);
end

rmpath(genpath(selpath));


function FindSpaceAndNoDatatype(model_name)


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
sheet_inport{1,1} = '序号';
sheet_inport{1,2} = 'Name';
sheet_inport{1,3} = 'DataType';
sheet_outport{1,1} = '序号';
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
                fprintf([' \n******',model_name,'模型的输入信号  ',Inport_name,'  中有空格******']);
            end
            
            result2=findstr(Inport_name,char(10));
            if isempty(result2)~=1
                fprintf([' \n******',model_name,'模型的输入信号  ',Inport_name,'  中有换行******']);
            end
            
            sheet_inport{local_inport_num,3} = get_param(blks(i),'OutDataTypeStr');
            OutDataType=sheet_inport{local_inport_num,3};
            result=findstr(OutDataType,'auto');
            if ~isempty(result)
                fprintf(['\n输入信号',Inport_name,'的数据类型是',OutDataType]);
            end
        elseif strcmp(blocktype_handle,'Outport')
            local_outport_num = local_outport_num+1;
            sheet_outport{local_outport_num,1} = num2str(local_outport_num-1);
            sheet_outport{local_outport_num,2} = get_param(blks(i),'Name');
            Outport_name=get_param(blks(i),'Name');
            result=findstr(Outport_name,' ');
            if isempty(result)~=1
                fprintf([' \n******',model_name,'模型的输出信号  ',Outport_name,'  中有空格******']);
            end
            
            result1=findstr(Outport_name,char(10));
            if isempty(result1)~=1
                fprintf([' \n******',model_name,'模型的输出信号  ',Outport_name,'  中有换行******']);
            end
            
            sheet_outport{local_outport_num,3} = get_param(blks(i),'OutDataTypeStr');
            OutDataType=sheet_outport{local_outport_num,3};
            result=findstr(OutDataType,'auto');
            if ~isempty(result)
                fprintf(['\n输出信号',Outport_name,'的数据类型是',OutDataType]);
            end
        end
    catch
    end
end

clear sheet_para result
end

