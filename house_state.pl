% File: house_state.pl
% Description: Snapshot of the current virtual home state (Phase 1)
% Predicates:
%   device(ID, Type, [Properties]).
%   sensor(ID, Type, [Properties]).
%   fact(Key, Value).
%
% Example queries:
%   ?- device(bedroom_ac, _, Properties).
%   ?- sensor(bedroom_temp_sensor, _, Props).
%   ?- fact(time, T).
 
% Make state predicates dynamic so the engine can update them at runtime
:- dynamic device/3, sensor/3, fact/2.

% ----------------------
% Devices
% ----------------------

device(bedroom_light, light, [status(off), brightness(100)]).
% Air conditioner in bedroom
device(bedroom_ac, ac, [status(off), target_temp(24)]).
% Living room light
device(living_room_light, light, [status(off), brightness(0)]).
% Front door smart lock
device(front_door_lock, lock, [status(locked)]).

% ----------------------
% Sensors
% ----------------------

% Motion sensors
sensor(bedroom_motion_sensor, motion, [status(no_motion)]).
sensor(living_room_motion_sensor, motion, [status(no_motion)]).

% Temperature sensor (Celsius)
sensor(bedroom_temp_sensor, temperature, [value(29)]).

% ----------------------
% Global facts
% ----------------------

fact(time, '22:15').
fact(occupants_at_home, yes).
