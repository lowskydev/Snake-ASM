# Assembly Snake Game

A classic Snake game written in x64 Assembly (MASM) for Windows.

## How to Play

- Use **arrow keys** to move
- Eat food `*` to grow
- Avoid walls and yourself
- Game speeds up as you grow

## Building

Requires Visual Studio 2022 with MASM for x64.

1. Open `Snake.sln` → Build (F7) → Run (F5)

## Architecture Overview

### Game States

![Game State Machine](Assets/13_game_state_machine.png)

### Main Program Flow

![Main Program Flow](Assets/01_main_program_flow.png)

### Game Loop

Each frame: check input (3x for responsiveness) → move snake → check collisions → update display.

![Game Loop](Assets/11_detailed_game_loop.png)

### Core Systems

| System | Description | Diagram |
|--------|-------------|---------|
| Movement | Snake moves by shifting body segments through an array | [View](Assets/03_snake_movement.png) |
| Body Shifting | Array-based segment management | [View](Assets/15_body_segment_shifting.png) |
| Collisions | Wall, self, and food collision detection | [View](Assets/04_collision_detection.png) |
| Input | Arrow keys with 180° turn prevention | [View](Assets/05_keyboard_input.png) |
| Food | Random spawn avoiding snake body | [View](Assets/06_food_system.png) |
| Menu | Adapts based on play history | [View](Assets/02_menu_system.png) |

### Technical Assets

| Diagram | Description |
|---------|-------------|
| [Data Structures](Assets/12_data_structures.png) | Memory layout and variables |
| [Call Hierarchy](Assets/14_procedure_call_hierarchy.png) | Procedure dependencies |
| [Drawing System](Assets/09_drawing_system.png) | Console rendering |
| [Score System](Assets/07_score_display_system.png) | Score calculation and display |
| [Initialization](Assets/08_initialization_system.png) | Game state reset |
| [Windows API](Assets/16_windows_api_integration.png) | External API usage |
| [Game Over](Assets/10_gameover_instructions.png) | End screens |

## Technical Details

- **Platform:** Windows 10/11
- **Language:** x64 Assembly (MASM)
- **Rendering:** Windows Console API
- **RNG:** C runtime (`rand`, `srand`)

## Authors

- Wiktor Szydlowski (75135)
- Valerii Matviiv (75176)
- Markiian Voloshyn (75528)
