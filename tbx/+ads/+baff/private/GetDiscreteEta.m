function [etas] = GetDiscreteEta(obj)
arguments
    obj baff.Beam
end
%GETDISCRETEETA Summary of this function goes here
%   Detailed explanation goes here
etas = [obj.Stations.Eta];
% add eta from all children
child_eta = [obj.Children.Eta];
etas = unique([etas,child_eta]);
% ensure only make beam elements between eta 0 and 1 (children can have greater etas!)
etas = etas(etas>=0 & etas<=1);
%split each section to get required number of total elements
if etas(1)~=0 || etas(end)~=1
    error('eta must start and end at 0 and 1')
end
end
