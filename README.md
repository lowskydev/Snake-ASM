# Assembly Snake Game

A classic Snake game written in MASMx64 Assembly language for Windows

## About

This is a console-based Snake game where you control a snake that grows as it eats food. The game speeds up as your snake gets longer. Avoid hitting walls and yourself

## How to Play

- Use **arrow keys** to move the snake
- Eat food (*) to grow longer
- Avoid walls and your own body
- The game speeds up as you grow

## Building

This project requires:
- Visual Studio 2022 (or compatible)
- MASM (Microsoft Macro Assembler) for x64

To build:
1. Open `Snake.sln` in Visual Studio
2. Build the solution (F7)
3. Run the game (F5 or Ctrl+F5)

## Technical Details

- Written in x64 Assembly (MASM)
- Uses Windows Console API
- Uses C functions (`rand`, `srand`)
- Platform: Windows 10/11

## Features

- Main menu with options
- Score tracking
- High score system
- Progressive difficulty (speeds up as you grow)
