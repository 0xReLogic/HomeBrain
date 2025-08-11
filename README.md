# HomeBrain

Prolog-based rule engine for a simulated smart home. The system models devices, sensors, and global facts as a dynamic state, evaluates rules over that state, prints decisions, and applies actions. An interactive loop is provided for manual simulation and testing.

## Features

- Dynamic state predicates (mutable at runtime):
  - `device(ID, Type, [Properties])`
  - `sensor(ID, Type, [Properties])`
  - `fact(Key, Value)`
- Rulebook with readable schema:
  - `rule(Name, [Conditions], [Actions]).`
  - Conditions on time, sensors, devices, and facts
  - Actions to update devices, sensors, and facts
- Engine:
  - Evaluates rules, prints matched rules and decisions
  - Applies actions by updating dynamic state (retract/assert)
- Interactive loop (`run_loop/0`):
  - Run ticks and change inputs (time, motion, occupants, temperature)
  - Inspect current state

## Requirements

- SWI-Prolog (tested with swipl for Windows)
  - Add SWI-Prolog to PATH or invoke via absolute path

## Project Structure

- `house_state.pl` — Initial dynamic state: devices, sensors, and global facts
- `rules.pl`       — Rulebook
- `engine.pl`      — Engine: condition evaluation, decision printing, action application, interactive loop
- `todo.txt`       — Original Indonesian plan + English updated roadmap
- `.gitignore`     — Ignore build artifacts, logs, editor files

## Quick Start

Run the interactive loop from the project directory:

```powershell
swipl -q -s engine.pl -g run_loop -t halt
```

Or run a single tick:

```powershell
swipl -q -s engine.pl -g run_simulation_tick -t halt
```

If SWI-Prolog is not in PATH, use the absolute path to `swipl.exe`.

## State Model

- Devices and sensors store properties as compound terms in a list, e.g. `[status(off), brightness(100)]`.
- Global facts capture environment and context, e.g. `fact(time, '22:15')` or `fact(occupants_at_home, yes)`.

Example from `house_state.pl`:

```prolog
device(bedroom_light, light, [status(off), brightness(100)]).
device(bedroom_ac, ac, [status(off), target_temp(24)]).

sensor(living_room_motion_sensor, motion, [status(no_motion)]).
sensor(bedroom_temp_sensor, temperature, [value(29)]).

fact(time, '22:15').
fact(occupants_at_home, yes).
```

## Rules

Schema:

- `rule(Name, [Conditions], [Actions]).`
- Conditions (examples):
  - `condition(time, between, '21:00', '06:00')`
  - `condition(time, equals, '22:30')`
  - `condition(sensor, SensorId, Property, Op, Value)`  % `Op` in `>`, `<`, `equals`
  - `condition(device, DeviceId, Property, equals, Value)`
  - `condition(fact, Key, equals, Value)`
- Actions (examples):
  - `action(DeviceId, set_status, on|off|locked|unlocked)`
  - `action(DeviceId, set_brightness, IntPercent)`
  - `action(DeviceId, set_target_temp, IntCelsius)`
  - `action(sensor(SensorId), set, prop(Key,Value))`
  - `action(fact(Key), set, Value)`

Example rules (`rules.pl`):

```prolog
rule('Turn on AC if hot at night',
     [ condition(time, between, '21:00', '06:00'),
       condition(sensor, bedroom_temp_sensor, value, '>', 27),
       condition(device, bedroom_ac, status, equals, off)
     ],
     [ action(bedroom_ac, set_status, on)
     ]).

rule('Night motion turns on living room light 50%',
     [ condition(time, between, '22:00', '06:00'),
       condition(sensor, living_room_motion_sensor, status, equals, motion),
       condition(device, living_room_light, status, equals, off)
     ],
     [ action(living_room_light, set_brightness, 50),
       action(living_room_light, set_status, on)
     ]).

rule('Simulate living room motion at 22:15',
     [ condition(time, equals, '22:15')
     ],
     [ action(sensor(living_room_motion_sensor), set, prop(status, motion))
     ]).

rule('Set occupants to away at 22:15',
     [ condition(time, equals, '22:15')
     ],
     [ action(fact(occupants_at_home), set, no)
     ]).
```

## Engine

Key predicates (`engine.pl`):

- `run_simulation_tick/0` — load state/rules, evaluate rules, print decisions, apply actions
- `check_condition/1` — evaluate supported condition forms
- `apply_actions/1`, `apply_action/1` — update dynamic state (devices, sensors, facts)
- `set_device_prop/3`, `set_sensor_prop/3`, `set_fact/2` — state mutation helpers
- `run_loop/0` — interactive menu

Interactive operations:

- Run tick
- Set time (HH:MM)
- Toggle occupants_at_home
- Set living room motion status (motion/no_motion)
- Set bedroom temperature (number)
- Show current state

## Extending

- Add rules: append to `rules.pl` using the same schema.
- Add actions: extend `apply_action/1` and implement corresponding helpers if needed.
- Add conditions: extend `check_condition/1` and supporting utilities.

Recommended roadmap:

- Persist state to a file (e.g., `current_state.pl`) after each tick
- Rule priorities and conflict resolution
- Debounce/cooldown for motion-triggered rules
- Negation in conditions (e.g., `condition(not(...))`)
- Scenes (composite actions) and relative actions (increase/decrease)
- Logging/history of decisions to files for debugging
- Optional: basic HTTP UI using SWI-Prolog HTTP libraries

## License

This project is licensed under the MIT License. See `LICENSE` for details.
