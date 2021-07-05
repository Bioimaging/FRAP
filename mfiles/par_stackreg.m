function data = par_stackreg(data,reg_para,hwb)
%STACKREG Summary of this function goes here
%   Detailed explanation goes here
%
%   Nicolas Liaudet
%   Bioimaging Core Facility - UNIGE
%   https://www.unige.ch/medecine/bioimaging/en/bioimaging-core-facility/
% 
%   v1.0 04-Mar-2020 NL


transformType = reg_para.transformType;
optimizer     = reg_para.optimizer;
metric        = reg_para.metric;
sigmablur     = reg_para.sigmablur;
% idxTREF       = reg_para.idxTREF;
idxCREF       = reg_para.idxCREF;

% Default spatial referencing objects
fixedRefObj  = imref2d([data.DimY data.DimX]);
movingRefObj = imref2d([data.DimY data.DimX]);

stack_reg = data.OriginalStack;
for idxT = 2:data.DimT

    hwb.Value = idxT/data.DimT; 
    hwb.Message = ['Frame ' num2str(idxT) '/' num2str(data.DimT)];
    
    FIXED = stack_reg(:,:,idxT-1,idxCREF);
    FIXED = imgaussfilt(FIXED,sigmablur);
    FIXED = mat2gray(FIXED);
    
    MOVING = stack_reg(:,:,idxT,idxCREF);   
    MOVING = imgaussfilt(MOVING,sigmablur);
    MOVING = mat2gray(MOVING);        
    
    tform = imregtform(MOVING,movingRefObj,...
        FIXED,fixedRefObj,....
        transformType,...
        optimizer,metric,...
        'PyramidLevels',3 );

    for idxC = 1:data.DimC        
        MOVING = data.OriginalStack(:,:,idxT,idxC);
        RegisteredImage = imwarp(MOVING, movingRefObj,...
            tform,...
            'cubic',...
            'OutputView', fixedRefObj,...
            'SmoothEdges', true);
        stack_reg(:,:,idxT,idxC) = RegisteredImage;
    end   

end
data.Stack = stack_reg;
end

