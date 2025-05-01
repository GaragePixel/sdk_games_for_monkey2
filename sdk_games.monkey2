
Namespace sdk_games

#rem 
	sdk_games is a library who follows the same naming convention that sdk and sdk_mojo, from the same
	author (iDkP from GaragePixel) and the same project (minimal module assets for the Monkey2 language).
	This library provide a core gameplay systems while maintaining independence 
	from specific rendering approaches. So ready to make some sdk_games?
	
	Already in sdk_games:
	
		- Ink format: Narrative Scripting Language

	Roadmap:

    	- Entity Component System (ECS) 
    		- A modern architecture pattern for game objects that separates data from behavior. 

    	- State Machine System 
    		- For managing game states, character behaviors, and AI in a declarative way. 
    		A well-implemented state machine is rendering-agnostic and would benefit almost any game.

    	- Event System - A lightweight publisher/subscriber pattern implementation 
    	allowing game components to communicate without direct dependencies.

    	- Pathfinding 
    		- A* and navigation mesh 2d/3d implementations for AI movement, while are purely 
    		logical components, using stdlib.math.

    	- Spatial Partitioning 
    		- Quad trees, grid systems, and spatial hashing 
    		for efficient collision detection and entity queries belong to stdlib.math
	    	but will maybe has an interface for simplicity.
#end 

#Import "<stdlib>"

#Import "parsers/ink/ink"

Function Main()
End
