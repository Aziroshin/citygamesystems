## Manages the life cycle for a type of WorldObject.
##
## The idea is for every WorldObject class to have a project specific way to
## create and deconstruct WorldObject objects. To increase the reusability of
## WorldObject classes, that sort of stuff is defined in a WorldObjectLifeCycler
## subclass; a sort of project specific companion class to the WorldObject class
## in question. The objects of these subclasses could be thought of as factories
## for objects of the WorldObject (sub)class they pertain to, whilst also
## providing ways to "deconstruct" it.
##
## This makes it so that WorldObject classes don't have to know, or guess,
## everything about the wider architecture of the project that goes into their
## life cycle management, and the code that, say, spawns some WorldObject object
## doesn't have to take care of adding it to some project specific lists and
## groups, making sure it's properly tied into how collision is handled in that
## project, etc.
##
## It might be a good idea to have a project specific subclass, off of which
## the WorldObject specific WorldObjectLifeCycler classes are then subclassed,
## if you'd like them to feature a common behaviour and/or interface.
##
## At the moment, this simply serves as a common baseclass for the purpose of
## type erasure, the definition of `Node` as a baseclass as well as
## communication of intent by code. The method signatures, especially the ones
## creating WorldObject objects, are too dependent on project specifics,
## and since there's no fully blown method overloading, defining them here
## would cause too much trouble. Every WorldObject could have its own
## "constructor" with its own parameters, perhaps even multiple ones (e.g.
## something like `house.create_from_curve3d(...)`).
##
## Perhaps we could have a basic "deconstructor" with no parameters and just
## ` -> void`, but that's probably best put into a project specific subclass.
extends Node
class_name WorldObjectLifeCycler

# For now, this acts as a basic interface for type erasure and defining `Node`
# as the common baseclass.
pass
