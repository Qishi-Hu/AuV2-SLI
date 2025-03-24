% Generate the LUT values
lut = 0.5 + 0.5 * cos(2*pi*(0:719)/720);
lutV = 0.5 + 0.5 * cos(2*pi*(0:1279)/1280);
% Scale the values to integers between 0 and 255
lut_scaled = uint8(255 * lut);
lut_scaled_V = uint8(255 * lutV);

% create coe file for LUT

fileID = fopen('LUT.coe', 'w');
fprintf(fileID, 'memory_initialization_radix=2;\n');
fprintf(fileID, 'memory_initialization_vector=\n');

% Write each element in binary format, ensuring 10 bits
for idx = 1:720
    binaryValue = dec2bin(lut_scaled(idx), 8);
    fprintf(fileID, '%s', binaryValue); 
    if idx < 720
        fprintf(fileID, ',\n');
    else
        fprintf(fileID, ';\n');
    end
end
fclose(fileID);

% create coe file for LUT_V

fileID_V = fopen('LUT_V.coe', 'w');
fprintf(fileID_V, 'memory_initialization_radix=2;\n');
fprintf(fileID_V, 'memory_initialization_vector=\n');

% Write each element in binary format, ensuring 10 bits
for idx = 1:1280
    binaryValue = dec2bin(lut_scaled_V(idx), 8);
    fprintf(fileID_V, '%s', binaryValue); 
    if idx < 1280
        fprintf(fileID_V, ',\n');
    else
        fprintf(fileID_V, ';\n');
    end
end
fclose(fileID_V);


fprintf('COE file successfully created \n');
clear;