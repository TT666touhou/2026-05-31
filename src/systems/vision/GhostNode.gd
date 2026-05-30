extends Node2D
class_name GhostNode

## GhostNode – frozen visual snapshot of a trackable object.
##
## Created by VisionTracker when a trackable leaves the player's vision.
## The ghost is placed in the world scene at the object's last-seen
## global_transform and only receives FogLight (light_mask = 1), so it
## remains dimly visible in the fog but does NOT move with the real physics
## object.
##
## Usage: VisionTracker creates ghosts via Node2D.duplicate() and
##        calls ghost.light_mask = 1 + adds it to the current scene.
##        You do NOT normally need to instantiate GhostNode directly.

# Optionally store a reference to the original for debugging.
var source_object: Node2D = null
