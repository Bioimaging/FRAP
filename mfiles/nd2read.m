function data = nd2read(FilePath,FileName)
%ND2READ Summary of this function goes here
%   Detailed explanation goes here
%
%   Nicolas Liaudet
%   Bioimaging Core Facility - UNIGE
%   https://www.unige.ch/medecine/bioimaging/en/bioimaging-core-facility/
% 
%   v1.0 03-March-2021 NL

reader = bfGetReader();
reader = loci.formats.Memoizer(reader, 0);
reader.setId([FilePath filesep FileName])

idxImage = 1;

omeMeta = reader.getMetadataStore();
NBImage = omeMeta.getImageCount();

% data = struct('Name',cell(NBImage,1),...
%     'DimX',cell(NBImage,1),...
%     'DimY',cell(NBImage,1),...
%     'DimZ',cell(NBImage,1),...
%     'DimC',cell(NBImage,1),...
%     'DimT',cell(NBImage,1),...
%     'ResX',cell(NBImage,1),...
%     'ResY',cell(NBImage,1),...
%     'ResZ',cell(NBImage,1),...
%     'ResT',cell(NBImage,1),...
%     'SpatialUnit',cell(NBImage,1),...
%     'TimeUnit',cell(NBImage,1),...
%     't',cell(NBImage,1),...   
%     'PixelType',cell(NBImage,1),...
%     'ChannelName',cell(NBImage,1),...
%     'OriginalStack',cell(NBImage,1));

data.FilePath = FilePath;
data.FileName = FileName;
data.Name = char(omeMeta.getImageName(idxImage-1));

data.DimX = omeMeta.getPixelsSizeX(idxImage-1).getValue();
data.DimY = omeMeta.getPixelsSizeY(idxImage-1).getValue();
data.DimZ = omeMeta.getPixelsSizeZ(idxImage-1).getValue();
data.DimC = omeMeta.getPixelsSizeC(idxImage-1).getValue();
data.DimT = omeMeta.getPixelsSizeT(idxImage-1).getValue();

data.ResX = double(omeMeta.getPixelsPhysicalSizeX(idxImage-1).value);
data.ResY = double(omeMeta.getPixelsPhysicalSizeY(idxImage-1).value);

if data.DimZ == 1
    data.ResZ = double(omeMeta.getPixelsPhysicalSizeZ(idxImage-1));
else
%     data.ResZ = double(omeMeta.getPixelsPhysicalSizeZ(idxImage-1).value);
    data = [];
    return
    
end

for idxC = 1:data.DimC
    data.ChannelName{idxC} = char(omeMeta.getChannelName(idxImage-1,idxC-1));
end

data.PixelType = char(omeMeta.getPixelsType(idxImage-1));

data.SpatialUnit = char(omeMeta.getPixelsPhysicalSizeX(idxImage-1).unit.getSymbol);
data.TimeUnit    = char(omeMeta.getPlaneDeltaT(idxImage-1,0).unit.getSymbol);
t = zeros(data.DimT,1);
%     z = zeros(data.DimT,1);
for idxT = 1:data.DimC*data.DimZ*data.DimT
    t(idxT) = omeMeta.getPlaneDeltaT(idxImage-1,idxT-1).value;
    %         z(idxT) = omeMeta.getPlanePositionZ(0,idxT-1).value;
end
t = seconds(t);
t = t-t(1);
t = t(1:data.DimC*data.DimZ:end);

t.Format = data.TimeUnit;

data.t = round(t);
data.ResT = round(mean(diff(data.t)));


stack = zeros(data.DimY,...
    data.DimX,...
    data.DimT,...
    data.DimC,...
    data.DimZ,...
    data.PixelType);
reader.setSeries(idxImage-1)
for idxZ=1:data.DimZ
    for idxC=1:data.DimC
        for idxT=1:data.DimT            
            iplane = loci.formats.FormatTools.getIndex(reader,...
                idxZ-1,idxC-1,idxT-1)+1;
            stack(:,:,idxT,idxC,idxZ) = bfGetPlane(reader, iplane);
        end
    end
end

stack = squeeze(stack);
data.OriginalStack = stack;




end

