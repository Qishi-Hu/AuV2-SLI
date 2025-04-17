%convert customized LUTs in .txt into one raw File
% Step 1: Read decimal values from the text file
LUT = readmatrix('LUT.txt');  
LUT_V = readmatrix('LUT_V.txt');  
% Step 2: Ensure data is uint8 (0–255)
LUT = uint8(LUT);
LUT_V = uint8(LUT_V);

% Step 3: Write to a .raw file, 1 byte per element
fid = fopen('LUT.raw', 'w');
fwrite(fid, LUT, 'uint8');
fwrite(fid, LUT_V, 'uint8');
fclose(fid);
clear;