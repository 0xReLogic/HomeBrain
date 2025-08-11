% File: rules.pl
% Description: Rulebook (Phase 2) for the HomeBrain logic engine
%
% Predicate schema
% -----------------
% rule(Name, [Conditions], [Actions]).
% condition(Type, ...).
% action(DeviceId, Command, Value).
%
% Supported condition forms (for the upcoming engine):
%   - condition(time, between, StartHHMM, EndHHMM).
%   - condition(time, equals, HHMM).
%   - condition(sensor, SensorId, Property, Op, Value).   % e.g., Property=value/status; Op can be '>'/'<'/equals
%   - condition(device, DeviceId, Property, equals, Value). % compare device property
%   - condition(fact, Key, equals, Value).                  % global fact equality
%
% Example actions (to be interpreted by the engine):
%   - action(DeviceId, set_status, on|off|locked|unlocked).
%   - action(DeviceId, set_brightness, IntPercent).
%   - action(DeviceId, set_target_temp, IntCelsius).


% -----------------
% Sample Rules
% -----------------

% 1) Turn on AC if hot at night
rule('Turn on AC if hot at night',
     [ condition(time, between, '21:00', '06:00'),
       condition(sensor, bedroom_temp_sensor, value, '>', 27),
       condition(device, bedroom_ac, status, equals, off)
     ],
     [ action(bedroom_ac, set_status, on)
     ]).

% 2) Turn on living room light to 50% when there is motion at night
rule('Night motion turns on living room light 50%',
     [ condition(time, between, '22:00', '06:00'),
       condition(sensor, living_room_motion_sensor, status, equals, motion),
       condition(device, living_room_light, status, equals, off)
     ],
     [ action(living_room_light, set_brightness, 50),
       action(living_room_light, set_status, on)
     ]).

% 3) Lock front door when nobody is at home
rule('Lock front door when no one is home',
     [ condition(fact, occupants_at_home, equals, no),
       condition(device, front_door_lock, status, equals, unlocked)
     ],
     [ action(front_door_lock, set_status, locked)
     ]).

% 4) Dim bedroom light at 22:30
rule('Dim bedroom light at 22:30',
     [ condition(time, equals, '22:30')
     ],
     [ action(bedroom_light, set_brightness, 20),
       action(bedroom_light, set_status, on)
     ]).

% 5) At 22:15, simulate motion in living room (updates sensor)
rule('Simulate living room motion at 22:15',
     [ condition(time, equals, '22:15')
     ],
     [ action(sensor(living_room_motion_sensor), set, prop(status, motion))
     ]).

% 6) At 22:15, set occupants_at_home to no (updates global fact)
rule('Set occupants to away at 22:15',
     [ condition(time, equals, '22:15')
     ],
     [ action(fact(occupants_at_home), set, no)
     ]).
