include <./src/core/standard.scad>
use <./src/helpers/generic-helpers.scad>
include <./src/core/gridfinity-baseplate.scad>

include <../../BOSL2/std.scad>

// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better in development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins.
 the magnet holes can have an extra cut in them to make it easier to print without supports
 tabs will automatically be disabled when gridz is less than 3, as the tabs take up too much space
 base functions can be found in "gridfinity-rebuilt-utility.scad"
 comments like ' //.5' after variables are intentional and used by the customizer
 examples at end of file

 #BIN HEIGHT
 The original gridfinity bins had the overall height defined by 7mm increments.
 A bin would be 7*u millimeters tall with a stacking lip at the top of the bin (4.4mm) added onto this height.
 The stock bins have unit heights of 2, 3, and 6:
 * Z unit 2 -> 7*2 + 4.4 -> 18.4mm
 * Z unit 3 -> 7*3 + 4.4 -> 25.4mm
 * Z unit 6 -> 7*6 + 4.4 -> 46.4mm

 ## Note:
 The stacking lip provided here has a 0.6mm fillet instead of coming to a sharp point.
 Which has a height of 3.55147mm instead of the specified 4.4mm.
 This **has no impact on stacking height, and can be ignored.**

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

include <src/core/standard.scad>
use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>

// ===== PARAMETERS ===== //

/* [General Settings] */
// number of bases along x-axis
gridx = 1;//[1:10]
// number of bases along y-axis
gridy = 1;//[1:10]
// bin height. See bin height information and "gridz_define" below.
gridz = 6;//[1:50]
// Half grid sized bins.  Implies "only corners".
half_grid = false;
// negative thingy down the middle?
negative_thingy = false;
// cut zheight into base?
cut_numbers = true;

/* [Linear Compartments] */
// number of X Divisions (set to zero to have solid bin)
divx = 1;//[1:10]
// number of Y Divisions (set to zero to have solid bin)
divy = 1;//[1:10]

/* [Height] */
// determine what the variable "gridz" applies to based on your use case
gridz_define = 0; // [0:7mm increments - Zack's method,1:internal height in mm, 2:overall external height in mm]
// overrides internal block height of bin (for solid containers). Leave zero for default height. Units: mm
height_internal = 0;
// snap gridz height to nearest 7mm increment
enable_zsnap = true;

/* [Cylindrical Compartments] */
// number of cylindrical X Divisions (mutually exclusive to Linear Compartments)
cdivx = 0;//[1:10]
// number of cylindrical Y Divisions (mutually exclusive to Linear Compartments)
cdivy = 0; //[0:1:10]
// orientation
c_orientation = 2; // [0: x direction, 1: y direction, 2: z direction]
// diameter of cylindrical cut outs
cd = 10; // .1
// cylinder height
ch = 1;  //.1
// spacing to lid
c_depth = 1;
// chamfer around the top rim of the holes
c_chamfer = 0.5; //[0:0.1:1]

/* [Features] */
// the type of tabs
style_tab = 1; //[0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
// which divisions have tabs
place_tab = 0; // [0:Everywhere-Normal,1:Top-Left Division]
// how should the top lip act
style_lip = 0; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]
// scoop weight percentage. 0 disables scoop, 1 is regular scoop. Any real number will scale the scoop.
scoop = 0.5; //[0:0.1:1]

/* [Base Hole Options] */
// only cut magnet/screw holes at the corners of the bin to save uneccesary print time
only_corners = true;
//Use gridfinity refined hole style. Not compatible with magnet_holes!
refined_holes = false;
// Base will have holes for 6mm Diameter x 2mm high magnets.
magnet_holes = true;
// Base will have holes for M3 screws.
screw_holes = false;
// Magnet holes will have crush ribs to hold the magnet.
crush_ribs = true;
// Magnet/Screw holes will have a chamfer to ease insertion.
chamfer_holes = true;
// Magnet/Screw holes will be printed so supports are not needed.
printable_hole_top = true;
// Enable "gridfinity-refined" thumbscrew hole in the center of each base: https://www.printables.com/model/413761-gridfinity-refined
enable_thumbscrew = false;

/* [Advanced] */
$LAYER_HEIGHT = 0.20; // .04
// offset for magnet fitment. lower number - looser magnet fitment
off = -0.10; // .05
negative_thingy_copies = true;
negative_thingy_rot = true;
enable_base = true;

/* [Hidden] */
$fa = 8;
$fs = 0.25; // .01

hole_options = bundle_hole_options(refined_holes, magnet_holes, screw_holes, crush_ribs, chamfer_holes, printable_hole_top);
grid_dimensions = GRID_DIMENSIONS_MM / (half_grid ? 2 : 1);

// extra magic //
module my_gridf_edge(length=10, is_snap=false) {
    module my_sweep_rounded(width=10) {
        assert(width > 0);

        half_width = width/2;
        path_points = [
            [-half_width, 0], //start
            [half_width, 0], // over
        ];
        path_vectors = [
            path_points[1] - path_points[0],
        ];

        // these contain the translations, but not the rotations
        // openscad requires this hacky for loop to get accumulate to work!
        first_translation = affine_translate([path_points[0].y, 0,path_points[0].x]);

        // Bring extrusion to the xy plane
        affine_matrix = affine_rotate([90, 0, 90]);

        walls = affine_matrix * first_translation * affine_rotate([0, atanv(path_vectors[0]), 0]);

        multmatrix(walls)
            linear_extrude(vector_magnitude(path_vectors[0]))
            children();
    }
    new_length = is_snap ? length * l_grid : length;
    #my_sweep_rounded(new_length)
        _baseplate_cutter_polygon(BASEPLATE_HEIGHT+0.11);

    translate([0, BASE_PROFILE[3][0]/2, BASE_PROFILE[3][1]/2])
        hide_this()
        cuboid(size=[new_length, BASE_PROFILE[3][0], BASE_PROFILE[3][1]])
        children();

}


// ===== IMPLEMENTATION ===== //

//color("tomato") {
gridfinityInit(gridx, gridy, height(gridz, gridz_define, style_lip, enable_zsnap), height_internal, grid_dimensions=grid_dimensions, sl=style_lip) {
    if (divx > 0 && divy > 0) {
        cutEqual(n_divx = divx, n_divy = divy, style_tab = style_tab, scoop_weight = scoop, place_tab = place_tab);
    } else if (cdivx > 0 && cdivy > 0) {
        cutCylinders(n_divx=cdivx, n_divy=cdivy, cylinder_diameter=cd, cylinder_height=ch, coutout_depth=c_depth, orientation=c_orientation, chamfer=c_chamfer);
    }
}
if (enable_base) {
    difference() {
        gridfinityBase([gridx, gridy], grid_dimensions=grid_dimensions, hole_options=hole_options, only_corners=only_corners || half_grid, thumbscrew=enable_thumbscrew, off=off);
        if (negative_thingy) {
            xcopies(spacing = l_grid, n = negative_thingy_copies ? gridx : 1)
                up(BASE_PROFILE[3][1])
                zrot(90)
                zflip()
                yflip_copy()
                my_gridf_edge(length=gridy, is_snap=true);
            if (negative_thingy_rot) {
                ycopies(spacing = l_grid, n = negative_thingy_copies ? gridy : 1)
                    up(BASE_PROFILE[3][1])
                    zflip()
                    yflip_copy()
                    my_gridf_edge(length=gridx, is_snap=true);
            }
        }
        if (cut_numbers) {
            gridz_type_str = gridz_define == 0 ? "z"
                : (gridz_define == 1 ? "i"
                : "e");
            gridz_snap_str = enable_zsnap ? "|" : " ";
            gridz_str = str(gridz_type_str, gridz_snap_str, gridz);
            #translate(
                [
                    gridx % 2 == 1 ? 0 : GRID_DIMENSIONS_MM[0] / 2,
                    gridy % 2 == 1 ? 0 : GRID_DIMENSIONS_MM[0] / 2,
                    0,
                ]
            )
                linear_extrude($LAYER_HEIGHT)
                    rotate([00, 180, 90])
                        text(gridz_str, size=8, font="Liberation Mono:style=Bold", halign="center", valign="center");
        }
    }
}
//}


// ===== EXAMPLES ===== //

// 3x3 even spaced grid
/*
gridfinityInit(3, 3, height(6), 0, 42) {
	cutEqual(n_divx = 3, n_divy = 3, style_tab = 0, scoop_weight = 0);
}
gridfinityBase([3, 3]);
*/

// Compartments can be placed anywhere (this includes non-integer positions like 1/2 or 1/3). The grid is defined as (0,0) being the bottom left corner of the bin, with each unit being 1 base long. Each cut() module is a compartment, with the first four values defining the area that should be made into a compartment (X coord, Y coord, width, and height). These values should all be positive. t is the tab style of the compartment (0:full, 1:auto, 2:left, 3:center, 4:right, 5:none). s is a toggle for the bottom scoop.
/*
gridfinityInit(3, 3, height(6), 0, 42) {
    cut(x=0, y=0, w=1.5, h=0.5, t=5, s=0);
    cut(0, 0.5, 1.5, 0.5, 5, 0);
    cut(0, 1, 1.5, 0.5, 5, 0);

    cut(0,1.5,0.5,1.5,5,0);
    cut(0.5,1.5,0.5,1.5,5,0);
    cut(1,1.5,0.5,1.5,5,0);

    cut(1.5, 0, 1.5, 5/3, 2);
    cut(1.5, 5/3, 1.5, 4/3, 4);
}
gridfinityBase([3, 3]);
*/

// Compartments can overlap! This allows for weirdly shaped compartments, such as this "2" bin.
/*
gridfinityInit(3, 3, height(6), 0, 42)  {
    cut(0,2,2,1,5,0);
    cut(1,0,1,3,5);
    cut(1,0,2,1,5);
    cut(0,0,1,2);
    cut(2,1,1,2);
}
gridfinityBase(3, 3, 42, 0, 0, 1);
*/

// Areas without a compartment are solid material, where you can put your own cutout shapes. using the cut_move() function, you can select an area, and any child shapes will be moved from the origin to the center of that area, and subtracted from the block. For example, a pattern of three cylinderical holes.
/*
gridfinityInit(3, 3, height(6), 0, 42) {
    cut(x=0, y=0, w=2, h=3);
    cut(x=0, y=0, w=3, h=1, t=5);
    cut_move(x=2, y=1, w=1, h=2)
        pattern_linear(x=1, y=3, sx=42/2)
            cylinder(r=5, h=1000, center=true);
}
gridfinityBase([3, 3]);
*/

// You can use loops as well as the bin dimensions to make different parametric functions, such as this one, which divides the box into columns, with a small 1x1 top compartment and a long vertical compartment below
/*
gx = 3;
gy = 3;
gridfinityInit(gx, gy, height(6), 0, 42) {
    for(i=[0:gx-1]) {
        cut(i,0,1,gx-1);
        cut(i,gx-1,1,1);
    }
}
gridfinityBase([gx, gy]);
*/

// Pyramid scheme bin
/*
gx = 4;
gy = 4;
gridfinityInit(gx, gy, height(6), 0, 42) {
    for (i = [0:gx-1])
    for (j = [0:i])
    cut(j*gx/(i+1),gy-i-1,gx/(i+1),1,0);
}
gridfinityBase([gx, gy]);
*/
