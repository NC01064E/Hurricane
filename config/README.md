# house.json: the chore schedule

Everything about *who does what, and when* lives in `house.json`. Edit it, re-zip the
channel, and sideload. No code changes needed.

The app checks the file on launch. If something is wrong, the app still opens
with an empty schedule. A toast appears, and **Admin > System Health > Chore
Schedule** names the exact field to fix, for example
`today.morning.rows[1] needs an owner (one of: emily, max, ...)`.

## People

Owners are always one of: `emily`, `max`, `anthony`, `patricia`, `nick`, `nicky`,
`parents`, `everyone`, `crew`, `house`. Adding a new person needs a code change
(faces, names and points live in the app).

## rotations

A rotation is a list of `turns`. Each turn maps a *slot* to a person.

| field      | meaning |
|------------|---------|
| `every`    | `"day"` advances every day; `"week"` advances once a week |
| `startsOn` | week rotations only: the day the new week starts (default `"thursday"`) |
| `turns`    | the cycle; it wraps around when it reaches the end |

`zones` and `crew` are required: the Chart and Crew pages show them.

> **Heads up:** the Chart page says *"Zones rotate every Monday"*, but zones have
> always actually rotated on **Thursday**. `zones.startsOn` is set to `"thursday"`
> so nothing changes when you install this build. To make the page true, set it to
> `"monday"`. Make that switch on a Thursday–Sunday and the current week's zones
> stay put. Switch on a Monday–Wednesday and it jumps straight to the next turn.

## today

Four blocks: `morning`, `afterSchool`, `evening`, and optional `saturday`
(shown on Saturdays only). Each block has a `title`, a `start` hour (0–23, used for
"early" bonuses and highlighting), and `rows`.

A row is either a fixed owner:

```json
{ "id": "beds", "text": "Beds made", "cat": "misc", "owner": "everyone" }
```

or the current turn of a rotation:

```json
{ "id": "trash", "text": "Trash to the curb", "cat": "trash", "rotation": "curb", "slot": "trash" }
```

- `id` must be unique. It is how a day's checkmarks are saved, so **renaming an
  id clears today's check for it**. `rhythm` is reserved.
- `cat` is one of `misc`, `laundry`, `dinner`, `trash`, `zones` (badges count these).
- A row may override its block's `start`.

## Screen limits

The screens are laid out for these maximums. Going over is reported as an
error, not cut off silently.

| item | max |
|------|-----|
| `today.morning` / `afterSchool` / `evening` / `saturday` rows | 4 / 2 / 8 / 1 |
| `rotations.zones` and `rotations.crew` turns | 3 |
| people in `rotations.zones` (chart columns) | 3 |
| `zoneJobs` zones / lines each | 3 / 3 |
| `crewJobs` | 3 |
| `rhythm` | exactly 7, Monday first |
| `resetZones` | 1–12 |

## Other sections

`laundryNote` (footer on Today), `zoneNames`, `zoneJobs` and `chart` (the Chart
page text), `crewJobs` (Crew page cards), `rhythm` (Rhythm page), and
`resetZones` (Reset page cards).
