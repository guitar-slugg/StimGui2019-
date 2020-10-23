% GUI application for electro phys stuff (KEN OLD VERSION)

classdef Stim_gui < handle
    properties
        Figure
        control
        users
        data
    end
    methods %display figure 
        function obj = Stim_gui()
            opengl software
            
            %clear any existing figures 
            figTest= findobj('tag','STIM_GUI');
            if ~isempty(figTest)
                delete(figTest);
            end     
            
            obj.Figure = figure('position',[50 75 1300 850],...
                'name','Stim GUI','tag','STIM_GUI');
            
            %setup tabs and axis
            tgroup = uitabgroup('Parent', obj.Figure);
            tab2 = uitab('Parent', tgroup,'Title','Main');
            tgroup.SelectedTab = tab2; %default tab
            tab2.ForegroundColor = 'b';
            tab2.BackgroundColor = '[0.3 0.5 0.5]';      
                          
            obj.control.ax1=axes('Parent',tab2,'Position',[0.05, 0.45, 0.75, 0.5]);
            plot(obj.control.ax1,0:0.01:2*pi,sin(0:0.01:2*pi),0:0.01:2*pi,-sin(0:0.01:2*pi),'linewidth',5);
            xlim([0 2*pi])
            grid on
            obj.control.ax2=axes('Parent',tab2,'Position',[0.05, 0.2, 0.75, 0.20]);
            plot(obj.control.ax2,0:0.01:2*pi,sin(0:0.01:2*pi),0:0.01:2*pi,-sin(0:0.01:2*pi),'linewidth',5);
            xlim([0 2*pi])
            title(obj.control.ax1,'Acquired Signals')
            title(obj.control.ax2,'Stimulus')
            
            %users and calibration     
            uicontrol('Parent', tab2,'style','tex','unit','pix','posit',[1080 790 180 20],...
                    'fontsize',15,'fontname','Courier New',...
                    'string','User:');                             
            obj.control.user_menu = uicontrol('Parent',tab2,'style','pop',...
                 'unit','pix',...
                 'position',[1080 770 180 20],...
                 'fontsize',12,... 
                 'Callback', @(h,e)obj.user_menu_callback());               
            set(obj.control.user_menu,'string', char(obj.users))
            uicontrol('Parent', tab2,'style','push',...
                  'units','pix',...
                  'posit',[1080 740 180 20],'string', 'New User','fontsize',10,'Callback',@(h,e)obj.new_user());
              
            uicontrol('Parent', tab2,'style','push',...
                  'units','pix',...
                  'posit',[1080 720 180 20],'string', 'Save User Settings','fontsize',10,'Callback',@(h,e)obj.save_settings());              

            uicontrol('Parent', tab2,'style','push',...
                  'units','pix',...
                  'posit',[1080 700 180 20],'string', 'Load User Settings','fontsize',10,'Callback',@(h,e)obj.load_settings());  
                            
            %procedures 
            obj.control.tabgp1 = uitabgroup('Parent',tab2,'Position',[.1 .01 .7 .15]);
            obj.control.acq_menu = uitab(obj.control.tabgp1,'Title','Acquire');
            obj.control.ABR_menu = uitab(obj.control.tabgp1,'Title','ABR');
            obj.control.Tuning_curve_menu = uitab(obj.control.tabgp1,'Title','Tuning_Curve');
            obj.control.ITD_ILD_menu = uitab(obj.control.tabgp1,'Title','ITD_ILD');
            obj.control.Optogen_menu = uitab(obj.control.tabgp1,'Title','Optogenetics');
            obj.control.Utility_menu = uitab(obj.control.tabgp1,'Title','Utility_Functions');
              
            %settings tabs
            tabgp2 = uitabgroup('Parent',tab2,'Position',[.81 .01 0.99 .8]);
            settings_menu = uitab(tabgp2,'Title','Acq Settings');
            hardware_menu = uitab(tabgp2,'Title','RZ6 Settings');
            laser_menu = uitab(tabgp2,'Title','Laser Settings');
            
            %setup users 
            obj.users.Default=Stim_gui_user();
            obj.users.Cat=Stim_gui_user();
            obj.users.Brad=Stim_gui_user();
            obj.users.Ken=Stim_gui_user();
            obj.users.David=Stim_gui_user();
            obj.users.Lauren=Stim_gui_user();
            obj.users.DavidB=Stim_gui_user();
            mkdir('Default')
            set(obj.control.user_menu,'string', char(fieldnames(obj.users)))
            setting_names = properties(obj.users.Default);  
            obj.control.current_user = 'Default';
            
            for i=1:(length(setting_names))
                if(strcmp(setting_names{i},{'data_saving','raster','channel_in','channel_out','amp_gain','ylims1','ylims2'})~=1)
                     uicontrol('Parent', settings_menu, 'Style', 'text', 'String', setting_names{i}, ...
                    'HorizontalAlignment', 'left', 'Position', [10 630-i*30 100 20]) ;
                    if(max(strcmp(setting_names{i},{'rise_fall','stim_voltage','ITD'}))==1)
                        jModel = javax.swing.SpinnerNumberModel(obj.users.Default.(setting_names{i}),-100000,100000,0.1);
                    else    
                        jModel = javax.swing.SpinnerNumberModel(obj.users.Default.(setting_names{i}),-100000,100000,1);
                    end 
                    if(max(strcmp(setting_names{i},'tone_frequency'))==1)
                        jModel = javax.swing.SpinnerNumberModel(obj.users.Default.(setting_names{i}),-100000,100000,100);
                    end     
                    
                    jSpinner = javax.swing.JSpinner(jModel);
                    obj.control.(setting_names{i}) = javacomponent(jSpinner, [118 630-i*30 100 20], settings_menu);
                    set(obj.control.(setting_names{i}),'StateChangedCallback',@(h,e)obj.update_widgets());
                end
            end
            
            uicontrol('Parent', settings_menu, 'Style', 'text', 'String', 'Stimulus Type', ...
                    'HorizontalAlignment', 'left', 'Position', [10 330 100 20]) ;
                
            obj.control.stim_type =uicontrol('Parent',settings_menu,'style','pop',...
                 'unit','pix',...
                 'position',[118 330 100 20],...
                 'fontsize',12,'string',  {'Tone','Click','White_Noise'},... 
                 'Callback', @(h,e)obj.ttl_check(obj));   
            
           for i=1:(length(setting_names))
                if(max(strcmp(setting_names{i},{'raster','ylims2','ylims1','data_saving'}))==1)
                    obj.control.(setting_names{i})= uicontrol('Parent',settings_menu,'style','rad',...
                    'unit','pix',...
                    'position',[10 630-30*i 100 20],...
                    'string',setting_names{i},'Callback', @(h,e)obj.update_widgets()); 
                
                    obj.control.(strcat(setting_names{i},'edit'))= uicontrol('Parent',settings_menu,'style','edit',...
                    'unit','pix',...
                    'position',[118 630-30*i 100 20],...
                    'string', num2str(obj.users.Default.(setting_names{i})),'Callback', @(h,e)obj.update_widgets()); 
                end  
           end
           
           obj.control.sig_rand = uicontrol('Parent', settings_menu, 'style', 'rad', 'string','Randomize Stimulus','Position', [10 5 140 20]); 
                 
           %set up hardware stuff 
           uicontrol('Parent', hardware_menu, 'Style', 'text', 'String', 'Amp Gain', ...
                    'HorizontalAlignment', 'left', 'Position', [10 600 100 20]) ;              
            jModel = javax.swing.SpinnerNumberModel(obj.users.Default.amp_gain,-100000,100000,1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.amp_gain = javacomponent(jSpinner, [118 600 100 20], hardware_menu);
            set(obj.control.amp_gain,'StateChangedCallback',@(h,e)obj.update_widgets()); 
            
            obj.control.amp_gain_units = uicontrol('Parent', hardware_menu, 'Style', 'popupmenu',...
                 'String', {'dB','Linear'}, ...
                    'HorizontalAlignment', 'right', 'Position', [118 570 100 30]);
            
            uicontrol('Parent', hardware_menu, 'Style', 'text', 'String', 'Microphone Response (mV/Pa)', ...
                    'HorizontalAlignment', 'left', 'Position', [10 530 100 30]) ;  
            jModel = javax.swing.SpinnerNumberModel(4,-100000,100000,0.1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.mic_response = javacomponent(jSpinner, [118 530 100 20], hardware_menu);
            set(obj.control.mic_response,'StateChangedCallback',@(h,e)obj.update_widgets());  
            
            uicontrol('Parent', hardware_menu, 'Style', 'text', 'String', 'Calibration File', ...
                    'HorizontalAlignment', 'left', 'Position', [10 490 100 30]) ; 
                
            obj.control.calibration=uicontrol('Parent',hardware_menu,'style','edit',...
                 'unit','pix',...
                 'position',[90 500 150 20],...
                 'fontsize',12,'string', 'cal_4_7_18_in_ear_red_500Hzto20KHz_10to90dB_600Hzfilter_oldmic.mat',... 
                 'Callback', @(h,e)obj.update_widgets());    
            
            uicontrol('Parent', hardware_menu, 'Style', 'text', 'String', 'Channel in:', ...
                    'HorizontalAlignment', 'left', 'Position', [10 470 100 20]) ;  
            obj.control.channel_in=uicontrol('Parent',hardware_menu,'style','pop',...
                 'unit','pix',...
                 'position',[118 470 100 20],...
                 'fontsize',12,'string',  {'In_A','In_B','Optical'},... 
                 'Callback', @(h,e)obj.update_widgets());
             
            uicontrol('Parent', hardware_menu, 'Style', 'text', 'String', 'Channel out:', ...
                    'HorizontalAlignment', 'left', 'Position', [10 430 100 20]) ;  
            obj.control.channel_out=uicontrol('Parent',hardware_menu,'style','pop',...
                 'unit','pix',...
                 'position',[118 430 100 20],...
                 'fontsize',12,'string', {'Out_A','Out_B','Both'},... 
                 'Callback', @(h,e)obj.update_widgets());
             
            uicontrol('Parent', hardware_menu, 'Style', 'text', 'String', 'Max Output Voltage', ...
                    'HorizontalAlignment', 'left', 'Position', [10 390 100 30]) ;  
            jModel = javax.swing.SpinnerNumberModel(2,-100000,100000, 0.1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.max_voltage = javacomponent(jSpinner, [118 390 100 20], hardware_menu);
            set(obj.control.mic_response,'StateChangedCallback',@(h,e)obj.update_widgets());  
            
            
            %%%setup laser menu 
            laser_opts = {'Laser on?','Laser_On_Time','Laser_Delay'};
            laser_vals = {0,50,0};
            obj.control.laser_on = uicontrol('Parent', laser_menu, 'Style', 'Radio', 'String',laser_opts{1}, ...
                    'HorizontalAlignment', 'left', 'Position', [10 575 100 30],'value',laser_vals{1}) ; 
            
            for ii=2:length(laser_opts)
                uicontrol('Parent', laser_menu, 'Style', 'text', 'String',laser_opts{ii}, ...
                    'HorizontalAlignment', 'left', 'Position', [10 (600 - (30*ii)) 100 30]) ; 
                jModel = javax.swing.SpinnerNumberModel(laser_vals{ii},-100000,100000, 1);
                jSpinner = javax.swing.JSpinner(jModel);
                obj.control.(laser_opts{ii}) = javacomponent(jSpinner, [120 (600 - 25*ii) 100 20], laser_menu);
                set(obj.control.(laser_opts{ii}),'StateChangedCallback',@(h,e)obj.update_widgets()); 
            end     
            
             
            %the acquire menu --------------------------------------------------------------------------%%%%%%%%%%%% 
            obj.control.search_mode=uicontrol('Parent',obj.control.acq_menu,'style','rad',...
                    'unit','pix',...
                    'position',[20 70 180 20],...
                    'string','Search Mode (O-scope)','Callback', @(h,e)obj.update_widgets()); 
                
            obj.control.accum_mode=uicontrol('Parent',obj.control.acq_menu,'style','rad',...
                    'unit','pix',...
                    'position',[20 40 150 20],...
                    'string','Accumulate Traces','Callback', @(h,e)obj.update_widgets()); 
                
            obj.control.avg_mode=uicontrol('Parent',obj.control.acq_menu,'style','rad',...
                    'unit','pix',...
                    'position',[20 10 100 20],...
                    'string','Average Traces','Callback', @(h,e)obj.update_widgets());    
                
            uicontrol('Parent', obj.control.acq_menu, 'Style', 'text', 'String', 'Acquisitions:', ...
                    'HorizontalAlignment', 'left', 'Position', [250 40 100 30]) ;   
                
            jModel = javax.swing.SpinnerNumberModel(1000,1,100000,1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.trace_number = javacomponent(jSpinner, [250 10 100 30], obj.control.acq_menu);
            set(obj.control.trace_number,'StateChangedCallback',@(h,e)obj.update_widgets());  
            
            
            %the ABR menu %_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', obj.control.ABR_menu, 'Style', 'text', 'String', 'ABR freqs', ...
                    'HorizontalAlignment', 'left', 'Position', [20 70 200 20]) ;                 
            obj.control.ABR_freqs=uicontrol('Parent',obj.control.ABR_menu,'style','edit',...
                 'unit','pix',...
                 'position',[120 70 500 20],...
                 'fontsize',12,'string', 'click,500,1000,4000,8000,16000',... 
                 'Callback', @(h,e)obj.update_widgets());     
                
            uicontrol('Parent', obj.control.ABR_menu, 'Style', 'text', 'String', 'ABR dB levels', ...
                    'HorizontalAlignment', 'left', 'Position', [20 40 200 20]) ;                 
            obj.control.ABR_levels=uicontrol('Parent',obj.control.ABR_menu,'style','edit',...
                 'unit','pix',...
                 'position',[120 40 500 20],...
                 'fontsize',12,'string', '90,80,70,60,50,40,30,20',... 
                 'Callback', @(h,e)obj.update_widgets());   
            uicontrol('Parent', obj.control.ABR_menu, 'Style', 'text', 'String', 'ABR averages', ...
                    'HorizontalAlignment', 'left', 'Position', [20 10 200 20]) ;    
            jModel = javax.swing.SpinnerNumberModel(512,1,100000,1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.ABR_averages = javacomponent(jSpinner, [120 10 100 20], obj.control.ABR_menu);
            set(obj.control.ABR_averages,'StateChangedCallback',@(h,e)obj.update_widgets()); 
            
            %the tuning curve  menu %_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', obj.control.Tuning_curve_menu, 'Style', 'text', 'String', ' Freqs (center:octaves:steps)', ...
                    'HorizontalAlignment', 'left', 'Position', [20 70 200 20]) ;                 
            obj.control.Tuning_curve_freqs=uicontrol('Parent',obj.control.Tuning_curve_menu,'style','edit',...
                 'unit','pix',...
                 'position',[200 70 200 20],...
                 'fontsize',12,'string', '1000:1:8',... 
                 'Callback', @(h,e)obj.update_widgets());                
            uicontrol('Parent', obj.control.Tuning_curve_menu, 'Style', 'text', 'String', 'dB range (start:interval:end)', ...
                    'HorizontalAlignment', 'left', 'Position', [20 40 200 20]) ;                 
            obj.control.Tuning_curve_levels=uicontrol('Parent',obj.control.Tuning_curve_menu,'style','edit',...
                 'unit','pix',...
                 'position',[200 40 200 20],...
                 'fontsize',12,'string', '30:10:90',... 
                 'Callback', @(h,e)obj.update_widgets());   
            uicontrol('Parent', obj.control.Tuning_curve_menu, 'Style', 'text', 'String', 'averages', ...
                    'HorizontalAlignment', 'left', 'Position', [20 10 200 20]) ;    
            jModel = javax.swing.SpinnerNumberModel(10,1,100000,1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.tuning_curve_averages = javacomponent(jSpinner, [120 10 100 20], obj.control.Tuning_curve_menu);
            set(obj.control.tuning_curve_averages,'StateChangedCallback',@(h,e)obj.update_widgets()); 
            
            
            obj.control.laser_alternate = uicontrol('Parent', obj.control.Tuning_curve_menu, 'Style', 'radio', 'value', 0, ...
                    'string','Alternate laser?','Position', [300 10 200 20]) ; 
                
            obj.control.shuffle_tuning_curve = uicontrol('Parent', obj.control.Tuning_curve_menu, 'Style', 'radio', 'value', 0, ...
                    'string','Shuffle?','Position', [500 10 200 20]) ; 
                
            
            
            %the ITDILD  menu %_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
           obj.control.ITD_on=uicontrol('Parent',obj.control.ITD_ILD_menu,'style','radio',...
                 'unit','pix',...
                 'position',[120 70 120 20],...
                 'fontsize',10,'string', 'ITD Procedure',... 
                 'Callback', @(h,e)obj.update_widgets());  

            uicontrol('Parent', obj.control.ITD_ILD_menu, 'Style', 'text', 'String', ' ITD(uS)(-ITD:step:+ITD)', ...
                    'HorizontalAlignment', 'left', 'Position', [20 45 200 20]) ; 
            obj.control.ITD_range=uicontrol('Parent',obj.control.ITD_ILD_menu,'style','edit',...
                 'unit','pix',...
                 'position',[150 45 200 20],...
                 'fontsize',12,'string', '500:50:500',... 
                 'Callback', @(h,e)obj.update_widgets()); 
             
            obj.control.ILD_on=uicontrol('Parent',obj.control.ITD_ILD_menu,'style','radio',...
                 'unit','pix',...
                 'position',[120 25 120 20],...
                 'fontsize',10,'string', 'ILD Procedure',... 
                 'Callback', @(h,e)obj.update_widgets());   
             
            uicontrol('Parent', obj.control.ITD_ILD_menu, 'Style', 'text', 'String', ' ILD(dB)(-ILD:step:+ILD)', ...
                    'HorizontalAlignment', 'left', 'Position', [20 0 200 20]) ; 
                
            obj.control.ILD_range=uicontrol('Parent',obj.control.ITD_ILD_menu,'style','edit',...
                 'unit','pix',...
                 'position',[150 0 200 20],...
                 'fontsize',12,'string', '-20:1:20',... 
                 'Callback', @(h,e)obj.update_widgets()); 
             
            uicontrol('Parent', obj.control.ITD_ILD_menu, 'Style', 'text', 'String', 'Averages', ...
                    'HorizontalAlignment', 'left', 'Position', [370 30 200 20]) ;    
            jModel = javax.swing.SpinnerNumberModel(10,1,100000,1);
            jSpinner = javax.swing.JSpinner(jModel);
            obj.control.ITD_ILD_averages = javacomponent(jSpinner, [430 30 100 20], obj.control.ITD_ILD_menu);
            set(obj.control.ITD_ILD_averages,'StateChangedCallback',@(h,e)obj.update_widgets());  
             
             
            %util functions menu %________________________________%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.control.create_calibration = uicontrol('Parent', obj.control.Utility_menu,'style','push',...
                  'units','pix',...
                  'posit',[10 70 200 20],'string', 'Create Calibration File','backg','c','fontsize',12,'Callback',@(h,e)obj.create_calibration(obj));  
               
            obj.control.spl_check = uicontrol('Parent', obj.control.Utility_menu,'style','push',...
                  'units','pix',...
                  'posit',[10 40 200 20],'string', 'SPL Check','backg','c','fontsize',12,'Callback',@(h,e)obj.spl_check(obj));   
            
            %run buttons%_______________________________________________%%%%%%%%%%%%%%%%%%%%%%%%
            uicontrol('Parent', tab2,'style','push',...
                  'units','pix',...
                  'posit',[10 90 100 30],'string', 'Run','backg','g','fontsize',12,'Callback',@(h,e)obj.get_data_proc()); 
              
            obj.control.pausebtn=uicontrol('Parent', tab2,'style','push',...
                  'units','pix',...
                  'posit',[10 55 100 30],'string', 'Pause','backg','y','fontsize',12,'Callback',@(h,e)obj.pause_running(obj));                
            uicontrol('Parent', tab2,'style','push',...
                  'units','pix',...
                  'posit',[10 20 100 30],'string', 'Stop','backg','r','fontsize',12,'Callback',@(h,e)obj.stop_running()); 
        end  
    end
    methods %widget control functions 
        function user_menu_callback(obj)
            val= get(obj.control.user_menu,'Value');
            str_list = char(get(obj.control.user_menu,'String'));
            current_user = strtrim(str_list(val,:));
            setting_names = properties(Stim_gui_user);
            for i=1:length(setting_names)
                if(strcmp(setting_names{i},{'data_saving','raster','channel_in','channel_out','amp_gain','ylims1','ylims2'})~=1)
                     set(obj.control.(setting_names{i}),'value',(obj.users.(current_user).(setting_names{i})));
                end 
            end
            obj.control.current_user=current_user;
        end
        function new_user(obj)
            str = char(strtrim(inputdlg('Enter new user name')));
            obj.users.(str)=Stim_gui_user();
            set(obj.control.user_menu,'string', char(fieldnames(obj.users)))
            mkdir(str);
        end      
        function save_settings(obj)
            val= get(obj.control.user_menu,'Value');
            str_list = char(get(obj.control.user_menu,'String'));
            current_user = strtrim(str_list(val,:));
            setting_names = properties(Stim_gui_user); 
            for i=1:length(setting_names)
                 obj.users.(current_user).(setting_names{i}) = get(obj.control.(setting_names{i}),'value') ;
            end
            props = properties(obj.users.(obj.control.current_user));
            lenn=length(props);
            user_settings = cell(2,lenn);
            for i=1:lenn
               user_settings{1,i} =  props{i};
            end  
            for i=1:lenn
               user_settings{2,i} =  obj.users.(obj.control.current_user).(props{i});
            end       
            full_path = strcat(pwd,'\' ,obj.control.current_user,'\','Settings','.mat');
            save(full_path, 'user_settings')
        end
        function load_settings(obj)
            full_path = strcat(pwd,'\' ,obj.control.current_user,'\','Settings','.mat');
            settings = load(full_path, 'user_settings');
           setting_names = properties(Stim_gui_user);
           for i=1:length(setting_names)
                if(strcmp(setting_names{i},{'data_saving','raster','channel_in','channel_out','amp_gain','ylims1','ylims2'})~=1)
                     set(obj.control.(setting_names{i}),'value',(settings.user_settings{2,i}));
                     obj.users.(obj.control.current_user).(setting_names{i}) = settings.user_settings{2,i};
                end 
            end
        end 
        function update_widgets(~)
            global update 
            update =1;
        end             
        function get_data_proc(obj) %pass info to data gathering functions
            global runmode
            runmode =1;
            TDT = TDTRP('stim_gui2.rcx', 'RZ6'); %the TDT Struct  
            obj.data.dt = 1/(TDT.FS);
            %acquire tab
            if(strcmp(obj.control.tabgp1.SelectedTab.Title,'Acquire')==1)
                obj.normal_acquire(obj,TDT)
            %ABR tab
            elseif(strcmp(obj.control.tabgp1.SelectedTab.Title,'ABR')==1)
                obj.ABR_procedure(obj,TDT) 
            %Tuning Curve proc
            elseif(strcmp(obj.control.tabgp1.SelectedTab.Title,'Tuning_Curve')==1)
                obj.tuning_procedure(obj,TDT) 
            %ITD/ILD tab
            elseif(strcmp(obj.control.tabgp1.SelectedTab.Title,'ITD_ILD')==1)
                obj.ITD_ILD_procedure(obj,TDT) 
            %Optogenetics Tab
            elseif(strcmp(obj.control.tabgp1.SelectedTab.Title,'Optogenetics')==1)
                
            end
            TDT.halt;
        end
        function stop_running(~)
            global runmode
            runmode = 0;
        end
        function pause_running(obj,~)
            global runmode
            if(runmode ==2)
                set(obj.control.pausebtn,'backg','y')
                set(obj.control.pausebtn,'string', 'Pause')
                runmode =1;
            else
                runmode = 2;
                set(obj.control.pausebtn,'string', 'Resume')
            end
        end
        function spl_check(obj,~)
            TDT = TDTRP('stim_gui2.rcx', 'RZ6'); %the TDT Struct
            try
                info = inputdlg({'trials:','trial length (ms)','weighting (A or none)','High pass filter (Hz)','channel in'}, 'Input', [1 30;1 30;1 30;1 30;1 30], {'10','1000','A','20','B'});
                dt = 1/(TDT.FS);
                TDT.write('outA_switch', 0);
                TDT.write('outB_switch', 0);
                TDT.write('inHPF', str2double(info{4}));
                averages = str2double(info{1});
                samples = round(str2double(info{2})/(dt*1000));
                gain_units = get(obj.control.amp_gain_units,'value');
                if gain_units ==1 %in db 
                    gain = (10^((get(obj.control.amp_gain,'Value'))/20))*(get(obj.control.mic_response,'Value')*10^-3);
                else
                   gain = get(obj.control.amp_gain,'Value')*(get(obj.control.mic_response,'Value')*10^-3); 
                end     
                in_val= (info{5});
                if(strcmp(in_val,'A')==1)
                    TDT.write('in_chan', 1);
                elseif(strcmp(in_val,'B')==1)
                    TDT.write('in_chan', 2);
                end
                traces=zeros(averages,samples);
                dBs= zeros(averages,1);
                disp('running..')
                for i = 1:averages
                    TDT.trg(1);
                    while(TDT.read('in_i')<= samples);
                    end
                    traces(i,:) = (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                    if(strcmp(info{3},'A')==1)
                        traces(i,:) = filterA(traces(i,:), 1/dt);
                    end
                    dBs(i) = 20.*log10(sqrt(mean((traces(i,:)).^2))/(20e-6));
                end
                figure()
                plot(dBs)
                title('Ambient SPL')
                if(strcmp(info{3},'A')==1)
                    ylabel('dBA')
                else
                    ylabel('dB')
                end
                xlabel('trial')
                grid on
                disp('mean:')
                mean(dBs)
                TDT.halt;
            catch
                disp('failed')
                TDT.halt;
            end
        end
        function create_calibration(obj,~)
            TDT = TDTRP('stim_gui2.rcx', 'RZ6'); %the TDT Struct
            dt = 1/(TDT.FS);
            global runmode 
            runmode =1 ;
            try
                info = inputdlg({'low freq:','high freq:','freq interval','low dB:','high dB','dB interval','max output voltage','high pass filter'}, 'Settings', ...
                    [1 30;1 30;1 30;1 30;1 30;1 30;1 30;1 30], {'500','20000','250','10','90','5','2','200'});
                freq_array = str2double(info{1}):str2double(info{3}):str2double(info{2});
                db_array = str2double(info{4}):str2double(info{6}):str2double(info{5});
                max_voltage = str2double(info{7});
                TDT.write('inHPF', str2double(info{8}));
                % Apply output filters to stim (e.g. for band-limited noise
                % calibration. Also put a debug stop mark on ln ~626
                % (tones)
                %TDT.write('outHPF', get(obj.control.hpf_out,'Value'));
                %TDT.write('outHPF', get(obj.control.lpf_out,'Value'));
                Levels = zeros(100,20000);  % to return the voltage at db,freq
                in_val= get(obj.control.channel_in,'Value');
                out_val= get(obj.control.channel_out,'Value');
                
                gain_units = get(obj.control.amp_gain_units,'value');
                if gain_units ==1 %in db 
                    gain = (10^((get(obj.control.amp_gain,'Value'))/20))*(get(obj.control.mic_response,'Value')*10^-3);
                else
                   gain = get(obj.control.amp_gain,'Value')*(get(obj.control.mic_response,'Value')*10^-3); 
                end 
                
                if(in_val==1)
                    TDT.write('in_chan', 1);
                elseif(in_val==2)
                    TDT.write('in_chan', 2);
                end
                if(out_val==1)
                    TDT.write('outA_switch', 1);
                    TDT.write('outB_switch', 0);
                elseif(out_val==2)
                    TDT.write('outA_switch', 0);
                    TDT.write('outB_switch', 1);
                end
                disp('Creating Calibration file...')
                samples =500;
                
                %calibrate click
                voltage = 0.1;
                input_signal=zeros(1,samples);
                input_signal(5:6)=voltage;
                TDT.write('outB', input_signal, 0);
                TDT.write('outA', input_signal, 0);
                for j =1:length(db_array)
                    TDT.trg(1);
                    while(TDT.read('in_i')<= samples);
                    end
                    sig= (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                    db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));
                    while(db_got <= db_array(j)*0.98 || db_got >= db_array(j)*1.02)
                        if(db_got <= db_array(j))
                            voltage =voltage*1.11;
                            if(voltage>=max_voltage)
                                voltage=max_voltage;
                                break
                            end
                        end
                        if(db_got >= db_array(j))
                            voltage =voltage*0.92;
                        end
                        if(voltage >= max_voltage)
                            break
                        end
                        if(voltage <= 1e-6)
                            break
                        end                        
                        
                        input_signal=zeros(1,samples);
                        input_signal(5:6)=voltage;
                        TDT.write('outB', input_signal, 0);
                        TDT.write('outA', input_signal, 0);
                        TDT.trg(1);
                        while(TDT.read('in_i')<= samples);
                        end
                        sig= (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                        db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));
                        pause(0.00000001)
                        plot(obj.control.ax1,sig)
                        set(obj.control.stim_level,'Value',db_array(j))
                        if(runmode ~=1)
                            break
                        end
                    end
                    Levels(db_array(j),1)=voltage;
                end    
                
                %calibrate white noise 
                voltage = 0.1;
                samples=2500; 
                rando= (rand(1,samples)-0.5);
                input_signal=(voltage*2).*rando;
                TDT.write('outB', input_signal, 0);
                TDT.write('outA', input_signal, 0);
                for j =1:length(db_array)
                    TDT.trg(1);
                    while(TDT.read('in_i')<= samples);
                    end
                    sig= (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                    db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));
                    while(db_got <= db_array(j)*0.98 || db_got >= db_array(j)*1.02)
                        if(db_got <= db_array(j))
                            voltage =voltage*1.11;
                            if(voltage>=max_voltage)
                                voltage=max_voltage;
                                break
                            end
                        end
                        if(db_got >= db_array(j))
                            voltage =voltage*0.92;
                        end
                        if(voltage >= max_voltage)
                            break
                        end
                        if(voltage <= 1e-6)
                            break
                        end   
                        input_signal=(voltage*2).*rando;
                        TDT.write('outB', input_signal, 0);
                        TDT.write('outA', input_signal, 0);
                        TDT.trg(1);
                        while(TDT.read('in_i')<= samples);
                        end
                        sig= (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                        db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));
                        pause(0.00000001)
                        plot(obj.control.ax1,sig)
                        set(obj.control.stim_level,'Value',db_array(j))
                        if(runmode ~=1)
                            break
                        end
                    end
                    Levels(db_array(j),2)=voltage;
                end         
                
                %calibrate tones 
                for i= 1:length(freq_array)
                    voltage = 0.1;
                    input_signal = voltage.*(sin(freq_array(i)*2*pi*dt*(1:samples)));
                    TDT.write('outB', input_signal, 0);
                    TDT.write('outA', input_signal, 0);
                    for j = 1:length(db_array)
                        TDT.trg(1);
                        while(TDT.read('in_i')<= samples);
                        end
                        sig= (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                        db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));  
                        %here, simplify 
                        
                        
                        while(db_got <= db_array(j)*0.98 || db_got >= db_array(j)*1.02)
                            if(db_got <= db_array(j))
                                voltage =voltage*1.11;
                                if(voltage>=max_voltage)
                                    voltage=max_voltage;
                                    break
                                end     
                            end 
                            if(db_got >= db_array(j))
                                voltage =voltage*0.92;
                            end 
                            if(voltage >= max_voltage)
                                break
                            end
                            if(voltage <= 1e-6)
                                break
                            end     
                            input_signal = voltage.*(sin(freq_array(i)*2*pi*dt*(1:samples)));
                            TDT.write('outB', input_signal, 0);
                            TDT.write('outA', input_signal, 0);
                            TDT.trg(1);
                            while(TDT.read('in_i')<= samples);
                            end
                            sig= (TDT.read('in', 'OFFSET', 0, 'SIZE', samples))./gain;
                            db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));
                            pause(0.00000001)
                            plot(obj.control.ax1,sig)
                            set(obj.control.tone_frequency,'Value',freq_array(i))
                            set(obj.control.stim_level,'Value',db_array(j))
                            if(runmode ~=1)
                                break
                            end     
                        end 
                        Levels(db_array(j),freq_array(i))=voltage;
                    end
                end
                TDT.halt;
            catch
                disp('failed')
                TDT.halt;
            end                  
            %interpolate freqs
            for i = 1:length(db_array)
                for j =1:length(freq_array)-1
                    num1=Levels(db_array(i),freq_array(j));
                    num2=Levels(db_array(i),freq_array(j+1));
                    step=(num2-num1)/(freq_array(j+1)-freq_array(j));
                    for k = 1:(freq_array(j+1)-freq_array(j))
                        Levels(db_array(i),freq_array(j)+k) = num1+ k*step;
                    end
                end
            end
            %interpolate db levels for freqs 
            for i=freq_array(1):1:(freq_array(end))
               for j=1:length(db_array)-1
                    num1=Levels(db_array(j),i);
                    num2=Levels(db_array(j+1),i);
                    step=(num2-num1)/(db_array(j+1)-db_array(j));
                    for k=1:(db_array(j+1)-db_array(j))
                        Levels(db_array(j)+k,i)= num1+k*step;
                    end
               end
            end
            %interp db levels for the click & white noise 
            for i=1:2
               for j=1:length(db_array)-1
                    num1=Levels(db_array(j),i);
                    num2=Levels(db_array(j+1),i);
                    step=(num2-num1)/(db_array(j+1)-db_array(j));
                    for k=1:(db_array(j+1)-db_array(j))
                        Levels(db_array(j)+k,i)= num1+k*step;
                    end
               end
            end
            %save
            folder = strcat(pwd,'\' ,obj.control.current_user);
            [file,path] = uiputfile('*.mat','Save data As',folder);
            save((strcat(path,file)),'Levels')
        end
        
    end 
    methods (Static) %data functions
        function normal_acquire(obj,TDT)
            disp ok
                acqs = round(get(obj.control.trace_number,'Value'));
                if((get(obj.control.search_mode,'Value'))==1)
                    [traces, ~]=obj.get_data(obj,TDT,acqs,'accum');
                    plot(obj.control.ax1,0.*traces);
                elseif((get(obj.control.accum_mode,'Value'))==1)
                    [traces, time]=obj.get_data(obj,TDT,acqs,'accum');
                    plot(obj.control.ax1,time,traces);
                    obj.data.info = strcat(num2str(acqs),'accumulated traces');
                    obj.save_data(obj,traces,'traces')
                elseif((get(obj.control.avg_mode,'Value'))==1)
                    [traces, time]=obj.get_data(obj,TDT,acqs,'accum');
                    traces = mean(traces,1);
                    plot(obj.control.ax1,time,traces);
                    obj.data.info = strcat(num2str(acqs), 'Averages');
                    obj.save_data(obj,traces,'traces')
                end  
        end 
        function ABR_procedure(obj,TDT)        
            %get abr params 
            global runmode
            freqs = strsplit(get(obj.control.ABR_freqs,'String'),',');
            levels = strsplit(get(obj.control.ABR_levels,'String'),',');
            averages = get(obj.control.ABR_averages,'Value');
            ABR_data=zeros(round(get(obj.control.acquire_length,'Value')/(1000*(1/TDT.FS))),length(freqs)*length(levels));
            ABR_display= zeros(round(get(obj.control.acquire_length,'Value')/(1000*(1/TDT.FS))),length(freqs)*length(levels));
            %make stimulus and %data collection loop
            obj.control.abrs=figure('position',[50 75 500 850],...
                'name','ABRS');
            obj.control.abr_ax= axes('Parent', obj.control.abrs,'Position',[0.1, 0.1, 0.8, 0.8]);
            count=1;
            for i=1:length(freqs)
                if(strcmp(freqs{i},'click')==1)                    
                    set(obj.control.stim_type,'Value',2)
                elseif(strcmp(freqs{i},'noise')==1) 
                    set(obj.control.stim_type,'Value',3)
                else
                    set(obj.control.stim_type,'Value',1);
                    set(obj.control.tone_frequency,'Value',str2double(freqs{i}))
                end                          
                for j = 1:length(levels)
                    if(runmode==1)
                        
                        set(obj.control.stim_level,'Value',str2double(levels{j}));                   
                        [traces, time]=obj.get_data(obj,TDT,averages,'accum');
                        traces = mean(traces,1);
                        ABR_data(:,count)=traces;
                        plot(obj.control.ax1,time, traces);
                        ABR_display(:,count) = (traces./max(traces))-(count);
                        plot(obj.control.abr_ax,time, ABR_display);
                        title(obj.control.abr_ax, 'Normalized ABRS (for viewing)')
                        xlabel(obj.control.abr_ax,'time (s)')
                        count=count+1;
                    elseif(runmode==2)
                        count = 0;
                    while(runmode==2)
                        pause(0.5)
                        count = count + 0.5;
                        if(mod(count,1)==0)
                            set(obj.control.pausebtn,'backg','y')
                        else
                            set(obj.control.pausebtn,'backg','c')
                        end
                    end
                    else
                        break
                    end     
                end
            end   
            plot(obj.control.ax1,time, ABR_data);
            obj.data.info = strcat('freqs: ' , get(obj.control.ABR_freqs,'String') , ' levels: ' ,get(obj.control.ABR_levels,'String') ,' Averges: ',num2str(get(obj.control.ABR_averages,'Value')) ) ;
            obj.save_data(obj,transpose(ABR_data),'ABR_Data')
        end            
        function tuning_procedure(obj,TDT)
            global runmode
            %get tuning params
            freqs=strsplit(get(obj.control.Tuning_curve_freqs,'String'),':');
            dbs= strsplit(get(obj.control.Tuning_curve_levels,'String'),':');
            averages = get(obj.control.tuning_curve_averages,'Value');
            db_range = str2double(dbs{1}):str2double(dbs{2}):str2double(dbs{3});
            center_freq=str2double(freqs{1});
            octaves = str2double(freqs{2});
            steps = str2double(freqs{3});
%             freq_range=[];
%             for ii=-octaves:1:octaves-1
%                 step1=2^-ii;
%                 step2=2^(-ii -1);
%                 freq_range_holder = round(center_freq/step1):round(center_freq/(step2) - center_freq/(step1))/steps:round(center_freq/step2);
%                 if(ii==-octaves)
%                     freq_range=[freq_range freq_range_holder(1:end)];
%                 else
%                     freq_range=[freq_range freq_range_holder(2:end)];
%                 end
%             end

%CODE FROM MICHAEL MUNIAK:START
            step_size=1/steps;
            num_steps=octaves/step_size;
            if mod(num_steps,1) ~= 0 % check if step-interval divides cleanly into octave-interval.  Example: 1/8-oct steps up to ±1-oct vs. 1/8-oct steps up to ±1.1-oct
                %re-adjust octave range as needed (up or down) (e.g., 1-oct) or at the first step above the limit (e.g., 1.125-oct).
                num_steps=floor(num_steps); %stop below, use "floor(x)"
                %num_steps=ceil(num_steps) %stop above, use "ceil(x)"
                octaves=num_steps * step_size;
                fprintf('warning: uneven step range, adjusted to ±%g octaves!\n', octaves);
            end
            % in log2 space, octaves are now linear (e.g., +/- 1 == 1 octave)
            center_freq_log = log2(center_freq);  % convert center freq to log2 space
            % get freq range
            freq_range_log = linspace(center_freq_log-octaves, ...  % lowest-freq
                                      center_freq_log+octaves, ...  % highest-freq
                                      num_steps*2 + 1);  % number of steps in each direction + center_freq
            freq_range = 2.^freq_range_log;  % convert back to linear/freq space
%CODE HELP FROM MICHAEL MUNIAK:END

             %check for inputs shuffle 
             shuffle_mode = get(obj.control.shuffle_tuning_curve,'value');
             if shuffle_mode
                 freq_range_orig = freq_range;
                 db_range_orig = db_range;
                 freq_range = freq_range(randperm(length(freq_range)));
                 db_range = db_range(randperm(length(db_range)));
             end    
             

            %check for laser alternate mode 
             laser_alt = get(obj.control.laser_alternate,'value');
             
             if laser_alt
                 
                 dt = 1/(TDT.FS);
                 laser_delay_samples = round((get(obj.control.Laser_Delay,'Value')/1000)/dt);
                laser_on_samples = round((get(obj.control.Laser_On_Time,'Value')/1000)/dt);
                
                %set to one sample for delay of '0' 
                if laser_delay_samples ==0
                    laser_delay_samples =1;
                end     
                laser_sig(laser_delay_samples:laser_delay_samples+laser_on_samples) =1;
                
                 tuning_data=cell(1,length(db_range)*length(freq_range)*2);
                 counter =1; 
                 set(obj.control.stim_type,'Value',1);
                 runmode=1;
                 for i =1:length(db_range)
                     set(obj.control.stim_level,'Value',db_range(i));
                     for j=1:length(freq_range)
                         if(runmode ==1 )
                             set(obj.control.tone_frequency,'Value',freq_range(j))
                             %laser off
                             tuning_data{counter}=obj.get_data(obj,TDT,averages,'accum',0.*laser_sig);
                             counter = counter+1; 
                             
                             %laser on 
                             TDT.write('laser', laser_sig, 0);
                             tuning_data{counter}=obj.get_data(obj,TDT,averages,'accum', laser_sig);
                             counter = counter+1; 
                         else
                             break
                         end
                         pause(0.0001)
                     end
                 end
                 averages = averages*2; 
                 
                obj.data.info = strcat('freqs: ' , get(obj.control.Tuning_curve_freqs,'String') , ' levels: ' ,...
                    get(obj.control.Tuning_curve_levels,'String') ,' Averges: ',...
                    num2str(averages),' LaserAlternate:Yes' ) ;
                
             else
                 
                 tuning_data=cell(1,length(db_range)*length(freq_range));
                 counter =1; 
                 set(obj.control.stim_type,'Value',1);
                 runmode=1;
                 for i =1:length(db_range)
                     set(obj.control.stim_level,'Value',db_range(i));
                     for j=1:length(freq_range)
                         if(runmode ==1 )
                             set(obj.control.tone_frequency,'Value',freq_range(j))
                             tuning_data{counter}=obj.get_data(obj,TDT,averages,'accum');
                             counter = counter+1; 
                         else
                             break
                         end
                         pause(0.0001)
                     end
                 end
                 
                 obj.data.info = strcat('freqs: ' , get(obj.control.Tuning_curve_freqs,'String') , ' levels: ' ,...
                get(obj.control.Tuning_curve_levels,'String') ,' Averges: ',...
                num2str(get(obj.control.tuning_curve_averages,'Value')), ' LaserAlternate:No' ) ;
                 
             end     
             
             %put data back in original order 
             if shuffle_mode
                 if laser_alt
                     tune_data_orig = cell(1,length(db_range)*length(freq_range)*2);
                     counter =1; 
                     for i  =1:length(db_range)
                         for j=1:length(freq_range)
                             %get counter position
                             ind_db = find(ismember(db_range_orig,db_range(i)));
                             ind_freq = find(ismember(freq_range_orig,freq_range(j)));
                             counter_pos = length(freq_range)*(ind_db-1)+ind_freq;
                             %need to account for the double counting due
                             %to laser etc 
                             counter_pos = 2*(counter_pos)-1; 
                             tune_data_orig{counter_pos} = tuning_data{counter}; 
                             counter = counter+1;
                             tune_data_orig{counter_pos+1} = tuning_data{counter}; 
                             counter = counter+1;
                             
                         end
                     end
                 else
                     tune_data_orig = cell(1,length(db_range)*length(freq_range));
                     counter =1; 
                     for i  =1:length(db_range)
                         for j=1:length(freq_range)
                             %get counter position
                             ind_db = find(ismember(db_range_orig,db_range(i)));
                             ind_freq = find(ismember(freq_range_orig,freq_range(j)));
                             counter_pos = length(freq_range)*(ind_db-1)+ind_freq;
                             tune_data_orig{counter_pos} = tuning_data{counter}; 
                             counter = counter+1; 
                         end
                     end
                 end
                 tuning_data = tune_data_orig; 
             end     
             
             
             %unpack from cell
             tuning_data = cell2mat(tuning_data');
             
             %add acq length and stim active length 
             acq_length_ms = get(obj.control.stimulus_length,'Value')/1000;
             stim_active_length_ms = get(obj.control.stimulus_active,'Value')/1000;
             obj.data.info = strcat(obj.data.info, ' AcqLength_ms: ' ,num2str(acq_length_ms) ,...
                 ' ActiveLength_ms: ', num2str(stim_active_length_ms));
             
            obj.save_data(obj,(tuning_data),'tuning_data')  
        end
        function ITD_ILD_procedure(obj,TDT) 
            global runmode
            runmode =1 ;
            averages= get(obj.control.ITD_ILD_averages,'Value'); 
            threshold= str2double(get(obj.control.rasteredit,'String'));
            obj.control.ITDs_ILDs=figure('position',[50 75 500 850],...
                'name','ITD_ILD');
            obj.control.ITD_ILD_ax= axes('Parent', obj.control.ITDs_ILDs,'Position',[0.1, 0.1, 0.8, 0.8]);
            if(get(obj.control.ITD_on,'Value')==1)
                params= strsplit(get(obj.control.ITD_range,'String'),':');
                ITD_range= -str2double(params{1}):str2double(params{2}):str2double(params{3});
                spikes=zeros(1,length(ITD_range));
                ITD_traces = zeros(length(ITD_range)*averages,round(get(obj.control.acquire_length,'Value')/(1000*obj.data.dt)));
                for i=1:length(ITD_range)
                    if(runmode ==1)
                        set(obj.control.ITD,'Value',ITD_range(i)/1000)
                        [traces, ~]=obj.get_data(obj,TDT,averages,'accum'); 
                        ITD_traces((i-1)*averages +1:i*averages,:)=traces;
                        holder = traces; 
                        holder(holder <threshold)=NaN;
                        spikes(i)= length(findpeaks(holder(:)))/averages;
                        plot(obj.control.ITD_ILD_ax,ITD_range,spikes)
                        title(obj.control.ITD_ILD_ax,'ITD curve')
                        ylabel(obj.control.ITD_ILD_ax,'Averaged threshold crossings')
                        xlabel(obj.control.ITD_ILD_ax,'ITD interval (uS)')
                        pause(0.000001)
                    else
                        break
                    end  
                end
                obj.data.info = strcat('ITD parameters: ', get(obj.control.ITD_range,'String'),' Averges: ',num2str(averages));
                obj.save_data(obj,(ITD_traces),'ITD_traces') 
            elseif(get(obj.control.ILD_on,'Value')==1)
                params= strsplit(get(obj.control.ILD_range,'String'),':');
                ILD_range= str2double(params{1}):str2double(params{2}):str2double(params{3});
                spikes=zeros(1,length(ILD_range));
                ILD_traces = zeros(length(ILD_range)*averages,round(get(obj.control.acquire_length,'Value')/(1000*obj.data.dt)));
                for i = 1:length(ILD_range)
                    TDT.write('AttenA',0);
                    TDT.write('AttenB',0);
                    set(obj.control.ILD,'value',(ILD_range(i)));
                    if(runmode ==1)
                        [traces, ~]=obj.get_data(obj,TDT,averages,'accum');                       
                        ILD_traces((i-1)*averages +1:i*averages,:)=traces;
                        holder = traces; 
                        holder(holder<threshold)=NaN;
                        spikes(i)= length(findpeaks(holder(:)))/averages;
                        plot(obj.control.ITD_ILD_ax,ILD_range,spikes)
                        title(obj.control.ITD_ILD_ax,'ILD curve')
                        ylabel(obj.control.ITD_ILD_ax,'Averaged threshold crossings')
                        xlabel(obj.control.ITD_ILD_ax,'ILD interval dB')
                        pause(0.000001)
                    else
                        break
                    end  
                end
                TDT.write('AttenA',0);
                TDT.write('AttenB',0);
                obj.data.info = strcat('ILD parameters: ', get(obj.control.ILD_range,'String'),' Averges: ',num2str(averages));
                obj.save_data(obj,(ILD_traces),'ILD_traces') 
            end    
        end    
        function [input_signalA,input_signalB,samples,gain,acq_samples,time] = setup_input(obj,TDT)
            dt = 1/(TDT.FS);
            stim_length=((get(obj.control.stimulus_length,'Value')/1000));
            samples=round(stim_length/(dt));
            warning('off','MATLAB:colon:nonIntegerIndex')
            input_signalA = zeros(1,samples);
            input_signalB = zeros(1,samples);
            laser_sig = zeros(1,samples);
            
            delayA=round(0.001/dt) - 0.5*round((get(obj.control.ITD,'Value')/1000)/dt);
            delayB=round(0.001/dt) + 0.5*round((get(obj.control.ITD,'Value')/1000)/dt);
            stim_on_samples = round(((get(obj.control.stimulus_active,'Value')/1000))/dt);
            
            try
                levels = load(get(obj.control.calibration,'String'),'Levels');
                levels = levels.Levels ;
            catch
                disp('Not able to load Calibration file, running with non calibrated values')
                levels = 0.3.*ones(100,20000);
            end   
            
            menuval= get(obj.control.stim_type,'Value');
            db= get(obj.control.stim_level,'Value');
            freq= get(obj.control.tone_frequency,'Value');           
            max_voltage = get(obj.control.max_voltage,'Value');    
            if(menuval==1) %tone 
                voltage =levels(round(db),round(freq));
                if(abs(voltage)>=max_voltage ) %hard max voltage to protect hardware
                    voltage =max_voltage;
                end
                set(obj.control.stim_voltage,'Value',voltage);
                input_signalA(delayA:delayA+stim_on_samples)=voltage.*sin(get(obj.control.tone_frequency,'Value')*2*pi*(dt)*(delayA:delayA+stim_on_samples));
                input_signalB(delayB:delayB+stim_on_samples)=voltage.*sin((get(obj.control.tone_frequency,'Value')...
                    +get(obj.control.freq_shift,'Value'))*2*pi*(dt)*(delayB:delayB+stim_on_samples));
            elseif(menuval==2)  %click 
                voltage =levels(round(db),1);
                if(abs(voltage)>=max_voltage ) %hard max voltage to protect hardware
                    voltage =max_voltage;
                end
                set(obj.control.stim_voltage,'Value',voltage);
                input_signalA(delayA:delayA+1)=voltage;
                input_signalB(delayB:delayB+1)=voltage;
            elseif(menuval==3) %white Noise 
                voltage =levels(round(db),2);
                if(abs(voltage)>=max_voltage ) %hard max voltage to protect hardware
                    voltage =max_voltage;
                end
                set(obj.control.stim_voltage,'Value',voltage);
                rando= (rand(1,stim_on_samples+1)-0.5);
                input_signalA(delayA:delayA+stim_on_samples)=(voltage*2).*rando;
                input_signalB(delayB:delayB+stim_on_samples)=(voltage*2).*rando;   
            end     
            
            if(menuval==1 || menuval==3)%make rise fall ramp
            rise_fall_samps =round(get(obj.control.rise_fall,'Value')/(1000*dt));
            input_signalA(delayA:delayA+rise_fall_samps)= input_signalA(delayA:delayA+rise_fall_samps).*(0:1/(length(input_signalA(1:rise_fall_samps))):1);
            input_signalA(delayA+stim_on_samples-rise_fall_samps:delayA+stim_on_samples)= input_signalA(round(delayA+stim_on_samples-rise_fall_samps):round(delayA+stim_on_samples))...
                .*(1:-1/(length(input_signalA(1:rise_fall_samps))):0);
            
            input_signalB(delayB:delayB+rise_fall_samps)= input_signalB(delayB:delayB+rise_fall_samps).*(0:1/(length(input_signalB(1:rise_fall_samps))):1);
            input_signalB(delayB+stim_on_samples-rise_fall_samps:delayB+stim_on_samples)= input_signalB(delayB+stim_on_samples-rise_fall_samps:delayB+stim_on_samples)...
                .*(1:-1/(length(input_signalB(1:rise_fall_samps))):0);
            end 
            acq_samples = round((get(obj.control.acquire_length,'Value')/1000)/dt);
            time = (1:acq_samples).*dt; 
            plot(obj.control.ax2,time,input_signalA(1:acq_samples),'m',time,input_signalB(1:acq_samples),'r');
            legend(obj.control.ax2,'Input Signal A','Input Signal B')
            xlabel(obj.control.ax2,'Time in S');
            ylabel(obj.control.ax2,'Voltage'); 
            
            if(get(obj.control.ylims2, 'Value')==1)
                lims = regexp(get(obj.control.ylims2edit,'String'),':','split');
                ylim(obj.control.ax2, [str2double(lims{1}) str2double(lims{2})]) ;
            end 
            %write values to rcx circuit 
            TDT.write('outHPF', get(obj.control.hpf_out,'Value')); 
            TDT.write('outLPF', get(obj.control.lpf_out,'Value')); 
            TDT.write('inHPF', get(obj.control.hpf_in,'Value')); 
            TDT.write('inLPF', get(obj.control.lpf_in,'Value')); 
            
            %write laser settings to rcx 
            if get(obj.control.laser_on,'value')
                laser_delay_samples = round((get(obj.control.Laser_Delay,'Value')/1000)/dt);
                laser_on_samples = round((get(obj.control.Laser_On_Time,'Value')/1000)/dt);
                %set to one sample for delay of '0' 
                if laser_delay_samples ==0
                    laser_delay_samples =1;
                end     
                laser_sig(laser_delay_samples:laser_delay_samples+laser_on_samples) =1;
            end    
            TDT.write('laser', laser_sig, 0);
            
            attenuation = get(obj.control.ILD,'Value');
            if attenuation < 0 
                TDT.write('AttenB', abs(attenuation)); 
            else
                TDT.write('AttenA', abs(attenuation)); 
            end     
            
            %get in/out channels here
            in_val= get(obj.control.channel_in,'Value');
            out_val= get(obj.control.channel_out,'Value');
            
            gain_units = get(obj.control.amp_gain_units,'value');
            if gain_units ==1 %in db
                amp_gain = (10^((get(obj.control.amp_gain,'Value'))/20));
            else
                amp_gain = get(obj.control.amp_gain,'Value');
            end
            
            if(in_val==1)
                TDT.write('in_chan', 1);
                gain = amp_gain*(get(obj.control.mic_response,'Value')*10^-3); %assume A is Mic
            elseif(in_val==2)
                TDT.write('in_chan', 2);
                gain = amp_gain;
            elseif(in_val==3)
                TDT.write('in_chan', 3);
                gain = amp_gain;
                %adjust gain?
            end
            TDT.write('raster_thresh', str2double(get(obj.control.rasteredit,'String')).*gain);
            if(out_val==1)
                TDT.write('outA_switch', 1);
                TDT.write('outB_switch', 0);
            elseif(out_val==2)
                TDT.write('outA_switch', 0);
                TDT.write('outB_switch', 1);
            elseif(out_val==3)
                TDT.write('outA_switch', 1);
                TDT.write('outB_switch', 1);
            end
        end            
        function [traces,time]= get_data(obj,TDT,acqs,mode, laser_sig)
            %check for laser alternate mode   
            if nargin <5
                laser_sig = [];
            end     
            
            
            global runmode update
            update=1;
            [input_signalA,input_signalB,samples,gain,acq_samples,time] = obj.setup_input(obj,TDT);
            if(strcmp(mode,'accum')==1)
                traces=zeros(acqs,acq_samples);
            else 
                traces = 0;
            end  
            rast_plots =30;
            raster = zeros(rast_plots,acq_samples);
            rast_trial =1; 
            for i =1:acqs
                pause(0.001) %to catch the runmode change
                if(runmode ==1)
                    if(update==1)
                        [input_signalA,input_signalB,samples,gain,acq_samples,time] = obj.setup_input(obj,TDT);
                        update=0;
                    end 
                    if ~isempty(laser_sig)
                        TDT.write('laser', laser_sig, 0);
                    end  
                    
                    if(get(obj.control.sig_rand,'Value')==1)
                        xx = rand; 
                        if(xx >= 0.5)
                            TDT.write('outB', input_signalB.*0, 0);
                            TDT.write('outA', input_signalA.*0, 0);
                        else     
                            TDT.write('outB', input_signalB, 0);
                            TDT.write('outA', input_signalA, 0); 
                        end   
                    else    
                        TDT.write('outB', input_signalB, 0);
                        TDT.write('outA', input_signalA, 0); 
                    end     
                    
                    TDT.trg(1);
                    while(TDT.read('in_i')<= acq_samples);
                    end
                    acquired_signal = (TDT.read('in', 'OFFSET', 66, 'SIZE', acq_samples))./gain; %RZ6 has a sample delay of 66 samples
                    if(get(obj.control.raster, 'Value')==1)
                        if(runmode ==1)
                            rast_step = (obj.control.ax1.YLim(2)-obj.control.ax1.YLim(2)*0.2)/rast_plots;
                            raster(rast_trial,:) = logical(TDT.read('raster', 'OFFSET', 66, 'SIZE', acq_samples))*(0.2*obj.control.ax1.YLim(2)+(rast_step*rast_trial));
                            raster(raster == 0) = NaN;
                            plot(obj.control.ax1,time,acquired_signal, time,raster,'.','markersize',7,'MarkerFaceColor','k','MarkerEdgeColor','k');
                            rast_trial = rast_trial +1;
                            if(rast_trial >= rast_plots)
                                raster=raster.*0;
                                rast_trial=1;
                            end
                        elseif(runmode==0)
                            disp('Stopped')
                            break
                        end
                    else
                        plot(obj.control.ax1,time,acquired_signal);
                    end
                    if(get(obj.control.ylims1, 'Value')==1)
                        lims = regexp(get(obj.control.ylims1edit,'String'),':','split');
                        ylim(obj.control.ax1, [str2double(lims{1}) str2double(lims{2})]);
                    end
                    if(get(obj.control.raster, 'Value')==1)
                        drawnow
                    end     
                    if(strcmp(mode,'accum')==1)
                         traces(i,:) = acquired_signal;
                    end
                elseif(runmode==2)
                    count = 0;
                    while(runmode==2)
                        pause(0.5)
                        count = count + 0.5 ;
                        if(mod(count,1)==0)
                            set(obj.control.pausebtn,'backg','y')
                        else
                            set(obj.control.pausebtn,'backg','c')
                        end
                    end
                elseif(runmode==0)
                    disp('Stopped')
                    TDT.halt;
                    break
                else
                    error('runmode error')
                end
                if(get(obj.control.raster, 'Value')~=1)
                    xlabel(obj.control.ax1,'Time in S');
                    ylabel(obj.control.ax1,'Voltage');
                    title(obj.control.ax1,'Acquired Signal');
                end 
            end         
        end       
        function save_data(obj,data,mode)
                save_data = struct('traces',data,'fs',1/(obj.data.dt),'info',obj.data.info);
                c = clock;
                if((get(obj.control.data_saving,'Value'))==1 && (get(obj.control.search_mode,'Value'))==0)
                    fold_hold= get(obj.control.data_savingedit,'string');
                    full_path = strcat(fold_hold, '\',mode, datestr(date),'_',num2str(c(4)),num2str(c(5)),num2str(round(c(6))), '.mat');
                    save(full_path, 'save_data')
                elseif((get(obj.control.data_saving,'Value'))==0 && (get(obj.control.search_mode,'Value'))==0)
                    folder = strcat(pwd,'\' ,obj.control.current_user,'\', mode ,datestr(date),'_',num2str(c(4)),num2str(c(5)),num2str(round(c(6))) ,'.mat');
                    [file,path] = uiputfile('*.mat','Save data As',folder);
                    save((strcat(path,file)),'save_data')
                else    
                    assignin('base',mode,save_data);
                end       
        end     
        
    end
end    
