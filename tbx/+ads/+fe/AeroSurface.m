classdef AeroSurface < ads.fe.Element
    %MASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CoordSys (1,1) ads.fe.AbsCoordSys = ads.fe.BaseCoordSys.get;
        AeroCoordSys (1,1) ads.fe.AbsCoordSys = ads.fe.BaseCoordSys.get;
        Points (3,2) double
        ChordwisePos (2,1) double = [nan nan];
        Chords (2,1) double = [nan nan];
        Twists (2,1) double = [0 0];
        nSpan (1,1) double = 10;
        nChord (1,1) double = 4;
        StructuralPoints (:,1) ads.fe.Point;
        DisplacementPoints (:,1) ads.fe.Point;
        ID double = nan;
        PID (1,1) double = nan;
        SID (3,1) double = [nan,nan,nan];
        SplineType = 4;
    end
    
    methods
        function obj = AeroSurface(Points,ChordwisePos,Chords,opts)
            arguments
                Points (3,2) double
                ChordwisePos (2,1) double
                Chords (2,1) double
                opts.CoordSys (1,1) ads.fe.AbsCoordSys = ads.fe.BaseCoordSys.get;
                opts.Twists (2,1) double = [0,0];
                opts.nSpan (1,1) double = 10;
                opts.nChord (1,1) double = 4;
                opts.StructuralPoints (:,1) ads.fe.Point = ads.fe.Point.empty;
                opts.DisplacementPoints (:,1) ads.fe.Point = ads.fe.Point.empty;
            end
            %MASS Construct an instance of this class
            %   Detailed explanation goes here
            obj.CoordSys = opts.CoordSys;
            obj.Points = Points;
            obj.ChordwisePos = ChordwisePos;
            obj.Chords = Chords;
            obj.Twists = opts.Twists;
            obj.nSpan = opts.nSpan;
            obj.nChord = opts.nChord;
            obj.StructuralPoints = opts.StructuralPoints;
            obj.DisplacementPoints = opts.DisplacementPoints;
        end
        function SetPanelNumbers(obj,N,AspectRatio,Dependent)
            arguments
                obj
                N (1,1) double
                AspectRatio (1,1) double
                Dependent string {mustBeMember(Dependent,{'Span','Chord'})}
            end
            for i = 1:length(obj)
            switch Dependent
                case 'Span'
                    obj(i).nChord = N;
                    span = abs(obj(i).Points(2,2)-obj(i).Points(2,1));
                    panelChord = obj(i).Chords(2)/N;
                    panelspan = panelChord*AspectRatio;
                    obj(i).nSpan = ceil(span/panelspan);
                case 'Chord'
                    obj(i).nSpan = N;
                    span = abs(obj(i).Points(2,2)-obj(i).Points(2,1));
                    panelSpan = span/N;
                    panelChord = panelSpan/AspectRatio;
                    obj(i).nChord = ceil(obj(i).Chord(2)/panelChord);
            end
            end
        end
        function ids = UpdateID(obj,ids)
            for i = 1:length(obj)
                obj(i).ID = ids.EID;
                % resurve EIDs for each panel and upto 2 Spline cards
                ids.EID = ids.EID + (obj(i).nSpan*obj(i).nChord) + 2;
                % for PAERO cards
                obj(i).PID = ids.PID;
                ids.PID = ids.PID + 1;
                % for AELIST and SET1 for spline + 1 extra incase two meshes used
                obj(i).SID = ids.SID:(ids.SID+2);
                ids.SID = ids.SID + 3;
            end
        end
        function plt_obj = draw(obj)
            if isempty(obj)
                plt_obj = [];
                return;
            end
            for i = 1:length(obj)
                Xs = obj(i).get_panel_coords();
                for j = 1:size(Xs,3)
                    Xs(:,:,j) = obj(i).CoordSys.getPointGlobal(Xs(:,:,j)')';
                end
                X = reshape(Xs(:,1,:),4,[]);
                Y = reshape(Xs(:,2,:),4,[]);
                Z = reshape(Xs(:,3,:),4,[]);
                c = repmat(201/255,size(X,2),3);
                c = reshape(c,size(X,2),1,3);
                plt_obj(i) = patch('XData', X,'YData', Y,'ZData', Z,...
                    'Tag', 'Aero Panels', 'CData', c,'FaceColor','flat');
            end
        end
        function Xs = get_panel_coords(obj)
            xDirGlobal = obj.AeroCoordSys.getAglobal()*[1;0;0];
            xDirLocal = obj.CoordSys.getAglobal()'*xDirGlobal;
            X1 = obj.Points(:,1) + [obj.Chords(1)*(obj.ChordwisePos(1)-0.5);0;0];
            X4 = obj.Points(:,2) + [obj.Chords(2)*(obj.ChordwisePos(2)-0.5);0;0];
            X1 = X1 - obj.Chords(1)*xDirLocal*0.5;
            X4 = X4 - obj.Chords(2)*xDirLocal*0.5;
            X2 = X1 + obj.Chords(1)*xDirLocal;
            X3 = X4 + obj.Chords(2)*xDirLocal;
            V12 = X2-X1;
            V43 = X3-X4;
            V14 = X4-X1;
            etaChord = linspace(0,1,obj.nChord+1);
            etaSpan = linspace(0,1,obj.nSpan+1);
            Xs = zeros(4,3,obj.nChord*obj.nSpan);
            idx = 1;
            for j = 1:obj.nSpan
                Vc = interp1([0 1],[V12,V43]',etaSpan(j:(j+1)))';
                Xle = [X1,X1] + [V14,V14].*repmat(etaSpan(j:(j+1)),3,1);
                for k = 1:obj.nChord
                    Xs(1,:,idx) = Xle(:,1) + Vc(:,1)*etaChord(k);
                    Xs(2,:,idx) = Xle(:,1) + Vc(:,1)*etaChord(k+1);
                    Xs(3,:,idx) = Xle(:,2) + Vc(:,2)*etaChord(k+1);
                    Xs(4,:,idx) = Xle(:,2) + Vc(:,2)*etaChord(k);
                    idx = idx + 1;
                end
            end
        end
        function Xs = get_centroids(obj)
            xDirGlobal = obj.AeroCoordSys.getAglobal()*[1;0;0];
            xDirLocal = obj.CoordSys.getAglobal()'*xDirGlobal;
            X1 = obj.Points(:,1) + [obj.Chords(1)*(obj.ChordwisePos(1)-0.5);0;0];
            X4 = obj.Points(:,2) + [obj.Chords(2)*(obj.ChordwisePos(2)-0.5);0;0];
            X1 = X1 - obj.Chords(1)*xDirLocal*0.5;
            X4 = X4 - obj.Chords(2)*xDirLocal*0.5;
            X2 = X1 + obj.Chords(1)*xDirLocal;
            X3 = X4 + obj.Chords(2)*xDirLocal;
            V12 = X2-X1;
            V43 = X3-X4;
            etaChord = linspace(0,1,obj.nChord+2);
            etaChord = etaChord(2:end-1);
            etaSpan = linspace(0,1,obj.nSpan+2);
            etaSpan = etaSpan(2:end-1);
            Xs = zeros(3,obj.nChord*obj.nSpan);
            idx = 1;
            for j = 1:obj.nSpan
                Vc = interp1([0 1],[V12,V43]',etaSpan(j))';
                Xle = X1 + (X4-X1)*etaSpan(j);
                for k = 1:obj.nChord
                    Xs(:,idx) = Xle + Vc*etaChord(k);
                    idx = idx + 1;
                end
            end
        end
        function Ns = get_normal(obj)
            xDirGlobal = obj.AeroCoordSys.getAglobal()*[1;0;0];
            xDirLocal = obj.CoordSys.getAglobal()'*xDirGlobal;
            N = cross(xDirLocal,[0 1 0]');
            Ns = repmat(N,1,obj.nChord*obj.nSpan);
        end
        function IDs = get_panelIDs(obj)
            IDs = (0:1:(obj.nChord*obj.nSpan - 1)) + obj.ID;
        end
        function Export(obj,fid)
            if ~isempty(obj)
                mni.printing.bdf.writeComment(fid,"CAERO2 : Defines Aerodyanmic Panels");
                mni.printing.bdf.writeColumnDelimiter(fid,"short")
                angles = {};
                for i = 1:length(obj)
                    xDirGlobal = obj(i).AeroCoordSys.getAglobal()*[1;0;0];
                    xDirLocal = obj(i).CoordSys.getAglobal()'*xDirGlobal;
                    angles{i} = ones(1,obj(i).nChord*obj(i).nSpan)*(90-acosd(xDirLocal'*[0;0;-1]));
                    X1 = obj(i).CoordSys.getPointGlobal(obj(i).Points(:,1) + [obj(i).Chords(1)*(obj(i).ChordwisePos(1)-0.5);0;0]);
                    X4 = obj(i).CoordSys.getPointGlobal(obj(i).Points(:,2) + [obj(i).Chords(2)*(obj(i).ChordwisePos(2)-0.5);0;0]);
                    X1 = X1 - obj(i).Chords(1)*xDirGlobal*0.5;
                    X4 = X4 - obj(i).Chords(2)*xDirGlobal*0.5;
                    mni.printing.cards.CAERO1(obj(i).ID,obj(i).PID,X1,X4,...
                        obj(i).Chords(1),obj(i).Chords(2),1,...
                        NSPAN=obj(i).nSpan,NCHORD=obj(i).nChord).writeToFile(fid);
                end
                %print DMI entry
                [~,idx] = sort([obj.ID]);
                angles = [angles{idx}];
                DMI_W2GJ = mni.printing.cards.DMI('W2GJ',deg2rad(angles(:)),2,1,0);
                DMI_W2GJ.writeToFile(fid);

                %print aero properties
                mni.printing.bdf.writeComment(fid,"PAERO1 : Defines Aerodyanmic Properties for panels");
                mni.printing.bdf.writeColumnDelimiter(fid,"short")
                for i = 1:length(obj)
                    mni.printing.cards.PAERO1(obj(i).PID).writeToFile(fid);
                end
                %print aero spline
                mni.printing.bdf.writeComment(fid,"Aerodynamic Splines: Defined by a SPLINE, AELIST and SET1 card");
                for i = 1:length(obj)
                    if numel(obj(i).StructuralPoints)>0
                        splitMesh = ~isempty(obj(i).DisplacementPoints);
                        if splitMesh
                            usage = 'FORCE';
                        else
                            usage = 'BOTH';
                        end
                        switch obj(i).SplineType
                            case 4
                                mni.printing.bdf.writeColumnDelimiter(fid,"short")
                                id = obj(i).ID + (obj(i).nSpan*obj(i).nChord);
                                mni.printing.cards.SPLINE4(id,obj(i).ID,obj(i).SID(1),obj(i).SID(2),USAGE=usage).writeToFile(fid);
                                mni.printing.cards.AELIST(obj(i).SID(1),obj(i).ID:(id-1)).writeToFile(fid);
                                mni.printing.cards.SET1(obj(i).SID(2),[obj(i).StructuralPoints.ID]).writeToFile(fid);
                                if splitMesh
                                    mni.printing.cards.SPLINE4(id+1,obj(i).ID,obj(i).SID(1),obj(i).SID(3),USAGE='DISP',METH='TPS',FTYPE='WF2',RCORE=0.5).writeToFile(fid);
                                    mni.printing.cards.SET1(obj(i).SID(3),[obj(i).DisplacementPoints.ID]).writeToFile(fid);
                                end
                            case 6
                                mni.printing.bdf.writeColumnDelimiter(fid,"short")
                                id = obj(i).ID + (obj(i).nSpan*obj(i).nChord);
                                mni.printing.cards.SPLINE4(id,obj(i).ID,obj(i).SID(1),obj(i).SID(2),USAGE=usage).writeToFile(fid);
                                mni.printing.cards.AELIST(obj(i).SID(1),obj(i).ID:(id-1)).writeToFile(fid);
                                mni.printing.cards.SET1(obj(i).SID(2),[obj(i).StructuralPoints.ID]).writeToFile(fid);
                                if splitMesh
                                    mni.printing.cards.SPLINE6(id+1,obj(i).ID,obj(i).SID(1),obj(i).SID(3),USAGE='DISP').writeToFile(fid);
                                    mni.printing.cards.SET1(obj(i).SID(3),[obj(i).DisplacementPoints.ID]).writeToFile(fid);
                                end
                            case 7
                                mni.printing.bdf.writeColumnDelimiter(fid,"short")
                                id = obj(i).ID + (obj(i).nSpan*obj(i).nChord);
                                mni.printing.cards.SPLINE4(id,obj(i).ID,obj(i).SID(1),obj(i).SID(2),USAGE=usage).writeToFile(fid);
                                mni.printing.cards.AELIST(obj(i).SID(1),obj(i).ID:(id-1)).writeToFile(fid);
                                mni.printing.cards.SET1(obj(i).SID(2),[obj(i).StructuralPoints.ID]).writeToFile(fid);
                                if splitMesh
                                    mni.printing.cards.SPLINE7(id+1,obj(i).ID,obj(i).SID(1),obj(i).SID(3),obj(i).CoordSys.ID,USAGE='DISP',DTOR=0.1).writeToFile(fid);
                                    mni.printing.cards.SET1(obj(i).SID(3),[obj(i).DisplacementPoints.ID]).writeToFile(fid);
                                end
                            otherwise
                                error('Unkown Sline Type %.0f',obj(i).SplineType)

                        end
                    end
                end
                mni.printing.bdf.writeColumnDelimiter(fid,"short")
            end
        end
    end
end
