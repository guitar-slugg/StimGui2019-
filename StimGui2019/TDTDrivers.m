%desigend to wrap and handle a running open ex circuit 
% communicates with the open ex software via Active-X

classdef TDTDrivers < handle 
    
    properties
        tdt
        fs
        dt
    end 
    
    methods
        
        %setup and init 
        function obj = TDTDrivers(filepath)
            
            if nargin <1 
                error('please pass filepath to open ex circuit')
            end     

            % check if file exists
            if ~(exist(filepath, 'file'))
                error('%s cannot be found ',filepath)
            end
            
            
            %First instantiate a variable for the ActiveX wrapper interface
            obj.tdt = actxserver('RPco.X');
            
            INTERFACE = 'GB';
            DEVICETYPE = 'RZ6';
            
            % connect to device
            eval(['obj.tdt.Connect' DEVICETYPE '(''' INTERFACE ''', ' num2str(1) ');']);

            % stop any processing chains running on device
            obj.halt; 

            % clears all the buffers and circuits on the device
            obj.tdt.ClearCOF;
            obj.tdt.LoadCOF(filepath);
            
            %get sample freq 
            obj.fs = obj.tdt.GetSFreq;
            obj.dt = 1/obj.fs;
            
            % start circuit
            obj.run;
            
            
        end    
        
        function run(obj)
            % start circuit
            obj.tdt.Run;
        end 
        
        
        function halt(obj)
            % stop any processing chains running on device
            obj.tdt.Halt; 
        end 
        

        function setTag(obj, tag, value)
            %write a software tag 
            obj.tdt.SetTagVal(tag, value);  
        end 
        
        function data = readBuffer(obj, tag, OFFSET, SIZE)
            
            SOURCE = 'F32';
            DEST = 'F32';
            NCHAN = 1;
            data = obj.tdt.ReadTagVEX(tag, OFFSET, SIZE, SOURCE, DEST, NCHAN);

        end     
        
        
        function num = readCounter(obj,tag)
            
            SOURCE = 'F32';
            DEST = 'F32';
            OFFSET = 0;
            NCHAN = 1;
            SIZE = 1;
            
            num = obj.tdt.ReadTagVEX(tag, OFFSET, SIZE, SOURCE, DEST, NCHAN);
            
        end     

        function trigger(obj, num)
            obj.tdt.SoftTrg(num);
        end     
  
         function samples = ms2Samples(obj,time_ms)
            samples = round((time_ms/1000)/obj.dt);
         end  
        
    end    
    
   
    
end     