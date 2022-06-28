% Author : Jayanth.S, Hussain Peera, Karthik.S, and Koduru Nani
% Date : 28/05/2022
% Title : Real Time Motion Detion Using Matlab

MotionDetection()


%% Initialization
function Ini = Initializ()
    Ini.NumOfFramesObjDet = 0;
    Ini.NumOfFramesObjNotDet = 0;
    Ini.MotionState = 0; %0 means motion not taking place, 1 means motion taking place
    Ini.motionDet = false; %false means motion has stoped, thus stop writing video 
                   %True means motion is taking place, thus keep writing video
    Ini.StopWriting = false; %false stop writing video %True keep writing video
end
%% Functions
function Obj = SetUpObjects()
    % Setup of cam
    Obj.mycam = webcam;
    Obj.mycam.Brightness = -40;
    % creating foreground anlaysis object through which foreground analysis will be done
    Obj.detector = vision.ForegroundDetector("NumTrainingFrames", 10,...
                             "InitialVariance", 60*60,...
                             "MinimumBackgroundRatio", 0.7,...
                             "NumGaussians", 3);
    %creating Blob analysis object to do blob analysis through this object
    Obj.blobAnalyser = vision.BlobAnalysis('MinimumBlobArea', 500);
    %creating an object to terminat the infinite loop
    Obj.stop=figure('position',[0 0 eps eps],'menubar','none');
    % video writing
    Obj.mywriter = VideoWriter("mymovie.avi");
    open(Obj.mywriter);
    % Set up video player
    Obj.player = vision.VideoPlayer("Position", [180, 100, 700, 400]);
    Obj.player2 = vision.VideoPlayer("Position", [300, 200, 700, 400]);
end

%% Creating Foreground mask
function mask = foregroundMask(img,Obj)
        mask.maskImg = Obj.detector.step(img);
        mask.maskImg = imopen(mask.maskImg, strel("rectangle", [3,3]));
        mask.maskImg = imclose(mask.maskImg, strel("rectangle", [15, 15]));
        mask.maskImg = imfill(mask.maskImg, "holes");
end

%% video player
function PlayVideo(img,mask,Obj)
        Obj.player.step(img);
        Obj.player2.step(mask);
end

%% Starting the Motion Detion in the frame
function StartMotionDetection(Obj,Ini)
    % Creating Infinite Loop to analysis   
    while 1 
        
        % Termination of Infinite Loop
        if strcmp(get(Obj.stop,'currentcharacter'),'q')
          close(Obj.stop)
          break
        end
        % force the event queue to flush
        figure(Obj.stop)
        drawnow
        
        img = snapshot(Obj.mycam); % Extraction Images from cam in frames
        mask = foregroundMask(img,Obj); % Foreground
        [~,~,bbox] = Obj.blobAnalyser.step(mask.maskImg); % Find bounding box
        ObjDet = size(bbox,1); % To indicate if object is detected or not
        
        %checking if there is any motion
        if(ObjDet>1)
            Ini.NumOfFramesObjDet = Ini.NumOfFramesObjDet+1; %used to count the no of frames the motion is detected to consider it as moving object
            if(Ini.NumOfFramesObjDet >= 5) %True of object is detected in more than 5 frames
                if((ObjDet>1)&&(Ini.MotionState==0))
                    fprintf("Motion Detected\n");
                    Ini.StopWriting = false;
                    Ini.motionDet = true; %used to write video when it is true
                    Ini.NumOfFramesObjDet = 0; %setting no of frames object detected to 0
                    Ini.MotionState=1; %to indicate that motion has begin (if 0 motion was not there till then/ if 1 motion was there till then)
                end
            end
        end
        %checking if there is no motion
        if(ObjDet==0 && ~Ini.StopWriting)
            %used to count the no of frames the motion is not detected to consider that there is no motion
            Ini.NumOfFramesObjNotDet = Ini.NumOfFramesObjNotDet+1; 
            if(Ini.NumOfFramesObjNotDet >= 15)
                if((ObjDet == 0)&&(Ini.MotionState==1))
                    fprintf("Motion Stopped\n");
                    %Ini.StopWriting = false;
                    Ini.motionDet = false; %reads the ending time of motion
                    Ini.NumOfFramesObjNotDet = 0;
                    Ini.MotionState=0; %to indicate that motion has begin (if 0 motion was not there till then/ if 1 motion was there till then)
                 end
            end
        end
        ObjFrame = insertShape(img,"rectangle",bbox,"color","r");
        PlayVideo(ObjFrame,mask.maskImg,Obj); % Play Video
        WriteVideo(Obj,Ini,img,bbox);
    end
end

%% Writing Video
function WriteVideo(Obj,Ini,img,bbox)
    %writing the video where the motion is detected
    if(Ini.motionDet)
        %insert bounding box in frame
        ObjFrame = insertShape(img,"rectangle",bbox,"color","r");
        %writing video
        writeVideo(Obj.mywriter,im2double(ObjFrame));
    end 
    %inserting empty frames to indecate the ending of the video
    if(~Ini.motionDet && Ini.StopWriting)
        for i=1:50
             writeVideo(Obj.mywriter, zeros(480,640));
             Ini.StopWriting = true;
        end
    end
end

%% Clean up
function CloseAll(Obj)
    delete(Obj.stop);
    delete(Obj.mycam);
    close(Obj.mywriter);
    release(Obj.detector);
    release(Obj.blobAnalyser);
    release(Obj.player);
    release(Obj.player2)
end

%% Real Time Motion Detion Using Matlab
function MotionDetection()
    Obj = SetUpObjects();
    Ini = Initializ();
    StartMotionDetection(Obj,Ini);
    CloseAll(Obj);
end