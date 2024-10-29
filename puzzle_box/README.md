
# Puzzle Box with 3D labyrinth

Initial motivation for this project was to create a puzzle box with mechanically simple but relatively hard to open mechanism.
After considering several options I decided to use the labyrinth as the puzzle but enhance its complexity by making it three dimensional.
Labyrinth is easily configurable in the source code and it is not visible from the outside, allowing to make a puzzle of arbitrary complexity.
On the flip side the harder the labyrinth is, the longer it takes to open and close the box.

Three handles on top of the lid are connected to dead-bolts, each of them has a pin and surface with grooves.
They interlock in such a way that three 2D labyrinth projections are forming a 3D labyrinth.
This design does not allow the creation of arbitrary 3D maze though: when path segments are projected from 3D to 2D they may create other "ghost" segments,
not originally intended but nevertheless real paths that can be taken and this may significantly simplify the solution.
These ghost trajectories are unavoidable with this design, but they can be visualized and taken into account when creating the labyrinth.
See `maze_def.scad` for more details.

## Printing

All printable parts are defined in `puzzle.scad`. They are listed near the top of the file with suggested orientation for printing.

Bolts are better printed vertically with brim enabled and seam orientation "rear" (so that they won't go inside the labyrinth grooves)

Lid and lid cover need to be glued together.
Check that bolts are moving easily inside the slots and trim/file them if necessary before gluing the lid cover.

The body of the puzzle box (shaped as a wooden barrel) has to be printed bottom-up.
There are two ways to print it: with supports enabled (one part) or with a drop-in disk, so that no supports are needed and the bottom is smooth inside.
Insert a color change command (or just a pause) before the horizontal layer is printed and carefully insert the supporting disk.

### Assembling the lid

After the lid cover is glued, the bolts can be inserted.

X bolt is inserted first, it is one of the two thin ones with a small notch in the bottom and groove exiting to the side. 
It is inserted in the lower slot, and has the longest handle. After the handle is attached it should be kept in the outermost position.

Y bolt is inserted second, it is the remaining thin one with the exit groove parallel to the longer side.
It needs the second longest handle, and should be kept in the outermost position.

Z bolt is inserted last. It is the thick one with the pin on a separate plane. 
It needs the shortest handle. With X and Y bolts in the outermost positions it should easily go into place.

### Operation

To use 3D maze from `maze_def.scad` as a key note that the outermost handle position corresponds to 0,
and innermost position corresponds to `travel_steps` -- the maximum allowed coordinate. 
When all 3 handles are in the innermost position, the lid can be opened (or closed).

Changing the size of the pin or `travel_steps` alters the dimensions of the dead-bolts, hence size of the box itself.
If only labyrinth is modified (by changing `paths` definition),
re-printing just 3 dead-bolts gives a new puzzle configuration and all other parts can be reused.
