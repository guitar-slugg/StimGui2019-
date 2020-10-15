% Visualizes Calibration Results
%       dB / V data for ER-2 speaker calibration files

% Plots maximum dB from V taking into account dB reliability just under 2V
% limit
%   old version is 'Vmax.m'
%
%   DBrown 2018-11-16


%% ADJUST INPUTS HERE


%load cal file and get "Levels" variable
%calfile = 'cal_4_7_18_in_ear_red_500Hzto20KHz_10to90dB_600Hzfilter_oldmic.mat';
%calfile = 'cal_11_13_18_in_ear_red_200Hzto20KHz_20to90dB_150Hzfilter_newMic.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\200-1000Hz delta200Hz 10-90dB delta5dB hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB 01.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\200-1000Hz delta200Hz 10-90dB delta5dB hipass150Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB 03.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\200-20000Hz delta200Hz 20-90dB delta5dB hipass150Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\day 2 - 200-1000Hz delta200Hz 10-90dB delta5dB hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB 01 lower ambient noise floor 04.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\2.3V test.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\500-2000Hz delta200Hz 10-90dB delta5dB hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB 01.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\500-2000Hz delta200Hz 10-90dB delta5dB  2.6Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB 01.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\200-1000Hz delta200 10-90dB delta5dB 2Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB Vtest 01.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\200-1000Hz delta200 10-90dB delta5dB 3Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB Vtest 02.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\low test 2V 200-5000Hz delta200 10-90dB delta5dB 2Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\low test 3V 200-5000Hz delta200 10-90dB delta5dB 3Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\low test 3.2V 200-5000Hz delta200 10-90dB delta5dB 3.2Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\low test 3.2V BLUE speaker Out_A BNC 200-5000Hz delta200 10-90dB delta5dB 3.2Vmax hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\3mm spacer 40dB gain +bypass -- 200-5000Hz delta200Hz 10-90dB delta5dB hipass50Hz 4mVPa quarterinchMic 40dB gain bypass atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\40dB +bypass 1mm inside spacer 3.2V 200-1000 delta200Hz 10-90dB delta5dB hpf50Hz 4mVPa atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\0dB +bypass 1mm inside spacer 3.2V 200-1000 delta200Hz 10-90dB delta5dB hpf50Hz 4mVPa atten0dB.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\DB cal tests\input filters 10hpf 10000lpf 200-1000Hz delta200Hz 10-90dB delta5dB 3.2V hpf50Hz 40dB gain.mat';

%calfile = 'C:\Users\GoldingLab\Desktop\cal_9_24_2020_500to10000_d100_10-90dB_d5_HPF600.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\cal_9_24_2020_500to10000_d100_10-90dB_d5_HPF100.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\half-inch mic 3.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\4.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\5.mat';     % NEW STIMGUI STOPS AT
%1000hZ (OR THE FREQ IN THE SETTINGS ISN'T OVERWRITTEN BY THE CAL
%PROCEDURE. FALSE RESULTS
%calfile = 'C:\Users\GoldingLab\Desktop\6.mat';
%calfile = 'C:\Users\GoldingLab\Documents\MATLAB\StimGui2019\Calibrations\roughCalibration.mat';

%calfile = 'C:\Users\GoldingLab\Documents\MATLAB\Stim_GUI\cal_4_7_18_in_ear_red_500Hzto20KHz_10to90dB_600Hzfilter_oldmic.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\01 250-1000Hz delta 250 5-80dB delta 5dB max V HPF 200.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\02 cal 500-2000Hz d250 10-90dB d5 max2 hpf600.mat';
%calfile = 'C:\Users\GoldingLab\Desktop\03 cal 500-2000Hz d250 10-90dB d5 max2 hpf600 OLD MIC.mat';
calfile = 'C:\Users\GoldingLab\Desktop\04 cal 500-2000Hz d250 10-90dB d5 max2 hpf600 OLD MIC GAIN=0.mat';

% Input freq range & steps
%freqs = [500:1:20000]'; % cal file 4_7_18
%freqs = [200:1:20000]';  % cal file 11_13_18
%freqs = [200:200:1000]'; % DB test cals
%freqs = [500:1:10000]';

%freqs = [500:1:20000]';
%freqs = [250:1:1000]';
freqs = [500:1:2000]';

hardmax = 2; %3.2;  %volts



load(calfile);

%% Find min & max for each freq based on calibration file

% 2V max
max_dB = [];
for i = 1:length(freqs);
    temp = find(Levels(:,freqs(i)) == hardmax);
        if isempty(temp)
            max_dB = [max_dB; nan];
        else
            max_dB = [max_dB; temp(1)];
        end
    
end

% "Max reliable dB" is i-1
max_reliable_dB = [];
for i = 1:length(freqs);
    temp = find(Levels(:,freqs(i)) == hardmax) -1;
        if isempty(temp)
            value = find(Levels(:,freqs(i)));
            max_reliable_dB = [max_reliable_dB; value(end)];
        else
            max_reliable_dB = [max_reliable_dB; temp(1)];
        end
    
end

% NOISE FLOOR: Find dB (row index) where value <.001 for now
noise_floor = [];
for i = 1:length(freqs);
    %temp = find(Levels(:,freqs(i)) < .001);
    temp = find(Levels(:,freqs(i)) < .001 & Levels(:,freqs(i)) > 0,1);
        %temp = temp(temp<90);
        noise_floor = [noise_floor; temp(end)];
end



%% Plot    
    
h6 = figure(6); hold on
    h6.Color = [1 1 1];
    
plot(freqs/1000,max_dB,'k.-');
plot(freqs/1000,max_reliable_dB,'r.-');
plot(freqs/1000,noise_floor,'b.-')
    set(gca,'ylim',[0 100])
    xlabel('kHz')
    ylabel('dB SPL')
    title(calfile,'Interpreter','none')
    set(gca,'tickdir','out')
    box off
    
    L1 = legend(['max dB at ',num2str(hardmax),'V'],'max reliable dB','noise floor')
        L1.Location = 'southeast';
        legend boxoff
        
    
    


%% Return values & save
%{

C.freqs             = freqs;
C.max_dB            = max_dB;
C.max_reliable_dB   = max_reliable_dB;
C.info              = calfile;
C


s = input('Save data?\n');
if s == 1;
    filename = input('File name?\n');
    savepath = ['C:\Users\GoldingLab\Desktop\DavidB\tests\ER-2 cal\'];
    save([savepath,filename],'C')
end
%}


