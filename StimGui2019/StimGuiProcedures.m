



classdef StimGuiProcedures
    
    properties (Constant)
        acqOffset = 66+30; %% 66 sample acquire delay
    end     
    
    methods (Static)

        function searchMode(TDT,SETTINGS, n_acqs, ax1, ax2)
            
           StimGuiProcedures.writeSettings(TDT, SETTINGS);
           
           acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
           
           TDT.setTag('amplitude', SETTINGS.stim_voltage_V);  %volts
           TDT.setTag('amp_B', SETTINGS.stim_voltage_V_B);  %volts

           acq_offset = StimGuiProcedures.acqOffset;
           gain = StimGuiProcedures.computeGain(SETTINGS);
           
           global RUNNING 
           RUNNING=1; 
           
           global UPDATE
           UPDATE=0; 
           
           global sets 

           for ii=1:n_acqs
               
               if ~RUNNING
                   break
               end  
               
               if UPDATE
                   SETTINGS = sets; 
                   StimGuiProcedures.writeSettings(TDT, SETTINGS);
                   UPDATE = 0; 
                   sets =[];
               end     
                
                %start and wait
                TDT.trigger(1);
                switch SETTINGS.channel_in
                    case 1
                        while TDT.readCounter('in_i') <= acq_samples;
                        end
                        
                    case 2
                        while TDT.readCounter('in_i_B') <= acq_samples;
                        end
                        
                    case 3
                        while TDT.readCounter('in_i') <= acq_samples;
                        end
                        
                end
                
                %acquire
                switch SETTINGS.channel_in
                    case 1
                        acquired_signal = TDT.readBuffer('in', acq_offset, acq_samples)./gain;
                    case 2
                        acquired_signal = TDT.readBuffer('in_B', acq_offset, acq_samples)./gain;
                    case 3
                        acquired_signal(1,:) = TDT.readBuffer('in', acq_offset, acq_samples)./gain;
                        acquired_signal(2,:) = TDT.readBuffer('in_B', acq_offset, acq_samples)./gain;
                end
                
                switch SETTINGS.channel_out
                    case 1
                        input_signal = TDT.readBuffer('input_sigA', 0, acq_samples);
                    case 2
                        input_signal = TDT.readBuffer('input_sigB', 0, acq_samples);
                       
                    case 3
                        input_signal(1,:) = TDT.readBuffer('input_sigA', 0, acq_samples);
                        input_signal(2,:) = TDT.readBuffer('input_sigB', 0, acq_samples);
                end

                %display 
                if SETTINGS.display_output || SETTINGS.display_input
                    time_vector = (1:length(input_signal)).*TDT.dt; 
                end     
                
                if SETTINGS.display_output && SETTINGS.display_input
                    plot(ax1, time_vector, acquired_signal);
                    plot(ax2, time_vector, input_signal);
                elseif SETTINGS.display_output 
                    plot(ax1, time_vector, acquired_signal);
                elseif SETTINGS.display_input
                    plot(ax2, time_vector, input_signal);
                end     
                drawnow 

           end
            %off 
            TDT.setTag('amplitude', 0);  %volts
            
        end    
        
        
        function DATA = abrProcedure(TDT, SETTINGS, freqs, levels, averages,calibration, ax1, ax2)
            
            global RUNNING 
            RUNNING=1; 
            
            acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
            data=zeros(length(freqs), length(levels), averages,acq_samples );
            inputs = zeros(length(freqs), length(levels), averages,acq_samples );
            
            for ind_freq = 1:length(freqs)
                freq = freqs(ind_freq);
                switch freq
                    
                    case 0 %click 
                        SETTINGS.stim_type =3; 

                    case 1  %noise 
                        SETTINGS.stim_type =2; 
                        
                    otherwise  %tone 
                        
                        SETTINGS.stim_type =1; 
                        SETTINGS.tone_frequency_hz = freq; 
                        
                end         
                
                for ind_level = 1:length(levels)
                    
                    level = levels(ind_level);
                    
                    if freq==0
                        volts = calibration(round(level),round(1));
                    else
                        volts = calibration(round(level),round(freq));
                    end     
                    
                    SETTINGS.stim_voltage_V = volts;
                    
                    %write settings 
                    StimGuiProcedures.writeSettings(TDT, SETTINGS);
                    
                    for ind_avg = 1:averages
                        
                        if ~RUNNING
                            break
                        end     
                        
                        [dat, inSig] = StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                        data(ind_freq, ind_level,ind_avg, : ) = dat; 
                        inputs(ind_freq, ind_level,ind_avg, : ) = inSig; 
                        
                    end 
                    
                    if ~RUNNING
                            break
                    end  

                end
                
                if ~RUNNING
                     break
                end  
                
            end
            
            DATA.data = data;
            DATA.inputs = inputs;
            DATA.freqs = freqs;
            DATA.levels = levels;
            DATA.averages = averages;
   

        end    
        
        

        
        function DATA = tuningProcedure(TDT, SETTINGS, args, calibration, ax1, ax2)
            
            %unpack
            centerFreq = args.centerFreq;
            octaves = args.octaves;
            divisions = args.divisions;
            levels = args.levels;
            averges = args.averges;
            alternate_laser = args.alternate_laser;
            shuffle = args.shuffle;
            
            divisions=1/divisions;
            num_steps=octaves/divisions;
            if mod(num_steps,1) ~= 0 % check if step-interval divides cleanly into octave-interval.  Example: 1/8-oct steps up to �1-oct vs. 1/8-oct steps up to �1.1-oct
                %re-adjust octave range as needed (up or down) (e.g., 1-oct) or at the first step above the limit (e.g., 1.125-oct).
                num_steps=floor(num_steps); %stop below, use "floor(x)"
                %num_steps=ceil(num_steps) %stop above, use "ceil(x)"
                octaves=num_steps * divisions;
                fprintf('warning: uneven step range, adjusted to �%g octaves!\n', octaves);
            end
            
            % in log2 space, octaves are now linear (e.g., +/- 1 == 1 octave)
            center_freq_log = log2(centerFreq);  % convert center freq to log2 space
            % get freq range
            freq_range_log = linspace(center_freq_log-octaves, ...  % lowest-freq
                                      center_freq_log+octaves, ...  % highest-freq
                                      num_steps*2 + 1);  % number of steps in each direction + center_freq
            freq_range = 2.^freq_range_log;  % convert back to linear/freq space
            
            if shuffle
                 freq_range_orig = freq_range;
                 db_range_orig = levels;
                 freq_range = freq_range(randperm(length(freq_range)));
                 levels = levels(randperm(length(levels)));
            end   
             
            global RUNNING 
            RUNNING=1;
            
            acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
            data = zeros(length(freq_range),length(levels),averges,acq_samples );
            input = zeros(length(freq_range),length(levels),averges,acq_samples );
            doIt = true; 
            
            for ind_level = 1:length(levels)
                level = levels(ind_level);
                
                for ind_freq = 1:length(freq_range)
                    freq = freq_range(ind_freq);
                    SETTINGS.tone_frequency_hz = freq;
                    
                    %write settings
                    volts = calibration(round(level),round(freq));
                    SETTINGS.stim_voltage_V = volts;
                    
                    if alternate_laser && doIt 
                        SETTINGS.laser_on = true; 
                        doIt = false; 
                    else
                        SETTINGS.laser_on = false; 
                        doIt = true;
                    end     
                    
                    
                    for ind_avg = 1:averges
                        
                        
                        [dat, inSig] = StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                        
                        data(ind_freq, ind_level,ind_avg, : ) = dat;
                        input(ind_freq, ind_level,ind_avg, : )= inSig;
                        
                        if ~RUNNING
                            break
                        end
                        
                    end
                    
                    if ~RUNNING
                        break
                    end
                    
                end
                
                if ~RUNNING
                    break
                end
            end
            
            %need to un-shuffle 
            if shuffle
            
             
                
            end 
            
            DATA.data = data;
            DATA.input_signals = input;
            DATA.freq_range = freq_range; 
            DATA.levels = levels; 
            DATA.args = args;     
            
        end 
        
        
        function DATA = itdProc(TDT,SETTINGS, itdLevels, averages, ax1, ax2)
            
            global RUNNING
            RUNNING=1;
            
            acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
            data=zeros(length(itdLevels), averages,acq_samples );
            inputs = zeros(length(itdLevels), averages,acq_samples );
            
            for ind_itd=1:length(itdLevels);
                SETTINGS.ITD_ms = itdLevels(ind_itd);
                
                for ind_avg = 1:averages
                    
                    if ~RUNNING
                        break
                    end
                    
                    [dat, inSig] = StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                    data(ind_itd,ind_avg, : ) = dat;
                    inputs(ind_itd, ind_avg, : ) = inSig(1,:);
                    
                end
                
                if ~RUNNING
                   break
                end
   
            end

            DATA.data = data;
            DATA.inputs = inputs;
            DATA.itdLevels = itdLevels;
            DATA.averages = averages;


        end 
        
        function DATA = ildProc(TDT,SETTINGS, ildLevels, averages, calibration,dbCenter, freq , ax1, ax2)
        
            global RUNNING
            RUNNING=1;
            
            acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
            data=zeros(length(ildLevels), averages,acq_samples );
            inputs = zeros(length(ildLevels), averages,acq_samples*2 );
            
            for ind_ild=1:length(ildLevels);
                
                SETTINGS.ILD_dB = ildLevels(ind_ild);
                SETTINGS.stim_voltage_V = calibration(round(dbCenter),round(freq));
                
                %compute volt offset for ild
                if SETTINGS.ILD_dB >=0
                    SETTINGS.stim_voltage_V_B = calibration(round(dbCenter - SETTINGS.ILD_dB),round(freq));
                else
                    SETTINGS.stim_voltage_V_B = SETTINGS.stim_voltage_V;
                    SETTINGS.stim_voltage_V = calibration(round(dbCenter + SETTINGS.ILD_dB),round(freq));
                end

                for ind_avg = 1:averages
                    
                    if ~RUNNING
                        break
                    end
                    
                    [dat, inSig] = StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                    data(ind_ild,ind_avg, : ) = dat;
                    inputs(ind_ild, ind_avg, : ) = inSig(:);
                    
                end
                if ~RUNNING
                    break
                end
                
            end
            
            DATA.data = data;
            DATA.inputs = inputs;
            DATA.ildLevels = ildLevels;
            DATA.averages = averages;
            
            
        end 
        
        
        function DATA = monaurlProc(TDT,SETTINGS, averages, ax1, ax2)
            
            global RUNNING
            RUNNING=1;
            
            acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
            SETTINGS.stim_type = 2; 
            SETTINGS.channel_out=1; 
            
            contraData = zeros(averages, acq_samples);
            for ind_avg = 1:averages
                
                contraData(ind_avg,:)= StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                
                if ~RUNNING
                        break
                end
            end     
            
            
            SETTINGS.channel_out=1; 
            ipsiData = zeros(averages, acq_samples);
            for ind_avg = 1:averages
                
                ipsiData(ind_avg,:)= StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                
                if ~RUNNING
                        break
                end
            end    
            
            
            SETTINGS.channel_out=3; 
            bothData = zeros(averages, acq_samples);
            for ind_avg = 1:averages
                
                bothData(ind_avg,:)= StimGuiProcedures.getData(TDT,SETTINGS,1,ax1, ax2);
                
                if ~RUNNING
                        break
                end
            end    
            
            DATA.contraData= contraData;
            DATA.ipsiData = ipsiData;
            DATA.bothData =bothData; 

            
        end     
            


        function [data, input_signal ] = getData(TDT,SETTINGS, n_acqs, ax1, ax2, avgFlag)
            
            if nargin < 6
                avgFlag = false;
            end     
            
            StimGuiProcedures.writeSettings(TDT, SETTINGS);
            
            acq_samples=  TDT.ms2Samples(SETTINGS.acquire_length_ms);
            TDT.setTag('amplitude', SETTINGS.stim_voltage_V);  %volts
            TDT.setTag('amp_B', SETTINGS.stim_voltage_V_B);  %volts
            acq_offset = StimGuiProcedures.acqOffset;
            gain = StimGuiProcedures.computeGain(SETTINGS);
            
            
            switch SETTINGS.channel_in
                case 3
                    data = zeros(n_acqs,acq_samples*2);
                otherwise
                    data = zeros(n_acqs,acq_samples);
            end
            
            
            global RUNNING
            RUNNING=1;
           
           for ii=1:n_acqs
               
               if ~RUNNING 
                   break
               end     
                
                %start and wait
                 %start and wait
                TDT.trigger(1);
                switch SETTINGS.channel_in
                    case 1
                        while TDT.readCounter('in_i') <= acq_samples;
                        end
                        
                    case 2
                        while TDT.readCounter('in_i_B') <= acq_samples;
                        end
                        
                    case 3
                        while TDT.readCounter('in_i') <= acq_samples;
                        end
                        
                end
                
                
                %acquire
                switch SETTINGS.channel_in
                    case 1
                        acquired_signal = TDT.readBuffer('in', acq_offset, acq_samples)./gain;
                    case 2
                        acquired_signal = TDT.readBuffer('in_B', acq_offset, acq_samples)./gain;
                    case 3
                        acquired_signal(1,:) = TDT.readBuffer('in', acq_offset, acq_samples)./gain;
                        acquired_signal(2,:) = TDT.readBuffer('in_B', acq_offset, acq_samples)./gain;
                end
                
                switch SETTINGS.channel_out
                    case 1
                        input_signal = TDT.readBuffer('input_sigA', 0, acq_samples);
                    case 2
                        input_signal = TDT.readBuffer('input_sigB', 0, acq_samples);
                       
                    case 3
                        input_signal(1,:) = TDT.readBuffer('input_sigA', 0, acq_samples);
                        input_signal(2,:) = TDT.readBuffer('input_sigB', 0, acq_samples);
                end     
                
                if SETTINGS.display_output || SETTINGS.display_input
                    time_vector= (1:length(acquired_signal)).*TDT.dt; 
                end 
                
                
                %plot 
                if SETTINGS.display_output && SETTINGS.display_input
                    plot(ax1, time_vector, acquired_signal);
                    plot(ax2, time_vector, input_signal);
                elseif SETTINGS.display_output 
                    plot(ax1, time_vector, acquired_signal);
                elseif SETTINGS.display_input
                    plot(ax2, time_vector, input_signal);
                end     
                drawnow 
                
                
                switch SETTINGS.channel_in
                    case 3
                        data(ii,:) = [acquired_signal(1,:) acquired_signal(2,:) ]; 
                    otherwise
                        data(ii,:) = acquired_signal; 
                end         

           end
            %off 
            TDT.setTag('amplitude', 0);  %volts
            
            %average
            if avgFlag
                data = mean(data,1);
            end
            
            
            switch SETTINGS.channel_in
                case 3
                    plot(ax1, 1:length(acquired_signal)*2, data);
                otherwise
                    plot(ax1, time_vector, data);
            end
            
            
        end
        
        
        function splCheck(TDT, SETTINGS)
            
                info = inputdlg({'trials:','trial length (ms)','weighting (A or none)'}, 'Input', [1 30;1 30;1 30], {'10','1000','A'});
               
                averages = str2double(info{1});
                lenMS = str2double(info{2});
                A_wt = info{3};

                SETTINGS.stimulus_length_ms = lenMS;
                SETTINGS.acquire_length_ms = lenMS;
                SETTINGS.stimulus_start_ms = 0;
                SETTINGS.stimulus_stop_ms = 1;
                SETTINGS.display_output=false;
                SETTINGS.display_input=false;
                SETTINGS.stim_voltage_V=0; 
                dBs= zeros(averages,1);

                disp('running..')
                for i = 1:averages
                    traces(i,:) = StimGuiProcedures.getData(TDT,SETTINGS, 1, gca, gca);
                    
                    if(strcmp(A_wt,'A')==1)
                        traces(i,:) = filterA(traces(i,:), 1/TDT.dt);
                    end
                    dBs(i) = 20.*log10(sqrt(mean((traces(i,:)).^2))/(20e-6));
                end
                
                figure();
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
                
                
        end     
        
        

        function Levels = makeCalibration(TDT, SETTINGS, ax1, ax2)
            
            info = inputdlg({'low freq:','high freq:','freq interval','low dB:','high dB','dB interval'}, 'Settings', ...
                    [1 30;1 30;1 30;1 30;1 30;1 30], {'500','20000','250','10','90','5'});
                freq_array = str2double(info{1}):str2double(info{3}):str2double(info{2});
                db_array = str2double(info{4}):str2double(info{6}):str2double(info{5});
            
            
            Levels = zeros(100,20000);  % to return the voltage at db,freq
            max_voltage =2; 
            SETTINGS.stimulus_length_ms = 100;
            SETTINGS.acquire_length_ms = 100;
            SETTINGS.stimulus_start_ms = 0;
            SETTINGS.stimulus_stop_ms = 100;
            
            SETTINGS.stim_type =1; 
            global RUNNING
            RUNNING=1;
            
             %calibrate tones 
                for i= 1:length(freq_array)
                    SETTINGS.stim_voltage_V=0.1; 
                    disp(['FREQ: ' num2str(freq_array(i))])
                    
                    for j = 1:length(db_array)
                        
                        disp(['LEVEL: ' num2str(db_array(j))])
                        
                        sig = StimGuiProcedures.getData(TDT, SETTINGS,1, ax1, ax2);
                        db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6));  
                        
                        while(db_got <= db_array(j)*0.98 || db_got >= db_array(j)*1.02)
                            
                            if ~RUNNING
                                break
                            end
                            
                            if(db_got <= db_array(j))
                                SETTINGS.stim_voltage_V =SETTINGS.stim_voltage_V*1.11;
                                if(SETTINGS.stim_voltage_V>=max_voltage)
                                    SETTINGS.stim_voltage_V=max_voltage;
                                    break
                                end     
                            end 
                            if(db_got >= db_array(j))
                                SETTINGS.stim_voltage_V =SETTINGS.stim_voltage_V*0.92;
                            end 
                            if(SETTINGS.stim_voltage_V >= max_voltage)
                                break
                            end
                            if(SETTINGS.stim_voltage_V <= 1e-6)
                                break
                            end     

                            
                            sig = StimGuiProcedures.getData(TDT, SETTINGS,1, ax1, ax2);
                            db_got=20.*log10(sqrt(mean(sig.^2))/(20e-6)); 
   
                        end 
                        Levels(db_array(j),freq_array(i))=SETTINGS.stim_voltage_V;
                    end
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
                
                
            [file, folder] = uiputfile('.mat');
            save([folder filesep file], 'Levels');
             
            
        end     

        function gain = computeGain(SETTINGS)
            
            switch SETTINGS.gain_units
                case 'dB'
                    amp_gain = 10^((SETTINGS.amp_gain)/20);
                case 'linear'
                    amp_gain = SETTINGS.amp_gain;
                otherwise
                    error('unknown gain unit... options are: dB, linear')
            end 
            
            switch SETTINGS.channel_in
                case 1
                    gain = amp_gain*(SETTINGS.micResponse_mVperPa)*10^-3; %assume A is Mic
                case 2
                    gain = amp_gain; 
                case 3
                    gain = amp_gain;    
            end         

        end     

        function writeSettings(TDT, SETTINGS)
            
            wave_start = TDT.ms2Samples(SETTINGS.stimulus_start_ms);  
            wave_end = TDT.ms2Samples(SETTINGS.stimulus_stop_ms);
            
            %account for rise fall 
            wave_end = wave_end - TDT.ms2Samples(SETTINGS.rise_fall_ms);

            TDT.setTag('wave_start', wave_start);  
            TDT.setTag('wave_end', wave_end);  
            
            TDT.setTag('freq', SETTINGS.tone_frequency_hz);  %volts
            TDT.setTag('rise_fall',SETTINGS.rise_fall_ms);  %rise fall 

             TDT.setTag('inLFP', SETTINGS.lpf_in_hz);  %Hz
             TDT.setTag('inHPF', SETTINGS.hpf_in_hz);  %Hz
            
             TDT.setTag('outLFP', SETTINGS.lpf_out_hz);  %Hz
             TDT.setTag('outHPF', SETTINGS.hpf_out_hz);  %Hz
             
             TDT.setTag('dF', SETTINGS.freq_shift_hz);
             
             
             %0.1 ms built in delay...
             if SETTINGS.ITD_ms > 0 
                 TDT.setTag('delay_sig_B', SETTINGS.ITD_ms +0.1); 
                 TDT.setTag('delay_sig_A', 0.1); 
             elseif SETTINGS.ITD_ms < 0
                 TDT.setTag('delay_sig_A', abs(SETTINGS.ITD_ms) +0.1); 
                 TDT.setTag('delay_sig_B', 0.1); 
             else
                 TDT.setTag('delay_sig_A', 0.1); 
                 TDT.setTag('delay_sig_B', 0.1); 
             end 
               
             %modulation 
             if SETTINGS.am_modulation || SETTINGS.fm_modulation
                 if SETTINGS.modulation_depth <=1 && SETTINGS.modulation_depth >=0
                     TDT.setTag('modulation_amp', SETTINGS.modulation_depth); 
                     TDT.setTag('modulation_freq', SETTINGS.am_modulation_freq_hz); 
                 else
                     error('MODULATION depth should be between 0 and 1')
                 end     
             else
                 TDT.setTag('modulation_amp', 0); 
             end     

             
             switch SETTINGS.channel_out
                 %channel A
                 case 1 
                     TDT.setTag('input_sigA_on', 1);  
                     TDT.setTag('input_sigB_on', 0);  
                 %channel B    
                 case 2 
                     TDT.setTag('input_sigA_on', 0);  
                     TDT.setTag('input_sigB_on', 1);  
                 %both    
                 case 3
                     TDT.setTag('input_sigA_on', 1);  
                     TDT.setTag('input_sigB_on', 1);  
                 otherwise
                     error('wtf error')
             end     
             
             switch SETTINGS.stim_type
                 case 1
                     %tone
                     TDT.setTag('tone_on', 1);  
                     TDT.setTag('noise_on', 0);  
                     TDT.setTag('pulse_on', 0);  
                 case 2
                     %noise
                     TDT.setTag('tone_on', 0); 
                     TDT.setTag('noise_on', 1);  
                     TDT.setTag('pulse_on', 0);  
                 case 3
                     %click
                     TDT.setTag('tone_on', 0);  
                     TDT.setTag('noise_on', 0);  
                     TDT.setTag('pulse_on', 1);  
                     TDT.setTag('rise_fall', 0.0001);%don't devide by zer0
                     TDT.setTag('wave_start', TDT.ms2Samples(SETTINGS.stimulus_start_ms));  
                     TDT.setTag('wave_end', TDT.ms2Samples(SETTINGS.stimulus_start_ms) + 4 );  

                 otherwise
                     
                     error('wtf error')
                     
             end  
             
             switch SETTINGS.laser_on
                 
                 case 1
                     TDT.setTag('laser_on', 1);  
                     TDT.setTag('laser_start', TDT.ms2Samples(SETTINGS.laser_delay_ms));  
                     TDT.setTag('laser_end', TDT.ms2Samples(SETTINGS.laser_delay_ms) + TDT.ms2Samples(SETTINGS.laser_on_time_ms)); 
                 case 0 
                      TDT.setTag('laser_on', 0);   
                     
             end             
             
        end     

    end     
    
 
    
end     