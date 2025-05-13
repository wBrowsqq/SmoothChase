# Roblox AI Pathfinding Module

This module is a lightweight, extendable Pathfinding AI system built in Roblox Lua, designed for server-side AI movement using the built-in PathfindingService. It allows you to create AI entities that can chase a target, roam randomly, and intelligently follow waypoints, with support for visibility checks, jump control, and update interval scaling.

✨ Features

✅ Smart chasing behavior with dynamic path recalculation

✅ Supports targets as Vector3, BasePart, or CFrame

✅ Roaming behavior when no valid target is found

✅ Efficient coroutine-based movement logic

✅ Adjustable parameters like range, jump ability, and path costs

🧠 How It Works

Each AI entity has a "target", which can be:

A fixed position (Vector3)

A reference to a BasePart (like a player’s torso or root)

A CFrame location

The module calculates a path to this position using PathfindingService, moves the entity through the waypoints, and optionally recalculates paths if the target moves.

If no target is available, the entity can roam by randomly picking valid positions.

📦 Installation

Create a ModuleScript inside ServerScriptService and paste the full module code.

Name it something like PathfindingModule.

🚀 How to Use

Here’s a basic setup example:
`
-- In a ServerScript inside ServerScriptService

local Pathfinding = require(game.ServerScriptService:WaitForChild("PathfindingModule"))

local npc = workspace:WaitForChild("MyNPC") -- Must have a PrimaryPart and Humanoid

-- Create an entity
local entity = Pathfinding.CreateChase(
	npc,         -- Character model
	2,           -- Agent radius
	true,        -- Can jump
	80,          -- Range (max chasing distance)
	{Water = 100}, -- Custom path costs
	true         -- Can roam when idle
)

-- Set a target (can be Vector3, BasePart, or CFrame)
entity.Target = workspace:WaitForChild("PlayerRootPart") -- or Vector3.new(...), or CFrame.new(...)
`

⚙️ Parameters Explained

When calling CreateChase, you provide the following:

Parameter

Type

Description

character

Model

NPC character with Humanoid and HumanoidRootPart.

radius

number

Radius used in PathfindingService. Determines NPC width.

canJump

boolean

Whether the entity can jump to reach targets.

range

number

Max distance to chase a target.

costs

table

Dictionary to define terrain costs (e.g., {Water = 100}).

canRoam

boolean

If true, the entity will pick random roam locations when no target is active.

Optional Properties (set after creation):

entity.Target: The goal position (Vector3, CFrame, or BasePart).

entity.OnSight: If true, will only chase if there’s clear vision (uses raycasting).

entity.Info: You can check this string to know if the entity is "Stopped", "Chasing", or "Roaming".

🧪 Tips

You can update entity.Target at any time to change goals.

For optimal performance, try limiting how often the target is reassigned.

If performance drops with many entities, increase the UPDATE_MULTIPLIER in the module.

🛠 Requirements

Your character model must include:

A Humanoid

A PrimaryPart (typically HumanoidRootPart)

Must be run in server-side scripts.

🧾 License

MIT License — Free to use, modify, and distribute with attribution.Credit is appreciated but not required.

