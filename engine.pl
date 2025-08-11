% File: engine.pl
% Description: Phase 3 - Engine & Simulator for HomeBrain

:- dynamic loaded/0.
:- use_module(library(readutil)).

% Ensure state and rules are loaded exactly once
init_engine :-
    ( loaded -> true
    ;  ensure_loaded('house_state.pl'),
       ensure_loaded('rules.pl'),
       asserta(loaded)
    ).

% Entry point: run one simulation tick
run_simulation_tick :-
    init_engine,
    fact(time, T),
    format("--- TICK @ ~w ---~n", [T]),
    collect_active_rule_actions(Pairs),
    ( Pairs == [] ->
        writeln('No actions needed.')
    ; print_decisions(Pairs),
      flatten_actions(Pairs, FlatActions),
      apply_actions(FlatActions)
    ),
    writeln('====================').

% Collect Name-[Actions] pairs for rules whose conditions all hold
collect_active_rule_actions(Pairs) :-
    findall(Name-Actions,
            ( rule(Name, Conditions, Actions),
              all_conditions_true(Conditions)
            ),
            Pairs).

all_conditions_true([]).
all_conditions_true([C|Cs]) :-
    check_condition(C),
    all_conditions_true(Cs).

% ----------------------
% Condition evaluation
% ----------------------

% time conditions
check_condition(condition(time, equals, Target)) :-
    fact(time, T),
    T == Target.

check_condition(condition(time, between, Start, End)) :-
    fact(time, T),
    time_between(T, Start, End).

% sensor property comparison: Op in '>'/'<'/equals
check_condition(condition(sensor, SensorId, Property, Op, Target)) :-
    sensor(SensorId, _Type, Props),
    property_value(Props, Property, Value),
    compare_value(Op, Value, Target).

% device property equals only (for now)
check_condition(condition(device, DeviceId, Property, equals, Target)) :-
    device(DeviceId, _Type, Props),
    property_value(Props, Property, Value),
    Value == Target.

% global fact equality
check_condition(condition(fact, Key, equals, Target)) :-
    fact(Key, Value),
    Value == Target.

% ----------------------
% Helpers
% ----------------------

% Extract property from a list like [status(off), brightness(100)] by key
property_value(Properties, Key, Value) :-
    member(Term, Properties),
    Term =.. [Key, Value].

% Compare with operation
compare_value(equals, A, B) :- !, A == B.
compare_value('>', A, B) :- !,
    to_number(A, AN), to_number(B, BN), AN > BN.
compare_value('<', A, B) :- !,
    to_number(A, AN), to_number(B, BN), AN < BN.

% Convert atom/number to number
to_number(N, N) :- number(N), !.
to_number(A, N) :- atom(A), atom_number(A, N), !.

% Time utilities
% Accept atoms 'HH:MM' for Start/End/Time
atom_time_to_minutes(Atom, Minutes) :-
    atom(Atom),
    sub_atom(Atom, 0, 2, _, HHAtom),
    sub_atom(Atom, 3, 2, _, MMAtom),
    atom_number(HHAtom, HH),
    atom_number(MMAtom, MM),
    Minutes is HH*60 + MM.

% True if T is within [Start, End] inclusive, handling overnight ranges
% Examples:
%   time_between('22:00','21:00','06:00'). % true (overnight)
%   time_between('05:30','21:00','06:00'). % true (overnight)
%   time_between('12:00','09:00','17:00'). % true (same-day)

time_between(T, Start, End) :-
    atom_time_to_minutes(T, TM),
    atom_time_to_minutes(Start, SM),
    atom_time_to_minutes(End, EM),
    ( SM =< EM
    -> TM >= SM, TM =< EM                 % same-day range
    ;  (TM >= SM ; TM =< EM)              % overnight range wrapping midnight
    ).

% ----------------------
% Printing decisions
% ----------------------

print_decisions([]).
print_decisions([Name-Actions | Rest]) :-
    format("RULE MATCH: ~w~n", [Name]),
    print_actions(Actions),
    print_decisions(Rest).

print_actions([]).
print_actions([action(Device, Command, Value) | Rest]) :-
    format("DECISION: ~w(~w, ~w)~n", [Command, Device, Value]),
    print_actions(Rest).

% ----------------------
% Applying actions to state
% ----------------------

% Flatten Name-[Actions] pairs into a single list of actions
flatten_actions(Pairs, Flat) :-
    findall(A, (member(_N-As, Pairs), member(A, As)), Flat).

apply_actions([]).
apply_actions([A|As]) :-
    apply_action(A),
    apply_actions(As).

% Support common action commands
apply_action(action(Device, set_status, Val)) :- !,
    set_device_prop(Device, status, Val),
    format("APPLY: set_status(~w, ~w)~n", [Device, Val]).
apply_action(action(Device, set_brightness, Val)) :- !,
    set_device_prop(Device, brightness, Val),
    format("APPLY: set_brightness(~w, ~w)~n", [Device, Val]).
apply_action(action(Device, set_target_temp, Val)) :- !,
    set_device_prop(Device, target_temp, Val),
    format("APPLY: set_target_temp(~w, ~w)~n", [Device, Val]).
% set a global fact: action(fact(Key), set, Value)
apply_action(action(fact(Key), set, Val)) :- !,
    set_fact(Key, Val),
    format("APPLY: set_fact(~w, ~w)~n", [Key, Val]).
% set a sensor property: action(sensor(SensorId), set, prop(Key,Val))
apply_action(action(sensor(SensorId), set, prop(Key, Val))) :- !,
    set_sensor_prop(SensorId, Key, Val),
    format("APPLY: set_sensor_prop(~w, ~w=~w)~n", [SensorId, Key, Val]).
apply_action(Unknown) :-
    format("WARN: Unknown action ~w~n", [Unknown]).

% Update a device property in dynamic state
set_device_prop(DeviceId, Key, Value) :-
    device(DeviceId, Type, Props),
    update_prop_list(Props, Key, Value, NewProps),
    retract(device(DeviceId, Type, Props)),
    assertz(device(DeviceId, Type, NewProps)), !.
set_device_prop(DeviceId, Key, Value) :-
    % If not found (shouldn't happen), create a generic device entry
    Term =.. [Key, Value],
    assertz(device(DeviceId, unknown, [Term])).

% Replace or append Key(Value) in a property list
update_prop_list([], Key, Value, [Term]) :-
    Term =.. [Key, Value].
update_prop_list([H|T], Key, Value, [NewH|T]) :-
    H =.. [Key, _Old], !,
    NewH =.. [Key, Value].
update_prop_list([H|T], Key, Value, [H|T2]) :-
    update_prop_list(T, Key, Value, T2).

% ----------------------
% Interactive loop & helpers
% ----------------------

% Start interactive simulation loop
run_loop :-
    init_engine,
    writeln('Starting HomeBrain interactive loop...'),
    loop_.

loop_ :-
    nl,
    writeln('==== HomeBrain Menu ===='),
    writeln('1) Run simulation tick'),
    writeln('2) Set time (HH:MM)'),
    writeln('3) Toggle occupants_at_home'),
    writeln('4) Set living_room_motion (motion/no_motion)'),
    writeln('5) Set bedroom temperature (number)'),
    writeln('6) Show state'),
    writeln('7) Quit'),
    write('Select [1-7]: '),
    read_line_to_string(user_input, S),
    handle_choice(S).

handle_choice("1") :- run_simulation_tick, !, loop_.
handle_choice("2") :- prompt_set_time, !, loop_.
handle_choice("3") :- toggle_occupants, !, loop_.
handle_choice("4") :- prompt_set_motion, !, loop_.
handle_choice("5") :- prompt_set_temperature, !, loop_.
handle_choice("6") :- print_state, !, loop_.
handle_choice("7") :- writeln('Bye.').
handle_choice(_)   :- writeln('Invalid choice.'), loop_.

% Display current state
print_state :-
    fact(time, T), format('Time: ~w~n', [T]),
    ( fact(occupants_at_home, H) -> true ; H = unknown ),
    format('Occupants at home: ~w~n', [H]),
    writeln('Devices:'),
    forall(device(Id, Type, Props), format('  ~w (~w): ~w~n', [Id, Type, Props])),
    writeln('Sensors:'),
    forall(sensor(Id, Type, Props), format('  ~w (~w): ~w~n', [Id, Type, Props])).

% Prompt helpers
prompt_set_time :-
    write('Enter time HH:MM: '),
    read_line_to_string(user_input, S),
    ( valid_time(S) ->
        atom_string(A, S), set_fact(time, A),
        format('Time set to ~w~n', [A])
      ; writeln('Invalid time format (expected HH:MM).')
    ).

prompt_set_motion :-
    write('Enter motion (motion/no_motion): '),
    read_line_to_string(user_input, S0),
    string_lower(S0, S),
    ( S == "motion" -> V = motion
    ; S == "no_motion" -> V = no_motion
    ; writeln('Invalid value.'); fail
    ),
    set_sensor_prop(living_room_motion_sensor, status, V),
    format('living_room_motion_sensor.status := ~w~n', [V]).

prompt_set_temperature :-
    write('Enter bedroom temperature (number): '),
    read_line_to_string(user_input, S),
    ( catch(number_string(N, S), _, fail) ->
        set_sensor_prop(bedroom_temp_sensor, value, N),
        format('bedroom_temp_sensor.value := ~w~n', [N])
      ; writeln('Invalid number.')
    ).

toggle_occupants :-
    ( fact(occupants_at_home, yes) -> set_fact(occupants_at_home, no), W=no
    ; set_fact(occupants_at_home, yes), W=yes
    ),
    format('occupants_at_home := ~w~n', [W]).

% Validate HH:MM using existing atom_time_to_minutes/2
valid_time(S) :-
    string(S), atom_string(A, S),
    catch(atom_time_to_minutes(A, _), _, fail).

% Update a sensor property in dynamic state
set_sensor_prop(SensorId, Key, Value) :-
    sensor(SensorId, Type, Props),
    update_prop_list(Props, Key, Value, NewProps),
    retract(sensor(SensorId, Type, Props)),
    assertz(sensor(SensorId, Type, NewProps)), !.
set_sensor_prop(SensorId, Key, Value) :-
    % If not found, create a generic sensor entry
    Term =.. [Key, Value],
    assertz(sensor(SensorId, unknown, [Term])).

% Set a global fact value (replace existing)
set_fact(Key, Value) :-
    retractall(fact(Key, _)),
    assertz(fact(Key, Value)).
