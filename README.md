# Roblox Pathfinding AI Module

This is a robust pathfinding module built for Roblox using Lua. It allows you to assign a moving target (`Vector3`, `CFrame`, or `BasePart`) to an entity, and it will pathfind and chase that target.

## 🚀 Features

- Supports chasing dynamic targets (`Vector3`, `BasePart`, `CFrame`)
- Smart update intervals based on distance
- Asynchronous path following
- Roaming logic if no target is available
- Clean coroutine/thread handling
- Designed for AI NPCs with humanoids

## 📁 Installation

1. Create a new ModuleScript inside `ServerScriptService`, and paste the module code inside.
2. Name the module e.g., `PathfinderModule`.

## 🔧 Usage

Here’s how to use it in a Script:

```lua
local Pathfinder = require(game.ServerScriptService.PathfinderModule)

local npc = workspace.Zombie -- Your NPC character
local player = game.Players:GetPlayers()[1] -- Just for example

-- Create the AI entity
local entity = Pathfinder.CreateChase(
	npc,       -- character model
	2,         -- Agent radius
	true,      -- Can jump
	80,        -- Pathfinding range
	{Water = 100}, -- Pathfinding costs
	true       -- Can roam when idle
)

-- Set a target for the entity
entity.Target = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
```
