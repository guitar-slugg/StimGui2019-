classdef StimGuiUserSettings < handle

    properties
            hpf_in_hz
            lpf_in_hz 
            notch_in_hz
            hpf_out_hz
            lpf_out_hz
            stimulus_length_ms
            acquire_length_ms 
            
            stimulus_start_ms
            stimulus_stop_ms
            rise_fall_ms 
            ITD_ms 
            ILD_dB 
            freq_shift_hz 
            stim_voltage_V
            stim_level_dB 
            tone_frequency_hz 
            stim_type
            
            am_modulation 
            am_modulation_freq_hz 
            fm_modulation
            fm_modulation_freq_hz
            modulation_depth 
            
            raster
            raster_V 
            auto_scale
            ylims1
            ylims2
            display_output
            display_input
            

            channel_in
            channel_out
            amp_gain
            gain_units
            micResponse_mVperPa
            max_voltage_V  
            laser_on 
            laser_on_time_ms  
            laser_delay_ms 

            save_tag
            root_dir
            auto_save
            stim_voltage_V_B
    end
    
    methods
        %constructor , default settings 
        function obj = StimGuiUserSettings 

            obj.hpf_in_hz = 300; %hz
            obj.lpf_in_hz = 3000; %hz
            obj.notch_in_hz = 60; %hz
            obj.hpf_out_hz = 20;%hz
            obj.lpf_out_hz = 20000;%hz
            obj.stimulus_length_ms= 45 ; %ms
            obj.acquire_length_ms = 15; %ms
            
            obj.stimulus_start_ms= 0; %ms
            obj.stimulus_stop_ms= 5; %ms
            obj.rise_fall_ms = 0.5;%ms
            obj.ITD_ms = 0;%ms
            obj.ILD_dB = 0;%db
            obj.freq_shift_hz = 0;%hz
            obj.stim_voltage_V = 0.5;%v
            obj.stim_level_dB = 70;%db
            obj.tone_frequency_hz = 1000;%hz
            obj.am_modulation = false;
            obj.am_modulation_freq_hz = 100; 
            obj.fm_modulation =false; 
            obj.fm_modulation_freq_hz = 100;
            obj.modulation_depth =1;
            
            obj.stim_type =1; 
            
            obj.raster = false; 
            obj.raster_V = 0.005;%v
            obj.auto_scale = true; 
            obj.ylims1= '-1:1';
            obj.ylims2='-1:1';
            obj.display_output = true;
            obj.display_input = true;
            
            obj.channel_in=1;
            obj.channel_out=1;
            obj.amp_gain =40;
            obj.gain_units ='dB';
            obj.micResponse_mVperPa = 4;
            obj.max_voltage_V = 2; 
            obj.laser_on = false; 
            obj.laser_on_time_ms = 50; 
            obj.laser_delay_ms =0; 
            
            obj.root_dir=pwd;
            obj.save_tag =[];
            obj.auto_save =true; 
            obj.stim_voltage_V_B =0 ;
        end     


    end
    
    
end

