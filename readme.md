# sdk_games for Monkey2

Game development library for Monkey2 focusing on core game systems and abstractions without tying to specific rendering solutions.

![Version](https://img.shields.io/badge/version-0.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Documentation

[Documentation](https://github.com/GaragePixel/sdk_games_for_monkey2/tree/main/doc)

[Comparative study between LUA and Ink](https://github.com/GaragePixel/sdk_games_for_monkey2/blob/main/doc/lua_vs_ink.md)

## Purpose

The `sdk_games` module provides essential game systems that sit between the standard library (`stdlib`) and your game applications. It focuses on platform-agnostic implementations of common game development tools.

[stdlib](https://github.com/GaragePixel/stdlib-for-mx2/tree/main)

By separating core game logic from rendering concerns, `sdk_games` allows developers to:
- Reuse game systems across different rendering backends
- Focus on gameplay logic without renderer-specific code
- Create more testable and maintainable game architecture
- Leverage common patterns without reimplementation

## Components

Currently, the library includes:

### Bindings
  - **Lua Scripting**: Comprehensive bindings for the Lua programming language
    - Full Lua 5.x API integration
    - Script loading and execution
    - Bidirectional data binding
    - Safe sandboxed environments
    - Error handling and debugging support
    - Game state manipulation from scripts
    - Event-driven script callbacks

### Parsers
- **Ink Runtime**: Complete implementation of Inkle Studios' narrative scripting language runtime
  - Story parsing and execution
  - Variable management
  - Choice handling
  - Global state persistence
  - Story linking between files

### Entity Component System (ECS)
- Efficient data-oriented game object architecture
- Component-based design without deep inheritance
- System-focused processing of entities
- Cache-friendly data layout

### More to come...
- State machines
- Pathfinding algorithms or interface layer
- Spatial partitioning or interface layer
- Physics abstractions or interface layer

## Installation

1. Clone this repository into your Monkey2 modules folder:
```bash
cd /path/to/monkey2/modules
git clone https://github.com/GaragePixel/sdk_games_for_monkey2.git sdk_games
