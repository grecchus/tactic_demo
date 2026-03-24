# tactic_demo
# AI Tactical System

Main features of this project is a custom AI Tactical System

## Core Logic
The AI operates on a **State-Based Decision Matrix**. Every turn, the unit evaluates its surroundings to determine one of 8 possible states. This state is an integer derived from three binary conditions:

1. **AP Status**: Whether the unit has multiple actions left or is on its last action.
2. **Cover**: Whether the unit is currently positioned behind a static obstacle.
3. **Line of Sight**: Whether any enemies are detected within the unit's vision range.

The state value acts as an index to a list of function names (unit_ai) defined on the unit, allowing different behaviors for different unit types.

## Key Components

### 1. Decision Loop
The take_turn function executes the following sequence:
* Scans for enemies within line_of_sight.
* Checks for cover relative to enemies or the map center.
* Updates the current state.
* Executes actions via Callable (e.g., Move, Shoot, Wait).
* Waits for the action_finished signal if the action is continuous.

### 2. Movement and Positioning
* **find_cover**: Searches for TileMapLayer obstacles within range. It uses find_safest_side to determine which adjacent tile offers the best protection against visible threats.
* **move_forward**: Directs the unit toward the center of the map or toward cover if no enemies are present.
* **new_position_found**: Interface with the unit's pathfinding system using AStarGrid2D.

### 3. Combat Logic
* **find_target**: Iterates through enemies_in_sight and selects the target with the highest hit probability.
* **is_behind_cover**: Uses 2D raycasting to determine if a direct line of fire between two points is obstructed by high terrain (Wall1 or Wall2).

### 4. Utility Functions
* **get_enemies_in_sight**: Performs a radial physics check to identify units belonging to opposing teams.
* **get_objects_on_lof**: Traces a path between two coordinates to identify all intervening obstacles.
* **comp_dist_path**: A custom sorting function to prioritize tiles based on actual pathfinding distance rather than simple Euclidean distance.

## Configuration
To implement behavior, the unit_ai array must contain 8 sub-arrays of function names corresponding to the STATE enum. If a state is reached and no behavior is defined, the system will output an error and skip the turn.
