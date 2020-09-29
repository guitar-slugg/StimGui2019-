% Designed to be used for auditory experiments using matlab, windows, and
% a TDT rz6 box.
% Requires Matlab >= 2015a 
 %Ken Ledford  1LedfordK@gmail.com
 
classdef StimGui < handle
    
    properties
        circuitpath
        fig
        axes1
        axes2
        controls
        TDT
        calibration
        userSettings
        infoBox
        tempData
        tempStimulus
    end
    
    
    methods
        
        %setup
        function obj = StimGui(filepath)
            
            if nargin <1
                filepath = []; 
            end     
            
            if isempty(filepath)
                %obj.circuitpath = 'C:\Users\GoldingLab\Documents\MATLAB\StimGui2019\rcxCircuit.rcx';
                obj.circuitpath = 'C:\Users\GoldingLab\Documents\MATLAB\StimGui2019\rcxCircuit_TDT.rcx';
            else
                obj.circuitpath=filepath; 
            end     

            %set up circuit
            obj.TDT = TDTDrivers(obj.circuitpath);
            
            %set up figure
            obj.buildGui();
            
            %defualt settings
            obj.userSettings = StimGuiUserSettings;
            
            %load calibration
            obj.loadCalibrationFiles;
            
            %use hardware acceleratesd opengl graphics 
            opengl hardware
            
            global RUNNING 
            RUNNING=0; 


        end
        
        
        function buildGui(obj)
            
            %clear any existing figures
            figTest= findobj('tag','STIM_GUI');
            if ~isempty(figTest)
                delete(figTest);
            end
            
            %create new figure
            obj.fig = figure('position',[50 75 1300 850],...
                'name','Stim GUI','tag','STIM_GUI','color',[0.3 0.5 0.5]);
            
            %function to close tdt on figure close
            obj.fig.DeleteFcn=@(h,e)eval('obj.TDT.halt');
            
            %set up axes
            obj.axes1=axes('Parent',obj.fig,'Position',[0.03, 0.45, 0.77, 0.52]);
            xVec = 0:0.01:2*pi;
            hold on
             for ii=1:10
                plot(obj.axes1,xVec,sin(xVec+10*ii/2*3.14),'linewidth',1,'color',[0.1 0.1 0.5]);
            end
            for ii=1:10
                plot(obj.axes1,xVec,cos(xVec+10*ii/2*3.14),'linewidth',1,'color',[0.1 0.1 0.5]);
            end
            xlim([0 2*pi])
            hold off
            
            
            obj.axes2=axes('Parent',obj.fig,'Position',[0.03, 0.2, 0.77, 0.20]);
            plot(obj.axes2,xVec,xVec*0,'linewidth',1);
            xlim([0 2*pi])
            title(obj.axes1,'Acquired Signals')
            title(obj.axes2,'Stimulus')
            obj.axes1.Color = [0.3 0.5 0.5];
            obj.axes2.Color = [0.3 0.5 0.5];
            
            %procedures  tab group
            obj.controls.procsTabs = uitabgroup('Parent',obj.fig,'Position',[0.03 .01 .77 .15]);
            obj.controls.acquireTab = uitab(obj.controls.procsTabs,'Title','Acquire');
            obj.controls.abrTab = uitab(obj.controls.procsTabs,'Title','ABR');
            obj.controls.tuningCurveTab = uitab(obj.controls.procsTabs,'Title','Tuning_Curve');
            obj.controls.monauralTab = uitab(obj.controls.procsTabs,'Title','Monaural/Diotic');
            obj.controls.itdTab = uitab(obj.controls.procsTabs,'Title','ITD_ILD');
            obj.controls.lazerTab = uitab(obj.controls.procsTabs,'Title','Laser_Train');
            obj.controls.utilsTab = uitab(obj.controls.procsTabs,'Title','Utility_Functions');
            obj.controls.binauralUnmaskingTab = uitab(obj.controls.procsTabs,'Title','Binaural_Unmasking');
            
            
            %settings tab Group
            settingsTabs = uitabgroup('Parent',obj.fig,'Position',[.81 .01 0.99 .8]);
            obj.controls.stimSettingsMenu = uitab(settingsTabs,'Title','Stimulus Settings');
            obj.controls.acqSettingsMenu = uitab(settingsTabs,'Title','Acquisition Settings');
            
            
            %setup info
            obj.infoBox = uicontrol('Parent', obj.fig,'style','edit',...
                'units','pix',...
                'posit',[1065 700 210 30],'string', ['info...'] ,'fontsize',9, 'backgroundColor',[0.7 0.7 0.7]);
            
            %users and calibration
            uicontrol('Parent', obj.fig,'style','tex','unit','pix','posit',[1080 790 180 20],...
                'fontsize',15,'fontname','Courier New',...
                'string','User:');
            
            
            %get files in settings folder
            files = obj.getSettingsFiles;
            
            uicontrol('Parent', obj.fig,'style','push',...
                'units','pix',...
                'posit',[1080 740 180 20],'string', 'Save User Settings','fontsize',10,'Callback',@obj.saveSettings);
            
            
            obj.controls.userSettingsPopup = uicontrol('Parent',obj.fig,'style','pop',...
                'unit','pix',...
                'position',[1080 770 180 20],...
                'fontsize',12,...
                'string',files,...
                'Callback', @obj.loadSettingsFile);
            
            
            obj.setupStimMenu;
            obj.setupAcqMenu;
            obj.setupAcquireMenu;
            obj.setupAbrMenu; 
            obj.setupTuningCurveMenu;
            obj.setupMonauralMenu;
            obj.setupItdIldMenu;
            obj.setupUtilFns;
            obj.setupLaserTab;
            obj.setupBinUnmaskMenu;
            

            %run button%_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', obj.fig,'style','push',...
                'units','pix',...
                'posit',[750 60 100 45],'string', 'Run','backg',[0 1 0 ],'fontsize',12,'Callback',@(h,e)obj.run);
            
            
            %stop button%_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', obj.fig,'style','push',...
                'units','pix',...
                'posit',[750 15 100 45],'string', 'Stop','backg',[0 1 0.5 ],'fontsize',12,'Callback',@(h,e)obj.stopEverything);
            
            
            %update button%_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', obj.fig,'style','push',...
                'units','pix',...
                'posit',[850 60 100 45],'string', 'Update','backg',[0 0.75 0.75 ],'fontsize',12,'Callback',@(h,e)obj.update);
            
            
            %save button%_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', obj.fig,'style','push',...
                'units','pix',...
                'posit',[850 15 100 45],'string', 'Save','backg',[0 0.5 1],'fontsize',12,'Callback',@(h,e)obj.save);

        end

        
        function run(obj)
            
            SETTINGS = obj.gatherSettings;
            n_acqs = str2double(obj.controls.numAcqs.String);
            
            obj.infoBox.String = 'running...';
            switch obj.controls.procsTabs.SelectedTab.Title 

                case 'Acquire'
                    
                  if obj.controls.accumMode.Value 
                    
                       [obj.tempData, obj.tempStimulus]= StimGuiProcedures.getData(obj.TDT,SETTINGS,n_acqs,...
                           obj.axes1, obj.axes2 );

                  elseif obj.controls.searchMode.Value
                      
                      StimGuiProcedures.searchMode(obj.TDT,SETTINGS,n_acqs, obj.axes1, obj.axes2 );
                      obj.infoBox.String = 'done.';
                      return
                      
                  elseif obj.controls.avgMode.Value
                      
                      [obj.tempData, obj.tempStimulus] = StimGuiProcedures.getData(obj.TDT,SETTINGS,n_acqs,...
                          obj.axes1, obj.axes2, true );
                  end     
                    
                  
                case 'ABR'
                    
                    freqs = obj.controls.abrFreqs.String;
                    freqs = regexprep(freqs,'click','0');
                    freqs = regexprep(freqs,'noise','1');
                    freqs = str2num(freqs);

                    levels = str2num(obj.controls.abrLevels.String);
                    averages = str2num(obj.controls.abrAverages.String);
                    
                    obj.infoBox.String = 'Abr Procedure...';
                    
                    [obj.tempData] = StimGuiProcedures.abrProcedure(obj.TDT, SETTINGS, freqs, levels,...
                        averages, obj.calibration ,obj.axes1, obj.axes2);
                    
                    obj.infoBox.String = 'done.';
                    
                    
                case 'Tuning_Curve'
                    
                    freqs = obj.controls.tuningFreqs.String;
                    levels = str2num(obj.controls.tuningLevels.String);
                    averges = str2num(obj.controls.tuningAverages.String);
                    alternate_laser = obj.controls.tuningLaserAlternate.Value;
                    shuffle = obj.controls.tuningShuffle.Value;
                    startWithZeros = obj.controls.startWithZeros.Value;
                    
                    splits = strsplit(freqs,':');
                    centerFreq = str2num(splits{1});
                    octaves = str2num(splits{2});
                    divisions = str2num(splits{3});
                    
                    
                    args=[];
                    args.centerFreq = centerFreq;
                    args.octaves = octaves;
                    args.divisions = divisions;
                    args.levels = levels;
                    args.averges = averges;
                    args.alternate_laser = alternate_laser;
                    args.shuffle = shuffle;
                    args.startWithZeros = startWithZeros; 
                    
                    obj.tempData = StimGuiProcedures.tuningProcedure(obj.TDT, SETTINGS, args, ...
                        obj.calibration, obj.axes1, obj.axes2);

                case 'ITD_ILD'
                    
                    if obj.controls.itdMode.Value
                        
                        itdRange = str2num(obj.controls.itdRange.String)/1000;
                        averages = str2num(obj.controls.itdIldAverages.String);
                        
                        obj.tempData  = StimGuiProcedures.itdProc(obj.TDT, SETTINGS, itdRange, ...
                            averages, obj.axes1, obj.axes2);

                         
                    elseif obj.controls.ildMode.Value
                        
                        ildRange = str2num(obj.controls.ildRange.String);
                        averages = str2num(obj.controls.itdIldAverages.String);
                        
                        SETTINGS = obj.gatherSettings; 
                        
                        obj.tempData  = StimGuiProcedures.ildProc(obj.TDT, SETTINGS, ildRange, ...
                            averages, obj.calibration, SETTINGS.stim_level_dB, SETTINGS.tone_frequency_hz,...
                            obj.axes1, obj.axes2);

                    end     
                    
  
                    
                case 'Monaural/Diotic'    
                    
                    averages = str2num(obj.controls.monauralAverages.String);
                    obj.tempData = StimGuiProcedures.monaurlProc(obj.TDT,SETTINGS, averages, obj.axes1, obj.axes2);
                    
                case 'Utility_Functions'
                    
                    
                    
                case 'Laser_Train'    
                    
                    args.laser_on = str2num(obj.controls.laserProcOnTime.String);
                    args.laser_off = str2num(obj.controls.laserProcOffTime.String);
                    args.laser_reps = str2num(obj.controls.laserProcReps.String);
                    obj.tempData = StimGuiProcedures.laserStimTrain(obj.TDT,SETTINGS, args, obj.axes1, obj.axes2);
                    
                case 'Binaural_Unmasking'

                    SETTINGS = obj.gatherSettings; % like pressing the Update button
                
                    args = [];
                    args.tone_dBs           = str2num(obj.controls.tone_dBs.String);
                    args.noise_dB           = str2num(obj.controls.noise_dB.String);
                    args.averages           = str2num(obj.controls.binUnmaskAverages.String);
                    args.NoSo               = obj.controls.NoSo.Value;
                    args.NoSp               = obj.controls.NoSp.Value;
                    args.NpSo               = obj.controls.NpSo.Value;
                    args.NpSp               = obj.controls.NpSp.Value;
                    args.interleave_noise   = obj.controls.interleaveNoise.Value;
                    args.shuffleTone_dBs    = obj.controls.shuffleTone_dBs.Value;
                    
                    obj.tempData  = StimGuiProcedures.binauralUnmasking(obj.TDT, SETTINGS,...
                        args,...
                        obj.calibration,...
                        obj.axes1,...
                        obj.axes2);
                    % TODO
                    % Vars below ARE NEEDED, but should be in SETTINGS,
                    % TODO: double check...
                    %obj.calibration, SETTINGS.stim_level_dB, SETTINGS.tone_frequency_hz
                    % all times (acq time, stim time, etc...)
                    
                otherwise 
                    error('wtf error')
                    
            end        
            
            if SETTINGS.auto_save
                
                DATA.data = obj.tempData;
                DATA.stimulus = obj.tempStimulus;
                DATA.settings = SETTINGS;
                DATA.procedure = obj.controls.procsTabs.SelectedTab.Title;
                DATA.sample_rate = obj.TDT.fs;
                DATA.n_traces = size(DATA.data,1);
                
                timestamp = regexprep(datestr(now),'[-: ]','_');
                tag = SETTINGS.save_tag;
                
                root_dir = obj.controls.root_dir.String; 
                if ~exist(root_dir, 'dir')
                    mkdir(root_dir)
                end     

                try
                    save([root_dir filesep 'DATA_' tag timestamp], 'DATA');
                catch 
                    disp('Tag is invalid for file name, removing... ')
                    save([root_dir filesep 'DATA_' timestamp], 'DATA');
                end     
            end    
            
            %send to workspace
            assignin('base','DATA', DATA);
            obj.infoBox.String = 'done.';

        end 
        
        
        function stopEverything(~)
            global RUNNING 
            RUNNING=0; 
        end 
        
        function update(obj)
            global UPDATE 
            UPDATE=1; 
            global sets 
            sets = obj.gatherSettings;
            obj.infoBox.String = 'UPDATED...';
        end
        
        function save(obj)
            
            DATA.data = obj.tempData;
            DATA.stimulus = obj.tempStimulus;
            DATA.settings = obj.gatherSettings;
            DATA.procedure = obj.controls.procsTabs.SelectedTab.Title;
            DATA.sample_rate = obj.TDT.fs;
            DATA.n_traces = size(DATA.data,1);
            
            [file, folder] = uiputfile('.mat');
            filepath = [folder filesep file];
            save(filepath, 'DATA');
            obj.infoBox.String = 'Saved...';
            
        end
        
        
        function acquireRadioBtns(obj,h,~)
            
            value = get(h,'value');
            
            if value==1
                %set all radio btns off
                
                obj.controls.accumMode.Value =0;
                obj.controls.searchMode.Value =0;
                obj.controls.avgMode.Value =0;
                
                %turn our btn on
                set(h,'value',value);
            end
        end
        
        
        function loadSettingsFile(obj,h,~)
            
            if ischar(h)
                file = h;
            else
                file = h.String{h.Value};
            end
            
            path = which('stimGui.m');
            [folderpath]= fileparts(path);
            fullPath = [folderpath filesep 'UserSettings' filesep file];
            temp = load(fullPath);
            fields = fieldnames(temp);
            obj.userSettings = temp.(fields{1});
            
            SETTINGS = obj.userSettings;
            fields = fieldnames(SETTINGS);
            
            radioBtnFields ={'laser_on','am_modulation', 'fm_modulation','auto_save','display_output', 'display_input', 'raster'};
            stringFields = {'save_tag','root_dir','ylims1','ylims2','gain_units'};
            
            for ii=1:length(fields)
                if ismember(fields{ii},radioBtnFields)
                    obj.controls.(fields{ii}).Value = SETTINGS.(fields{ii});
                elseif ismember(fields{ii},stringFields)
                    obj.controls.(fields{ii}).String = SETTINGS.(fields{ii});
                else
                    obj.controls.(fields{ii}).Value = SETTINGS.(fields{ii});
                end
                
            end
            
            obj.infoBox.String = ['Loaded Settings:' file];
        end
        
        
        function saveSettings(obj,~,~)
            
            file = obj.controls.userSettingsPopup.String{obj.controls.userSettingsPopup.Value}; 
            path = which('stimGui.m');
            [folderpath]= fileparts(path);
            fullPath = [folderpath filesep 'UserSettings' filesep file];
            SETTINGS = obj.gatherSettings; 
            save(fullPath,'SETTINGS');
            
        end     
        
        
        function SETTINGS = gatherSettings(obj)
            
            SETTINGS = obj.userSettings;
            fields = fieldnames(SETTINGS);
            
            SETTINGS.channel_in = [];
            SETTINGS.channel_out = []; 
            
            radioBtnFields ={'laser_on','am_modulation', 'fm_modulation','auto_save','display_output', 'display_input', 'raster', 'auto_scale'};
            stringFields = {'save_tag','root_dir','ylims1','ylims2'};
            pulldownFields = {'gain_units'};
            hiddenFields = {'masking_noise_V'};
            
            for ii=1:length(fields)
                
                if ismember(fields{ii},radioBtnFields)
                    
                    SETTINGS.(fields{ii}) = obj.controls.(fields{ii}).Value;
                    
                elseif ismember(fields{ii},stringFields)
                    
                    SETTINGS.(fields{ii}) = obj.controls.(fields{ii}).String;
                    
                elseif ismember(fields{ii},pulldownFields)      % causing problems, think it tries to pull a Val but should pull string? comment out for now...
                       
                    %val =obj.controls.(fields{ii}).Value;  
                    %SETTINGS.(fields{ii}) = obj.controls.(fields{ii}).String{val};
                    SETTINGS.(fields{ii}) = 'linear';   % quick & dirty fix. if 'gain_units' need to be in dB later...
                        %address by commenting out line above, uncommenting
                        %the 2 lines above it, and troubleshooting
                        
                elseif ismember(fields{ii},hiddenFields)
                    
                    SETTINGS.(fields{ii}) = obj.controls.(fields{ii}).Value;
                    
                else
                    if ~strcmpi((fields{ii}), 'stim_voltage_V_B')
                        SETTINGS.(fields{ii}) = obj.controls.(fields{ii}).Value;
                    end 
                end
                
            end
            
            
            
            %get appropriate voltage
            db = SETTINGS.stim_level_dB; 

            switch SETTINGS.stim_type
                case 1 
                    freq = SETTINGS.tone_frequency_hz;
                case 2 
                    freq = 2;
                case 3
                    freq = 1;
            end         

            volts = obj.calibration(round(db),round(freq));
            SETTINGS.stim_voltage_V = volts; 
            
            %compute volt offset for ild  
            if SETTINGS.ILD_dB >=0 
                SETTINGS.stim_voltage_V_B = obj.calibration(round(db - SETTINGS.ILD_dB),round(freq));
            else
                SETTINGS.stim_voltage_V_B = SETTINGS.stim_voltage_V; 
                SETTINGS.stim_voltage_V = obj.calibration(round(db + SETTINGS.ILD_dB),round(freq));
            end     

            obj.controls.stim_voltage_V.Value = volts; 
            
        end     

        
        function setupStimMenu(obj)
            
            SETTINGS = StimGuiUserSettings;
            fields = fieldnames(SETTINGS);
            
            stimFields = {'stimulus_length_ms','acquire_length_ms','stimulus_start_ms','stimulus_stop_ms'...
                'rise_fall_ms','ITD_ms','ILD_dB','freq_shift_hz','stim_voltage_V', 'stim_level_dB', ...
                'tone_frequency_hz', 'laser_on','laser_on_time_ms','laser_delay_ms','am_modulation',...
                'am_modulation_freq_hz','fm_modulation','fm_modulation_freq_hz','modulation_depth'};
            
            radioBtnFields ={'laser_on','am_modulation', 'fm_modulation'};
            count=1;
            for ii=1:length(fields)
                if ismember(fields{ii}, stimFields)
                    
                    if ismember(fields{ii},radioBtnFields)
                        obj.controls.(fields{ii})= uicontrol('Parent', obj.controls.stimSettingsMenu, 'Style', 'radio', 'String', fields{ii}, ...
                            'HorizontalAlignment', 'left', 'Position', [130 650-count*25 100 20],'Value', SETTINGS.(fields{ii})) ;
                        count =count+1;
                    else
                        
                        uicontrol('Parent', obj.controls.stimSettingsMenu, 'Style', 'text', 'String', fields{ii}, ...
                            'HorizontalAlignment', 'left', 'Position', [10 650-count*25 120 20]) ;
                        jModel = javax.swing.SpinnerNumberModel(SETTINGS.(fields{ii}),-100000,100000,1);
                        jSpinner = javax.swing.JSpinner(jModel);
                        
                        obj.controls.(fields{ii}) = javacomponent(jSpinner, [130 650-count*25 100 20], obj.controls.stimSettingsMenu);
                        count =count+1;
                    end
                    
                end
            end
            
            
            obj.controls.randomize_stimulus= uicontrol('Parent', obj.controls.stimSettingsMenu, 'Style', 'radio', 'String', 'randomize', ...
                'HorizontalAlignment', 'left', 'Position', [130 630-count*25 100 20]) ;
            
            uicontrol('Parent', obj.controls.stimSettingsMenu, 'Style', 'text', 'String', 'Stimulus Type:', ...
                'HorizontalAlignment', 'left', 'Position', [10 130 100 20]) ;
            
            obj.controls.stim_type= uicontrol('Parent', obj.controls.stimSettingsMenu, 'Style', 'popup', 'String',...
                {'Tone','WhiteNoise','Impulse'}, ...
                'HorizontalAlignment', 'left', 'Position', [130 130 100 20]) ;
            
        end
        
        
        function setupAcqMenu(obj)
            
            SETTINGS = StimGuiUserSettings;
            fields = fieldnames(SETTINGS);
            
            acqFields = {'hpf_in_hz','lpf_in_hz','notch_in_hz','hpf_out_hz','lpf_out_hz','raster','raster_V',...
                'display_output','display_input','amp_gain','micResponse_mVperPa','max_voltage_V','save_tag','root_dir',...
                'ylims1','ylims2','auto_save', 'auto_scale'};
            
            radioBtnFields ={'auto_save','display_output', 'display_input', 'raster', 'auto_scale'};
            stringFields = {'save_tag','root_dir','ylims1','ylims2'};
            
            
            count=1;
            for ii=1:length(fields)
                if ismember(fields{ii}, acqFields)
                       
                    if ismember(fields{ii},radioBtnFields)
                        obj.controls.(fields{ii})= uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'radio', 'String', fields{ii}, ...
                            'HorizontalAlignment', 'left', 'Position', [130 650-count*25 100 20], 'Value', SETTINGS.(fields{ii})) ;
                        count =count+1;
                        
                    elseif ismember(fields{ii},stringFields)
                        
                        uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'text', 'String', fields{ii}, ...
                            'HorizontalAlignment', 'left', 'Position', [10 650-count*25 120 20]) ;
                        
                        obj.controls.(fields{ii})= uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'edit', 'String', SETTINGS.(fields{ii}), ...
                            'HorizontalAlignment', 'left', 'Position', [130 650-count*25 100 20]) ;
                        
                        count =count+1;
                    else
                        
                        uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'text', 'String', fields{ii}, ...
                            'HorizontalAlignment', 'left', 'Position', [10 650-count*25 120 20]) ;
                        jModel = javax.swing.SpinnerNumberModel(SETTINGS.(fields{ii}),-100000,100000,1);
                        jSpinner = javax.swing.JSpinner(jModel);
                        
                        obj.controls.(fields{ii}) = javacomponent(jSpinner, [130 650-count*25 100 20], obj.controls.acqSettingsMenu);
                        count =count+1;
                    end
                    
                end
            end
            
            
            uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'text', 'String', 'Gain Units:', ...
                'HorizontalAlignment', 'left', 'Position', [10 170 100 20]) ;
            
            obj.controls.gain_units = uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'popup', 'String', {'dB', 'linear'}, ...
                'HorizontalAlignment', 'left', 'Position', [118 170 100 20]) ;
            
            
            uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'text', 'String', 'Channel In:', ...
                'HorizontalAlignment', 'left', 'Position', [10 140 100 20]) ;
            
            
            obj.controls.channel_in = uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'popup', 'String', {'In-A','In-B','Both', 'Optical'}, ...
                'HorizontalAlignment', 'left', 'Position', [118 140 100 20]) ;
            
            
            
            uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'text', 'String', 'Channel Out:', ...
                'HorizontalAlignment', 'left', 'Position', [10 110 100 20]) ;
            
            
            obj.controls.channel_out = uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'popup', 'String',...
                {'Out-A','Out-B','Both'}, ...
                'HorizontalAlignment', 'left', 'Position', [118 110 100 20]) ;
            
            
            %get files in calibration  folder
            files = obj.getCalibrationFiles;
            
            uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'text', 'String', 'Calibration:', ...
                'HorizontalAlignment', 'left', 'Position', [10 70 100 20]) ;
            
            obj.controls.cal_A = uicontrol('Parent', obj.controls.acqSettingsMenu, 'Style', 'popup', 'String',...
                files, ...
                'HorizontalAlignment', 'left', 'Position', [118 70 100 20], 'callback', @(h,e)obj.loadCalibrationFiles) ;
            
            
        end
        

        
        function setupAcquireMenu(obj)
            %the acquire menu --------------------------------------------------------------------------%%%%%%%%%%%%
            obj.controls.searchMode =  uicontrol('Parent',obj.controls.acquireTab,'style','rad',...
                'unit','pix',...
                'position',[20 70 180 20],...
                'string','Search Mode (O-scope)','Callback',@obj.acquireRadioBtns, 'value',1);
            
            obj.controls.accumMode =  uicontrol('Parent',obj.controls.acquireTab,'style','rad',...
                'unit','pix',...
                'position',[300 70 150 20],...
                'string','Accumulate Traces','Callback',@obj.acquireRadioBtns);
            
            obj.controls.avgMode = uicontrol('Parent',obj.controls.acquireTab,'style','rad',...
                'unit','pix',...
                'position',[300 50 100 20],...
                'string','Average Traces','Callback', @obj.acquireRadioBtns);
            
            uicontrol('Parent', obj.controls.acquireTab, 'Style', 'text', 'String', 'N Acquisitions:', ...
                'HorizontalAlignment', 'left', 'Position', [250 20 100 20]) ;
            
            obj.controls.numAcqs = uicontrol('Parent', obj.controls.acquireTab, 'Style', 'edit', 'String', '5', ...
                'HorizontalAlignment', 'right', 'Position', [350 20 100 20]) ;
            
        end     
        
        
        function setupAbrMenu(obj)
            
            uicontrol('Parent', obj.controls.abrTab, 'Style', 'text', 'String', 'Abr Freqs:', ...
                'HorizontalAlignment', 'left', 'Position', [10 70 100 20]) ;
            
            obj.controls.abrFreqs = uicontrol('Parent', obj.controls.abrTab, 'Style', 'edit', 'String',...
                'click, 500, 1000, 4000, 8000,16000', ...
                'HorizontalAlignment', 'center', 'Position', [118 70 300 20]) ;
            
            
            uicontrol('Parent', obj.controls.abrTab, 'Style', 'text', 'String', 'Abr Levels:', ...
                'HorizontalAlignment', 'left', 'Position', [10 50 100 20]) ;
            
            obj.controls.abrLevels = uicontrol('Parent', obj.controls.abrTab, 'Style', 'edit', 'String',...
                '90,80,70,60,50,40,30', ...
                'HorizontalAlignment', 'center', 'Position', [118 50 300 20]) ;
            
            
            uicontrol('Parent', obj.controls.abrTab, 'Style', 'text', 'String', 'Abr Averages:', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20]) ;
            
            obj.controls.abrAverages = uicontrol('Parent', obj.controls.abrTab, 'Style', 'edit', 'String',...
                '512', ...
                'HorizontalAlignment', 'center', 'Position', [118 30 100 20]) ;
 
            
        end 
        
        
        function setupTuningCurveMenu(obj)
            
            uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'text', 'String', 'TuningCruveFreqs:', ...
                'HorizontalAlignment', 'left', 'Position', [10 70 100 20]) ;
            
            obj.controls.tuningFreqs = uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'edit', 'String',...
                '1000:1:8', ...
                'HorizontalAlignment', 'center', 'Position', [118 70 300 20]) ;
            
            
            uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'text', 'String', 'dB Range:', ...
                'HorizontalAlignment', 'left', 'Position', [10 50 100 20]) ;
            
            obj.controls.tuningLevels = uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'edit', 'String',...
                '30:10:90', ...
                'HorizontalAlignment', 'center', 'Position', [118 50 300 20]) ;
            
            
            uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'text', 'String', 'TuningCurveAvgs:', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20]) ;
            
            obj.controls.tuningAverages = uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'edit', 'String',...
                '10', ...
                'HorizontalAlignment', 'center', 'Position', [118 30 100 20]) ;
            
            
            obj.controls.tuningLaserAlternate = uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'radio', 'String', 'Alternate Laser?', ...
                'HorizontalAlignment', 'left', 'Position', [500 70 100 20]) ;
            
            obj.controls.tuningShuffle = uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'radio', 'String', 'Shuffle?', ...
                'HorizontalAlignment', 'left', 'Position', [500 50 100 20]) ;
            
            obj.controls.startWithZeros = uicontrol('Parent', obj.controls.tuningCurveTab, 'Style', 'radio', 'String', 'StartWithZeros?', ...
                'HorizontalAlignment', 'left', 'Position', [500 30 100 20]) ;

        end     
        
        
        function setupMonauralMenu(obj)
            
            uicontrol('Parent', obj.controls.monauralTab, 'Style', 'text', 'String', 'Averges:', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20]) ;
            
            obj.controls.monauralAverages = uicontrol('Parent', obj.controls.monauralTab, 'Style', 'edit', 'String',...
                '20', ...
                'HorizontalAlignment', 'center', 'Position', [118 30 100 20]) ;
            
        end     
        
        
        function setupLaserTab(obj)
            
            uicontrol('Parent', obj.controls.lazerTab, 'Style', 'text', 'String', 'ontime(ms):', ...
                'HorizontalAlignment', 'left', 'Position', [10 50 100 20]) ;
            
            obj.controls.laserProcOnTime = uicontrol('Parent', obj.controls.lazerTab, 'Style', 'edit', 'String',...
                '20', ...
                'HorizontalAlignment', 'center', 'Position', [118 50 100 20]) ;
            
            uicontrol('Parent', obj.controls.lazerTab, 'Style', 'text', 'String', 'offtime(ms):', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20]) ;
            
            obj.controls.laserProcOffTime = uicontrol('Parent', obj.controls.lazerTab, 'Style', 'edit', 'String',...
                '20', ...
                'HorizontalAlignment', 'center', 'Position', [118 30 100 20]) ;
            
            
            uicontrol('Parent', obj.controls.lazerTab, 'Style', 'text', 'String', 'reps:', ...
                'HorizontalAlignment', 'left', 'Position', [10 10 100 20]) ;
            
            obj.controls.laserProcReps = uicontrol('Parent', obj.controls.lazerTab, 'Style', 'edit', 'String',...
                '50', ...
                'HorizontalAlignment', 'center', 'Position', [118 10 100 20]) ;

        end     
        
        
        

        function setupItdIldMenu(obj)
            
            uicontrol('Parent', obj.controls.itdTab , 'Style', 'text', 'String', 'ITD range:', ...
                'HorizontalAlignment', 'left', 'Position', [10 70 100 20]) ;
            
            obj.controls.itdRange = uicontrol('Parent', obj.controls.itdTab, 'Style', 'edit', 'String',...
                '-500:50:500', ...
                'HorizontalAlignment', 'center', 'Position', [118 70 300 20]) ;
            
            
            uicontrol('Parent', obj.controls.itdTab, 'Style', 'text', 'String', 'ILD range', ...
                'HorizontalAlignment', 'left', 'Position', [10 50 100 20]) ;
            
            obj.controls.ildRange = uicontrol('Parent', obj.controls.itdTab, 'Style', 'edit', 'String',...
                '-20:1:20', ...
                'HorizontalAlignment', 'center', 'Position', [118 50 300 20]) ;
            
            
            uicontrol('Parent', obj.controls.itdTab, 'Style', 'text', 'String', 'Avergaes:', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20]) ;
            
            obj.controls.itdIldAverages = uicontrol('Parent', obj.controls.itdTab, 'Style', 'edit', 'String',...
                '10', ...
                'HorizontalAlignment', 'center', 'Position', [118 30 100 20]) ;
            
            
            obj.controls.itdMode = uicontrol('Parent', obj.controls.itdTab, 'Style', 'radio', 'String', 'ITD Mode', ...
                'HorizontalAlignment', 'left', 'Position', [500 70 100 20]) ;
            
            obj.controls.ildMode = uicontrol('Parent', obj.controls.itdTab, 'Style', 'radio', 'String', 'ILD Mode', ...
                'HorizontalAlignment', 'left', 'Position', [500 50 100 20]) ;
            
        end     
        
        
        function setupUtilFns(obj)
            
            uicontrol('Parent', obj.controls.utilsTab, 'Style', 'push', 'String', 'SPL check', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20],...
                 'ToolTipString', 'DONT FORGET TO CHECK THE FILTERS AND GAIN',...
                'callback',...
                @(h,e)StimGuiProcedures.splCheck(obj.TDT, obj.gatherSettings)) ;
            
            uicontrol('Parent', obj.controls.utilsTab, 'Style', 'push', 'String', 'Make Calibration', ...
                'HorizontalAlignment', 'left', 'Position', [10 60 100 20],...
                 'ToolTipString', 'DONT FORGET TO CHECK THE FILTERS AND GAIN',...
                'callback',...
                @(h,e)StimGuiProcedures.makeCalibration(obj.TDT, obj.gatherSettings, obj.axes1, obj.axes2)) ;
            
        end     
        
        
        function setupBinUnmaskMenu(obj)

            uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'text', 'String', 'Tone dBs:', ...
                'HorizontalAlignment', 'left', 'Position', [10 70 100 20]) ;
            
            obj.controls.tone_dBs = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'edit', 'String',...
                '31:1:70', ...
                'HorizontalAlignment', 'center', 'Position', [80 70 80 20]);
            
            uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'text', 'String', 'Noise dB:', ...
                'HorizontalAlignment', 'left', 'Position', [10 50 100 20]) ;
            
            obj.controls.noise_dB = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'edit', 'String',...
                '42', ...
                'HorizontalAlignment', 'center', 'Position', [80 50 80 20]);
            
            temp_txt = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'text', 'String', 'set output filters!', ...
                'HorizontalAlignment', 'left', 'Position', [165 50 100 20]) ;
                    temp_txt.ForegroundColor = 'r'; clear temp_txt            

            uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'text', 'String', 'Averages:', ...
                'HorizontalAlignment', 'left', 'Position', [10 30 100 20]) ;
            
            obj.controls.binUnmaskAverages = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'edit', 'String',...
                '5', ...
                'HorizontalAlignment', 'center', 'Position', [80 30 80 20]) ;
            
            % Radio buttons NoSo, NoSp, NpSo, NpSp
            %NoSo
            obj.controls.NoSo = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'radio', 'String', 'NoSo', ...
                'HorizontalAlignment', 'left', 'Position', [300 70 100 20]);
            %NoSpi
            obj.controls.NoSp = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'radio', 'String', '<HTML>NoS&pi;</HTML>', ...
                'HorizontalAlignment', 'left', 'Position', [300 50 100 20]) ;
            %NpiSo
            obj.controls.NpSo = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'radio', 'String', '<HTML>N&pi;So</HTML>', ...
                'HorizontalAlignment', 'left', 'Position', [300 30 100 20]) ;
            %NpiSpi
            obj.controls.NpSp = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'radio', 'String', '<HTML>N&pi;S&pi;</HTML>', ...
                'HorizontalAlignment', 'left', 'Position', [300 10 100 20]) ;
            
            %Interleave noise (e.g. No, NoSo, No, NoSo,... Jiang et al. 1997 did this)
            obj.controls.interleaveNoise = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'checkbox', 'String', 'Interleave noise alone?', ...
                'HorizontalAlignment', 'left', 'Position', [400 70 200 20]) ;
            %Randomize tone dBs
            obj.controls.shuffleTone_dBs = uicontrol('Parent', obj.controls.binauralUnmaskingTab, 'Style', 'checkbox', 'String', 'Randomize tone dB?', ...
                'HorizontalAlignment', 'left', 'Position', [400 50 200 20]) ;
            
        end

        
        function loadCalibrationFiles(obj)
            
            fileA = obj.controls.cal_A.String{obj.controls.cal_A.Value};
               
            path = which('stimGui.m');
            [folderpath]= fileparts(path);
            fullPathA = [folderpath filesep 'Calibrations' filesep fileA];
            
            temp = load(fullPathA);
            fields = fieldnames(temp);
            calibrationA = temp.(fields{1});

            obj.calibration = calibrationA;
            
            obj.infoBox.String = ['Loaded Calibration...'];
        end
  
    end
    
    
    methods (Static, Access = private)
        function files = getSettingsFiles
            path = which('StimGui.m');
            [folderpath]= fileparts(path);
            INFO = dir([folderpath filesep 'UserSettings']);
            
            files ={};
            for ii=3:length(INFO)
                files{end+1} = INFO(ii).name;
            end
        end
        
        function files = getCalibrationFiles
            path = which('StimGui.m');
            [folderpath]= fileparts(path);
            INFO = dir([folderpath filesep 'Calibrations']);
            
            files ={};
            for ii=3:length(INFO)
                files{end+1} = INFO(ii).name;
            end
        end      
        
        
    end
    
    
end







