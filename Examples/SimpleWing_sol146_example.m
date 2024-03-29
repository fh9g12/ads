%% Example Exicution of a SOL146 solution in MSC NAstran
% model is of a cantilever wing suitable for WT testing and utilises the 
% baff file format to generate a model
clear all
%% Create the FeModel

% get baff model from private function
model = UniformBaffWing();

% add a monitor point at tip
mp = baff.Point("eta",1,"Name","MP");
model.Wing(1).add(mp);
model = model.Rebuild;

%convert to an FE Model
fe = ads.baff.baff2fe(model);

% plot the model
f = figure(1);
clf;
hold on
fe.draw();
ax = gca;
ax.Clipping = false;
ax.ZAxis.Direction = "reverse";
axis equal

%% Setup 103 Analysis with Nastran
U = 18;  % velocity in m/s

%flatten the FE model and update the element ID numbers
fe = fe.Flatten;
IDs = fe.UpdateIDs();

% Add Aero Settings
fe.CoordSys(end+1) = ads.fe.CoordSys(Origin=[0;0;0],A=eye(3));
fe.AeroSettings(1) = ads.fe.AeroSettings(0.12,1,2,ACSID=fe.CoordSys(end),SymXZ=true);
for i = 1:length(fe.AeroSurfaces)
    fe.AeroSurfaces(i).AeroCoordSys = fe.CoordSys(end);
end
IDs = fe.UpdateIDs();


% create the 'sol' object
idx = [fe.Points.Tag] == "Root Connection";
ID = [fe.Points(idx).ID];
sol = ads.nast.Sol146(ID);
sol.FreqRange = [0 200];
sol.V = U;
sol.Mach = 0;
sol.rho = 1.225;
sol.ModalDampingPercentage = 0;

% gust setup
sol.GustDuration = 10;
sol.GustTstep = 0.01;
sol.NFreq = 1000;
sol.GustFreq = [];
Amp = -0.5;
Freqs = [3,6,9];
for i = 1:length(Freqs)
    sol.Gusts(i) = ads.nast.GustSettings(Amp,nan,Freqs(i),'Freq');
    sol.Gusts(i).Tdelay = 1;
end
% update the IDs
sol.UpdateID(IDs);

% run Nastran
BinFolder = 'ex_uw_sol146';
sol.run(fe,Silent=false,NumAttempts=1,BinFolder=BinFolder);

%% plot WRBM response
res = mni.result.hdf5(fullfile(BinFolder,'bin','sol146.h5'));
data = res.read_dynamic();

idx = [fe.Points.Tag] == "MP";
ID = [fe.Points(idx).ID];
[~,idx_mp] = ismember(data(1).Displacement.IDs,ID);

f = figure(1);
clf;
tt = tiledlayout(2,1);
for i = 1:length(Freqs)
    nexttile(1);
    hold on
    p = plot(data(i).t,data(i).Displacement.Z(:,logical(idx_mp))*1000);
    p.DisplayName = sprintf('Freq: %.0f Hz', Freqs(i));
    nexttile(2);
    hold on
    p = plot(data(i).t,data(i).Force.Mx(:,1));
    p.DisplayName = sprintf('Freq: %.0f Hz', Freqs(i));
end
nexttile(1);
xlabel('Time [s]')
ylabel('displacement [mm]')
xlim([0 5])

nexttile(2);
xlabel('Time [s]')
ylabel('WRBM [Nm]')
xlim([0 5])

lg = legend;
lg.Location = "northeast";


