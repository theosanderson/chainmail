// Chainmail generator for OpenSCAD
// -------------------------------------------------------------
// This script creates a flat sheet of inter-locking rings in the
// classic European-4-in-1 pattern, printable *in-place* on most
// FDM and resin printers.
//
// Modified to be fully parameterized and to optionally add a
// base plate, supports for the bottom layer, and side walls.
// Revision: Added side walls and refined highest/lowest Z calculations.
// -------------------------------------------------------------

// ─── USER-ADJUSTABLE PARAMETERS ───────────────────────────────
$fn             = 20;      // global resolution (increase for smoother rings, min 12 for supports)
ring_id         = 10;      // inner diameter of each ring (mm)
wire_d          = 2;       // wire (ring) thickness / diameter (mm)

cols            = 3;       // number of rings horizontally (number of 'cell' units)
rows            = 3;       // number of rings vertically (number of 'cell' rows)
stacks          = 3;       // number of layers in Z-direction

// Parameters for optional base plate and supports
add_base_plate_and_supports = true; // Set to true to add base and supports
base_plate_gap              = 2;    // Gap between lowest ring part and base plate top
base_plate_thickness        = 1.5;  // Thickness of the base plate
support_diameter            = wire_d * 0.75; // Diameter of support pillars
base_plate_margin           = wire_d; // Margin around chainmail for base plate size

// Parameters for optional side walls
add_side_walls              = true; // Set to true to add side walls
wall_thickness              = base_plate_thickness; // Thickness of the side walls
wall_height_extension       = wire_d; // How much walls extend above highest ring

// ─── DERIVED GEOMETRY PARAMETERS (from original parameterization) ─────
cell_spacing_x = ring_id + 2.25 * wire_d;
cell_spacing_y_factor = (ring_id + 2.25 * wire_d) / 2; 
layer_spacing_z = ring_id; // Z-distance between centers of layers
intra_cell_pair_offset_x = cell_spacing_x / 2;
intra_cell_pair_offset_y = (ring_id / 2) - (wire_d * 0.75);
linker_base_offset_x = -wire_d * 1.25;
linker_base_offset_y = ring_id * 0.75;
linker_base_offset_z = ring_id / 2; 
linker_alt_translate_x_offset = -wire_d * 0.75; 
linker_alt_translate_y_offset = -wire_d * 1.5; 

cell_ring1_rot_x = 45;  
cell_ring2_rot_x = -45; 
linker_rot_x_angle = -20; 
linker_rot_y_angle = 90;  

// ─── DERIVED EXTENT PARAMETERS (for base plate sizing) ───────────────
_x_coords_cells1 = [for (x_idx = [0:cols-1]) x_idx * cell_spacing_x];
_x_coords_cells2 = [for (x_idx = [0:cols-1]) x_idx * cell_spacing_x + intra_cell_pair_offset_x];
_x_coords_linkers_even = (rows > 0 && stacks > 0) ? [linker_base_offset_x] : []; 
_x_coords_linkers_odd = (rows > 0 && stacks > 1) ? [linker_base_offset_x + (rows * cell_spacing_x + linker_alt_translate_x_offset)] : []; 

_all_x_centers = concat(_x_coords_cells1, _x_coords_cells2, _x_coords_linkers_even, _x_coords_linkers_odd);
_min_center_x = (len(_all_x_centers) > 0) ? min(_all_x_centers) : 0;
_max_center_x = (len(_all_x_centers) > 0) ? max(_all_x_centers) : 0;

_y_coords_cells1 = [for (y_idx = [0:rows-1]) y_idx * cell_spacing_y_factor];
_y_coords_cells2 = [for (y_idx = [0:rows-1]) y_idx * cell_spacing_y_factor + intra_cell_pair_offset_y];
_y_linker_indices = [for (y_idx = [0 : max(0, rows - 2)]) y_idx]; 

_y_coords_linkers_even = (len(_y_linker_indices) > 0 && stacks > 0) ? [for (y_idx = _y_linker_indices) linker_base_offset_y + y_idx * cell_spacing_y_factor] : [];
_y_coords_linkers_odd = (len(_y_linker_indices) > 0 && stacks > 1) ? [for (y_idx = _y_linker_indices) (linker_base_offset_y + y_idx * cell_spacing_y_factor) + linker_alt_translate_y_offset] : [];

_all_y_centers = concat(_y_coords_cells1, _y_coords_cells2, _y_coords_linkers_even, _y_coords_linkers_odd);
_min_center_y = (len(_all_y_centers) > 0) ? min(_all_y_centers) : 0;
_max_center_y = (len(_all_y_centers) > 0) ? max(_all_y_centers) : 0;

_ring_outer_radius_from_center = ring_id/2 + wire_d; // Max extent of ring material from its center if laid flat

_plate_actual_min_x = _min_center_x - _ring_outer_radius_from_center;
_plate_actual_max_x = _max_center_x + _ring_outer_radius_from_center;
_plate_actual_min_y = _min_center_y - _ring_outer_radius_from_center;
_plate_actual_max_y = _max_center_y + _ring_outer_radius_from_center;

base_plate_final_width  = _plate_actual_max_x - _plate_actual_min_x + 2 * base_plate_margin;
base_plate_final_depth  = _plate_actual_max_y - _plate_actual_min_y + 2 * base_plate_margin;
base_plate_final_center_x = _plate_actual_min_x + base_plate_final_width/2 - base_plate_margin;
base_plate_final_center_y = _plate_actual_min_y + base_plate_final_depth/2 - base_plate_margin;


// ─── HELPER FUNCTIONS FOR Z EXTENTS ───────────
// Lowest Z of a cell ring (center at Z=0) rotated by angle_x.
// R_major = (id+wd)/2, r_minor = wd/2. Lowest Z = -(R_major*|sin(angle_x)| + r_minor)
function get_cell_ring_lowest_z_rel(id, wd, angle_x) = 
    -( ((id+wd)/2)*abs(sin(angle_x)) + (wd/2) );

// Highest Z of a cell ring (center at Z=0) rotated by angle_x.
// Highest Z = R_major*|sin(angle_x)| + r_minor
function get_cell_ring_highest_z_rel(id, wd, angle_x) = 
    ( ((id+wd)/2)*abs(sin(angle_x)) + (wd/2) );

// Y-offset for support contact on a cell ring.
function get_cell_ring_contact_y_offset(id, wd, angle_x) =
    (sin(angle_x) > 0 ? -((id+wd)/2)*cos(angle_x) : 
        (sin(angle_x) < 0 ? ((id+wd)/2)*cos(angle_x) : 0) );

// Z extent of a linker ring relative to its center after rotations.
// After rotate([linker_rot_x_angle, 90, 0]), the ring is on its side.
// Its Z extent relative to its center is +/- (ring_id/2 + wire_d).
_linker_z_extent_rel = (ring_id/2 + wire_d);


// ─── MODULES ─────────────────────────────────────────────────
module ring(id = ring_id, wd = wire_d) {
    rotate_extrude($fn=$fn) 
        translate([ (id + wd)/2 , 0, 0 ]) 
            circle(d = wd, $fn=$fn); 
}

module conditional_mirror(condition = true, v = [1, 0, 0]) {
    if (condition) { mirror(v) children(); } 
    else { children(); }
}

module cell(x_idx, y_idx, z_idx) {
    odd_z = z_idx % 2 == 1;
    translate([x_idx * cell_spacing_x, 
               y_idx * cell_spacing_y_factor, 
               z_idx * layer_spacing_z]) {
        conditional_mirror(odd_z, [0,0,1]) {
            rotate([cell_ring1_rot_x, 0, 0]) ring(); 
            translate([intra_cell_pair_offset_x, intra_cell_pair_offset_y, 0])
            rotate([cell_ring2_rot_x, 0, 0]) ring(); 
        }
    }
}

module linker(y_idx, z_idx) {
    odd_z = z_idx % 2 == 1;
    translate([linker_base_offset_x, 
               linker_base_offset_y + y_idx * cell_spacing_y_factor, 
               linker_base_offset_z + z_idx * layer_spacing_z]) {
        if(!odd_z) { 
            rotate([linker_rot_x_angle, linker_rot_y_angle, 0]) ring();
        } else { 
            translate([rows * cell_spacing_x + linker_alt_translate_x_offset, 
                       linker_alt_translate_y_offset, 0]) 
            rotate([linker_rot_x_angle, linker_rot_y_angle, 0]) ring();
        }
    }
}

module chainmail_rings(r = rows, c = cols, s = stacks) {
    if (r > 0 && c > 0 && s > 0) { 
        for (z = [0 : s - 1]) {
            for (y = [0 : r - 1]) {
                union() { 
                    if (z != s - 1 && y != r - 1) { linker(y, z); } // Linkers up to stack s-2
                    for (x = [0 : c - 1]) { cell(x, y, z); } // Cells up to stack s-1
                }
            }
        }
    }
}

module support_pillar(target_x, target_y, pillar_bottom_z, pillar_top_z, diameter) {
    height = pillar_top_z - pillar_bottom_z;
    if (height > 0.001) { 
        translate([target_x, target_y, pillar_bottom_z + height/2])
            cylinder(h = height, d = diameter, center=true, $fn=max(6,$fn/2)); 
    }
}

module full_chainmail_assembly(r = rows, c = cols, s = stacks) {
    chainmail_rings(r, c, s);

    if ((add_base_plate_and_supports || add_side_walls) && r > 0 && c > 0 && s > 0) {
        // --- Calculate Overall Z Extents of the Model ---
        // Lowest Z for a cell ring at z_idx=0
        _lowest_z_cell_abs = get_cell_ring_lowest_z_rel(ring_id, wire_d, cell_ring1_rot_x); 
        
        // Lowest Z for a linker ring at z_idx=0 (if s > 1)
        _lowest_z_linker_abs = (s > 1) ? (0 * layer_spacing_z + linker_base_offset_z - _linker_z_extent_rel) : _lowest_z_cell_abs;
        
        _overall_lowest_z_of_model = min(_lowest_z_cell_abs, _lowest_z_linker_abs);
        
        // Highest Z for a cell ring at top stack (s-1)
        _highest_z_cell_abs = (s-1)*layer_spacing_z + get_cell_ring_highest_z_rel(ring_id, wire_d, cell_ring1_rot_x);

        // Highest Z for a linker ring at its top stack (s-2, if s > 1)
        _highest_z_linker_abs = (s > 1) ? ((s-2)*layer_spacing_z + linker_base_offset_z + _linker_z_extent_rel) : -1e9; // Large negative if no linkers
                                     
        _overall_highest_z_of_model = (s > 1) ? max(_highest_z_cell_abs, _highest_z_linker_abs) : _highest_z_cell_abs;


        // --- Base Plate ---
        base_plate_top_surface_z = _overall_lowest_z_of_model - base_plate_gap;
        if (add_base_plate_and_supports) {
            actual_base_plate_center_z = base_plate_top_surface_z - base_plate_thickness / 2;
            translate([base_plate_final_center_x, base_plate_final_center_y, actual_base_plate_center_z])
                cube([base_plate_final_width, base_plate_final_depth, base_plate_thickness], center=true);
        
            // --- Supports for the bottom layer (z_idx = 0) ---
            _contact_y_offset_cell1 = get_cell_ring_contact_y_offset(ring_id, wire_d, cell_ring1_rot_x);
            _contact_y_offset_cell2 = get_cell_ring_contact_y_offset(ring_id, wire_d, cell_ring2_rot_x);

            for (y_idx = [0 : r - 1]) {
                for (x_idx = [0 : c - 1]) {
                    cell_base_x = x_idx * cell_spacing_x; 
                    cell_base_y = y_idx * cell_spacing_y_factor;
                    
                    support_pillar(cell_base_x, cell_base_y + _contact_y_offset_cell1,
                                   base_plate_top_surface_z, _lowest_z_cell_abs, support_diameter);
                    support_pillar(cell_base_x + intra_cell_pair_offset_x, 
                                   cell_base_y + intra_cell_pair_offset_y + _contact_y_offset_cell2,
                                   base_plate_top_surface_z, _lowest_z_cell_abs, support_diameter);
                }
            }

            if (s > 1) { // Linker supports only if linkers exist at z=0
                for (y_idx = [0 : r - 1]) {
                    if (y_idx != r - 1) { 
                        linker_actual_center_x = linker_base_offset_x;
                        linker_actual_center_y = linker_base_offset_y + y_idx * cell_spacing_y_factor;
                        support_pillar(linker_actual_center_x, linker_actual_center_y, /* Y offset for linker support is 0 */
                                       base_plate_top_surface_z, 
                                       (0 * layer_spacing_z + linker_base_offset_z - _linker_z_extent_rel), // Lowest Z of linker at z=0
                                       support_diameter);
                    }
                }
            }
        }
        
        // --- Side Walls ---
        if (add_side_walls) {
            wall_actual_height = _overall_highest_z_of_model + wall_height_extension - base_plate_top_surface_z;
            wall_center_z = base_plate_top_surface_z + wall_actual_height / 2;

            // Wall at Min X
            translate([base_plate_final_center_x - base_plate_final_width/2 + wall_thickness/2, 
                       base_plate_final_center_y, 
                       wall_center_z])
                cube([wall_thickness, base_plate_final_depth, wall_actual_height], center=true);

            // Wall at Max X
            translate([base_plate_final_center_x + base_plate_final_width/2 - wall_thickness/2, 
                       base_plate_final_center_y, 
                       wall_center_z])
                cube([wall_thickness, base_plate_final_depth, wall_actual_height], center=true);
        }
    }
}

// ─── RENDER ─────────────────────────────────────────────────-
full_chainmail_assembly(r = rows, c = cols, s = stacks);
