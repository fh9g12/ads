classdef Sol145 < handle
    %FLUTTERSIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % generic aero parameters
        Name = 'SOL145';
        LoadFactor = 1;
        DoFs = [];
        V = 0;
        rho = 0;
        Mach = 0;
        AEQR = 1;
        ACSID = [];

        RefChord = 1;
        RefSpan = 1;
        RefArea = 1;
        RefDensity = 1.225;
        LModes = 0;

        % freqeuency & Structural Damping Info
        FreqRange = [0.01,50];
        NFreq = 500;
        ModalDampingPercentage = 0;

        FlutterMethod = 'PK';
        FlutterID = 4;
        Flfact_mach_id = 2;
        Flfact_v_id = 3;
        Flfact_rho_id = 1;
        EigR_ID = 5;
        SPC_ID = 6;
        SPCs = [];
        ReducedFreqs = [0.01,0.05,0.1,0.2,0.5,0.75,1,2,4];

        %CoM and constraint Paramters
        CoM_gp = 1;
        CoM_GID = 99999999;
        CoM_Cp = [];
        CoM = [0;0;0];
    end
    
    methods
        function ids = UpdateID(obj,ids)
                obj.FlutterID = ids.SID;
                obj.Flfact_mach_id = ids.SID+1;
                obj.Flfact_v_id = ids.SID+2;
                obj.Flfact_rho_id = ids.SID+3;
                obj.EigR_ID = ids.SID + 4;
                obj.SPC_ID = ids.SID + 5;
                ids.SID = ids.SID + 6;
        end
        function str = config_string(obj)
            str = '';
        end
        function set_trim_steadyLevel(obj,V,rho,Mach)
            obj.V = V;
            obj.rho = rho;
            obj.Mach = Mach;
            obj.ANGLEA.Value = NaN;
            obj.URDD3.Value = 0;
            obj.DoFs = 35;
        end
        function set_trim_locked(obj,V,rho,Mach)
            obj.V = V;
            obj.rho = rho;
            obj.Mach = Mach;
            obj.ANGLEA.Value = 0;
            obj.DoFs = [];
        end
    end
end
