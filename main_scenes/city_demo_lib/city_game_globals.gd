## Global definitions for the city game.
##
## Don't use this in the `global_lib` part of citygamesystems, this is
## supposed to be a dependency for the higher up stuff, not the basic
## libraries.
## When moving things from the city game into basic libraries, either
## refactor the code involved to be agnostic of this, or move the affected
## definitions away from here into those libraries (if this ever enters the
## territory of having to worry about breaking API-compatibility with
## downstream users of the city game, it might be worth considering
## leaving the definitions here intact, but assigning the values from the basic
## libraries where they were moved to).
##
## When using the city game as a basis to make a game, there are some options:
##   - Extend this to your needs.
##     - The only caveat with this is that if you want to update from upstream,
##       you'll have to sort out the merge conflicts in this file.
##   - Create a definition file of your own in addition to this.
##   - Just wing it with String literals where applicable.
##   - A code generator that generates this file out of other files. If
##     the latter idea appeals to you, open an Issue:
##     https://github.com/Aziroshin/citygamesystems/issues/new
##
## Also note that the `CGS_` prefix for strings should (only) be used for
## definitions by citygamesystems, in order to decrease the chance for conflicts
## with derived games.

# The reason this is a Node instead of `RefCounted` is that there may yet be
# the option to turn this into something that could offer additional
# functionality at runtime as part of the scene tree, e.g. arrays of definitions
# for `in` kinds of checks and whatnot. With it being a node, it could also be
# a subclass doing that, perhaps in a derived game. Of course, there'd be a
# disparity between the basic city game things and the derived game way of using
# this in that case.
extends Node
class_name CityGameGlobals


## Node groups used in the city game.
##
## Note that, whilst the convention for this class is to use all upper case
## letters and have the constant name and its String be identical, this cannot
## be relied upon (e.g. for name collision prevention), since this might get
## extended by a project that integrates with or has code that works with node
## groups that include spaces or other characters that can't be used in variable
## names.
##
## At least for `CGS_` constants, if the node name is plural it means it may
## contain more than one node. If it's singular, it's expected to only contain
## one.
class NodeGroups:
	# Single node groups.
	const CGS_COLLIDER_MANAGER := &"CGS_COLLIDER_MANAGER"
	
	# Collider groups.
	const CGS_CORNER_COLLIDERS := &"CGS_CORNER_COLLIDERS"
	const CGS_BOUNDARY_COLLIDERS := &"CGS_BOUNDARY_COLLIDERS"
	const CGS_TOOL_COLLIDERS := &"CGS_TOOL_COLLIDERS"


## Special node names used in the city game.
class NodeNames:
	const CGS_COLLIDER_MANAGER := &"ColliderManager"


## Names of metadata keys (as in `set_meta`/`get_meta`).
class MetaNames:
	## Refers to the `WorldObject` a collider is associated with.
	const WORLD_OBJECT_ON_COLLIDERS := &"cgs_world_object"
