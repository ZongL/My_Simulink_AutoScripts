% Load the Simulink model
modelName = 'BCM_Tx'; % Replace with your model name
subsystemPath = 'BCM_Tx/Runnable_BCM_Tx_sys';
load_system(modelName);

% Find all Outport blocks at the top level of the model
outportBlocks = find_system(modelName, 'SearchDepth', 1, 'FindAll', 'On', 'type', 'block', 'BlockType', 'Outport');

% Initialize an empty cell array to store the filtered port names
portname_filter = {};

% Extract the second-to-last element from the port name and store it in the array
disp('Filtered Port Names:');
for i = 1:length(outportBlocks)
    portName = get_param(outportBlocks(i), 'PortName'); % Get the full port name
    
    % Split the port name by underscores
    parts = strsplit(portName, '_');
    
    % Check if there are at least two parts
    if length(parts) >= 2
        % Extract the second-to-last element
        filteredName = parts{end-1};
        portname_filter{end+1} = filteredName; % Store the filtered name
        disp(filteredName); % Display the filtered name
    else
        % If there is only one part, store the original name
        portname_filter{end+1} = portName;
        disp(portName);
    end
end
portname_filter = unique(portname_filter);
% Display the final array of filtered port names
disp('Creating Simulink.Signal objects in the workspace:');
for i = 1:length(portname_filter)
    signalName = portname_filter{i}; % Get the name from the array
    signalName = ['BCM_Tx_',signalName];
    % Create a Simulink.Signal object with the given name
    assignin('base', signalName, Simulink.Signal);
    disp(['Created Simulink.Signal object: ', signalName]);
end






% 获取子系统的句柄
subsystemHandle = get_param(subsystemPath, 'Handle');
initialX = 100;  % 子系统左边界
initialY = 100;  % 子系统上边界
offsetY = 80;  % 每个模块之间的垂直间距
% 假设portname_filter已经定义并去重
portname_filter = unique(portname_filter);  % 确保portname_filter中没有重复元素

% 遍历portname_filter，为每个名称添加Data Store Write模块
for i = 1:length(portname_filter)
    signalName = portname_filter{i};
    signalName = ['BCM_Tx_',signalName];
    % 添加Data Store Write模块
    %newBlockPath = [subsystemPath, '/DataStoreWrite_', signalName];
    %add_block('simulink/Signal Routing/Data Store Write', newBlockPath);
    
% 计算模块的纵坐标
    blockY = initialY - (i - 1) * offsetY;
    
    % 添加Data Store Write模块
    newBlockPath = [subsystemPath, '/DataStoreWrite_', signalName];
    add_block('simulink/Signal Routing/Data Store Write', newBlockPath, ...
              'Position', [initialX - 30, blockY - 20, initialX + 100, blockY + 20]);

    % 设置Data Store Write模块的参数（例如，数据存储名称）
    set_param(newBlockPath, 'DataStoreName', signalName);

    %----------------data store read---------
    newBlockPath_read = [subsystemPath, '/DataStoreRead_', signalName];
    add_block('simulink/Signal Routing/Data Store Read', newBlockPath_read, ...
              'Position', [initialX + 30, blockY - 20, initialX + 100, blockY + 20]);
    set_param(newBlockPath_read, 'DataStoreName', signalName);

end
