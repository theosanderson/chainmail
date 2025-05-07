// Chainmail generator for OpenSCAD
// -------------------------------------------------------------
// This script creates a flat sheet of inter-locking rings in the
// classic European-4-in-1 pattern, printable *in-place* on most
// FDM and resin printers.
//
// Modified to be fully parameterized and to optionally add a
// base plate, supports for the bottom layer, and side walls.
// Revision: Positioned side walls to be tight against ring extents.
// Revision: Added angled supports for linkers in layers z_idx >= 1.
// Revision: Added support_joiners between layers.
// -------------------------------------------------------------

// ─── USER-ADJUSTABLE PARAMETERS ───────────────────────────────
$fn                      = 18;      // global resolution (increase for smoother rings, min 12 for supports)
ring_id                  = 12;      // inner diameter of each ring (mm)
wire_d                   = 2.5;     // wire (ring) thickness / diameter (mm)

cols                     = 11;       // number of rings horizontally (number of 'cell' units)
rows                     = 22;       // number of rings vertically (number of 'cell' rows)
stacks                   = 4;       // number of layers in Z-direction

// Parameters for optional base plate and supports
add_base_plate_and_supports = true; // Set to true to add base and supports
base_plate_gap           = 0.5;     // Gap between lowest ring part and base plate top
base_plate_thickness     = 0.3;     // Thickness of the base plate
support_diameter         = 2*wire_d * 0.75; // Diameter of support pillars
base_plate_margin        = wire_d;  // Margin around chainmail for base plate size
angled_support_thickness = wire_d * 0.6; // Thickness of the new angled supports

// Parameters for optional side walls
add_side_walls           = true;    // Set to true to add side walls
wall_thickness           = base_plate_thickness; // Thickness of the side walls
wall_height_extension    = wire_d;  // How much walls extend above highest ring

// Parameters for new support_joiner
add_support_joiners      = true;    // Set to true to add support_joiners between layers
support_joiner_dim_x     = 4;       // mm (width of the joiner cube)
support_joiner_dim_y     = 0.4;     // mm (depth of the joiner cube)
support_joiner_dim_z     = 0.5;     // mm (height of the joiner cube, between layers)

// ─── DERIVED GEOMETRY PARAMETERS (from original parameterization) ─────
cell_spacing_x = ring_id + 2 * wire_d;
cell_spacing_y_factor = (ring_id + 2.25 * wire_d) / 2;
layer_spacing_z = ring_id*1.05; // Z-distance between centers of layers
intra_cell_pair_offset_x = cell_spacing_x / 2;
intra_cell_pair_offset_y = (ring_id / 2) - (wire_d * 0.75);
linker_base_offset_x = -wire_d * 1.25;
linker_base_offset_y = ring_id * 0.75;
linker_base_offset_z = ring_id / 2;
linker_alt_translate_x_offset = -wire_d * 0.55;
linker_alt_translate_y_offset = wire_d * 1.6;

cell_ring1_rot_x = 45;
cell_ring2_rot_x = -45;
linker_rot_x_angle = -20;
linker_rot_y_angle = 90;

// ─── DERIVED EXTENT PARAMETERS (for base plate sizing) ───────────────
_x_coords_cells1 = [for (x_idx = [0:cols-1]) x_idx * cell_spacing_x];
_x_coords_cells2 = [for (x_idx = [0:cols-1]) x_idx * cell_spacing_x + intra_cell_pair_offset_x];
// Adjusted linker x-coord generation to reflect their actual conditional placement
_x_coords_linkers_even_z_layers = (rows > 0 && cols > 0 && stacks > 0) ? [linker_base_offset_x] : [];
_x_coords_linkers_odd_z_layers = (rows > 0 && cols > 0 && stacks > 1) ? [linker_base_offset_x + (cols * cell_spacing_x + linker_alt_translate_x_offset)] : [];


_all_x_centers = concat(
    _x_coords_cells1,
    _x_coords_cells2,
    flatten([for (z_idx = [0:stacks-2]) z_idx % 2 == 0 ? _x_coords_linkers_even_z_layers : _x_coords_linkers_odd_z_layers])
);

_min_center_x = (len(_all_x_centers) > 0) ? min(_all_x_centers) : 0;
_max_center_x = (len(_all_x_centers) > 0) ? max(_all_x_centers) : 0;

_y_coords_cells1 = [for (y_idx = [0:rows-1]) y_idx * cell_spacing_y_factor];
_y_coords_cells2 = [for (y_idx = [0:rows-1]) y_idx * cell_spacing_y_factor + intra_cell_pair_offset_y];
_y_linker_indices = [for (y_idx = [0 : max(0, rows - 2)]) y_idx];

// Adjusted linker y-coord generation for clarity
_y_coords_linkers_base = (len(_y_linker_indices) > 0 && stacks > 0) ? [for (y_idx = _y_linker_indices) linker_base_offset_y + y_idx * cell_spacing_y_factor] : [];
_y_coords_linkers_alt_offset = (len(_y_linker_indices) > 0 && stacks > 1) ? [for (y_idx = _y_linker_indices) (linker_base_offset_y + y_idx * cell_spacing_y_factor) + linker_alt_translate_y_offset] : [];


_all_y_centers = concat(
    _y_coords_cells1,
    _y_coords_cells2,
    flatten([for (z_idx = [0:stacks-2]) z_idx % 2 == 0 ? _y_coords_linkers_base : _y_coords_linkers_alt_offset])
);
_min_center_y = (len(_all_y_centers) > 0) ? min(_all_y_centers) : 0;
_max_center_y = (len(_all_y_centers) > 0) ? max(_all_y_centers) : 0;

_ring_outer_radius_from_center = ring_id/2 + wire_d; // Max extent of ring material from its center if laid flat

// Actual extents of the chainmail rings themselves
_plate_actual_min_x = _min_center_x - _ring_outer_radius_from_center*0.75;
_plate_actual_max_x = _max_center_x + _ring_outer_radius_from_center*0.75;
_plate_actual_min_y = _min_center_y - _ring_outer_radius_from_center*0.75;
_plate_actual_max_y = _max_center_y + _ring_outer_radius_from_center*0.75;

// Base plate dimensions including margin
base_plate_final_width    = _plate_actual_max_x - _plate_actual_min_x + 2 * base_plate_margin;
base_plate_final_depth    = _plate_actual_max_y - _plate_actual_min_y + 2 * base_plate_margin;
base_plate_final_center_x = (_plate_actual_min_x + _plate_actual_max_x)/2; // Center of the actual rings
base_plate_final_center_y = (_plate_actual_min_y + _plate_actual_max_y)/2; // Center of the actual rings


// ─── HELPER FUNCTIONS FOR Z EXTENTS ───────────
function get_cell_ring_lowest_z_rel(id, wd, angle_x) =
    -( ((id+wd)/2)*abs(sin(angle_x)) + (wd/2) );

function get_cell_ring_highest_z_rel(id, wd, angle_x) =
    ( ((id+wd)/2)*abs(sin(angle_x)) + (wd/2) );

function get_cell_ring_contact_y_offset(id, wd, angle_x) =
    (sin(angle_x) > 0 ? -((id+wd)/2)*cos(angle_x) :
        (sin(angle_x) < 0 ? ((id+wd)/2)*cos(angle_x) : 0) );

_linker_z_extent_rel = (ring_id/2 + wire_d);


// ─── MODULES ─────────────────────────────────────────────────
module ring(id = ring_id, wd = wire_d) {
    rotate_extrude($fn=$fn)
        translate([ (id + wd)/2 , 0, 0 ])
            circle(d = wd, $fn=6);
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
    odd_z = z_idx % 2 == 1; // This refers to the z_idx of the layer this linker belongs to.
    translate([linker_base_offset_x,
               linker_base_offset_y + y_idx * cell_spacing_y_factor,
               linker_base_offset_z + z_idx * layer_spacing_z]) {
        if(!odd_z) { // Even layer linkers (0, 2, ...)
            rotate([linker_rot_x_angle, linker_rot_y_angle, 0]) ring();
        } else { // Odd layer linkers (1, 3, ...) - these are the "alternate" ones
            translate([cols * cell_spacing_x + linker_alt_translate_x_offset,
                       linker_alt_translate_y_offset, 0])
            rotate([-linker_rot_x_angle, linker_rot_y_angle, 0]) ring();
        }
    }
}

module chainmail_rings(r = rows, c = cols, s = stacks) {
    if (r > 0 && c > 0 && s > 0) {
        for (z = [0 : s - 1]) {
            for (y = [0 : r - 1]) {
                union() {
                    // Linkers connect layer z to z+1. So max z for linkers is s-2.
                    if (z < s - 1 && y < r - 1) { linker(y, z); }
                    for (x = [0 : c - 1]) { cell(x, y, z); }
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

// NEW MODULE for support_joiner
module support_joiner() {
    cube([support_joiner_dim_x, support_joiner_dim_y, support_joiner_dim_z], center=true);
}

// NEW MODULE for angled supports
module angled_support_beam(contact_x, contact_y, contact_z, from_min_x_side, thickness,
                           plate_min_x, plate_max_x, current_wall_thickness, base_z_level, use_walls, margin_if_no_walls) {

    // Determine the X-plane from which the support originates horizontally
    // This is the inner surface of the conceptual wall
    wall_plane_x = from_min_x_side ?
                   (plate_min_x - (use_walls ? 0 : margin_if_no_walls) ) :
                   (plate_max_x + (use_walls ? 0 : margin_if_no_walls) );

    // Initial horizontal distance from contact point to wall plane
    delta_h_initial = abs(contact_x - wall_plane_x);
    // For a 45-degree angle, vertical distance equals horizontal distance
    delta_z_initial = delta_h_initial;

    // Calculate the Z coordinate of the support's base
    support_base_z_calculated = contact_z - delta_z_initial;

    // Ensure the support base doesn't go below the defined base_z_level (e.g., top of base plate)
    actual_support_base_z = max(support_base_z_calculated, base_z_level);

    // Recalculate delta_z based on the actual starting Z (if it was capped)
    actual_delta_z = contact_z - actual_support_base_z;

    // To maintain a 45-degree angle, actual_delta_h must equal actual_delta_z
    actual_delta_h = actual_delta_z;

    // Recalculate the support's X base position based on the new actual_delta_h
    actual_support_base_x = from_min_x_side ?
                            (contact_x - actual_delta_h) :
                            (contact_x + actual_delta_h);

    length = sqrt(pow(actual_delta_h, 2) + pow(actual_delta_z, 2));
    angle_y_rot = from_min_x_side ? 45 : -45; // Rotates around Y axis

    // Only create support if it has a positive length and height
    if (length > 0.01 && actual_delta_z > 0.01) {
        translate([ (actual_support_base_x + contact_x) / 2,
                    contact_y,
                    (actual_support_base_z + contact_z) / 2 ])
        rotate([0, -angle_y_rot, 0])
        cube([length, thickness, thickness], center=true);
    }
}


module full_chainmail_assembly(r = rows, c = cols, s = stacks) {
    chainmail_rings(r, c, s);

    if ((add_base_plate_and_supports || add_side_walls || add_support_joiners) && r > 0 && c > 0 && s > 0) {
        // --- Calculate Overall Z Extents of the Model ---
        // Adjusted _lowest_z_cell_abs to be slightly less aggressive for robustness
        _lowest_z_cell_abs = get_cell_ring_lowest_z_rel(ring_id, wire_d, cell_ring1_rot_x) + wire_d*0.1; // Was +0.2
        
        _lowest_z_linker_abs = (s > 1) ? (linker_base_offset_z - _linker_z_extent_rel) : _lowest_z_cell_abs;
        _overall_lowest_z_of_model = min(_lowest_z_cell_abs, _lowest_z_linker_abs);

        _highest_z_cell_abs = (s-1)*layer_spacing_z + get_cell_ring_highest_z_rel(ring_id, wire_d, cell_ring1_rot_x);
        _highest_z_linker_abs = (s > 1 && s-2 >=0) ? ((s-2)*layer_spacing_z + linker_base_offset_z + _linker_z_extent_rel) : -1e9;
        _overall_highest_z_of_model = (s > 1 && s-2 >=0) ? max(_highest_z_cell_abs, _highest_z_linker_abs) : _highest_z_cell_abs;

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

            // Linker supports for z_idx = 0 (connecting layer 0 to 1)
            if (s > 1) { // Linkers exist only if more than one stack
                for (y_idx = [0 : r - 2]) { // Up to r-2 for linkers
                    linker_actual_center_x = linker_base_offset_x;
                    linker_actual_center_y = linker_base_offset_y + y_idx * cell_spacing_y_factor;
                    linker_lowest_z_at_z0 = linker_base_offset_z - _linker_z_extent_rel;
                    support_pillar(linker_actual_center_x, linker_actual_center_y,
                                   base_plate_top_surface_z,
                                   linker_lowest_z_at_z0,
                                   support_diameter);
                }
            }

            // --- Angled Supports for Linkers in layers z_idx = 1 and above ---
            if (s > 2) { // Need at least 3 stacks for linkers at z_idx=1
                for (z_linker_idx = [1 : s - 2]) {
                    is_odd_linker_layer = z_linker_idx % 2 == 1;
                    for (y_idx = [0 : r - 2]) {
                        linker_center_z = linker_base_offset_z + z_linker_idx * layer_spacing_z;
                        linker_contact_z_underside = linker_center_z - _linker_z_extent_rel;

                        if (!is_odd_linker_layer) {
                            linker_contact_x = linker_base_offset_x;
                            linker_contact_y = linker_base_offset_y + y_idx * cell_spacing_y_factor;
                            angled_support_beam(linker_contact_x, linker_contact_y, linker_contact_z_underside,
                                                true, angled_support_thickness,
                                                _plate_actual_min_x, _plate_actual_max_x, wall_thickness,
                                                base_plate_top_surface_z, add_side_walls, base_plate_margin);
                        } else {
                            linker_contact_x = linker_base_offset_x + cols * cell_spacing_x + linker_alt_translate_x_offset;
                            linker_contact_y = (linker_base_offset_y + y_idx * cell_spacing_y_factor) + linker_alt_translate_y_offset;
                            angled_support_beam(linker_contact_x, linker_contact_y, linker_contact_z_underside,
                                                false, angled_support_thickness,
                                                _plate_actual_min_x, _plate_actual_max_x, wall_thickness,
                                                base_plate_top_surface_z, add_side_walls, base_plate_margin);
                        }
                    }
                }
            }
        }

        if (add_support_joiners && s > 1 && r > 0 && c > 0) {
            for (z_layer_idx = [0 : s - 2]) { // Iterate between cell layers z_layer_idx (lower) and z_layer_idx+1 (upper)
                
                // Determine the orientation of the upper layer's rings for Y-offset calculation
                upper_cell_layer_idx = z_layer_idx + 1;
                is_upper_cell_layer_mirrored = (upper_cell_layer_idx % 2 == 1);

                // Calculate effective rotation angles for contact point Y-offset determination
                // These depend on whether the upper layer (which the joiner sits below) is mirrored
                effective_ring1_rot_x_for_contact = is_upper_cell_layer_mirrored ? -cell_ring1_rot_x : cell_ring1_rot_x;
                effective_ring2_rot_x_for_contact = is_upper_cell_layer_mirrored ? -cell_ring2_rot_x : cell_ring2_rot_x;
                
                // Dynamically calculate Y offsets based on the upper layer's orientation
                joiner_contact_y_offset1 = get_cell_ring_contact_y_offset(ring_id, wire_d, effective_ring1_rot_x_for_contact);
                joiner_contact_y_offset2 = get_cell_ring_contact_y_offset(ring_id, wire_d, effective_ring2_rot_x_for_contact);

                // Z position for the center of the joiner: midway between the nominal Z-centers of the two layers
                joiner_center_z = z_layer_idx * layer_spacing_z + layer_spacing_z / 2;

                for (y_idx = [0 : r - 1]) {
                    for (x_idx = [0 : c - 1]) {
                        // Base X,Y for the cell
                        cell_base_x_for_joiner = x_idx * cell_spacing_x;
                        cell_base_y_for_joiner = y_idx * cell_spacing_y_factor;

                        // Joiner for the first ring position in the cell
                        translate([cell_base_x_for_joiner,
                                   cell_base_y_for_joiner + joiner_contact_y_offset1, // Use dynamic Y-offset
                                   joiner_center_z]) {
                            support_joiner();
                        }

                        // Joiner for the second ring position in the cell
                        translate([cell_base_x_for_joiner + intra_cell_pair_offset_x,
                                   cell_base_y_for_joiner + intra_cell_pair_offset_y + joiner_contact_y_offset2, // Use dynamic Y-offset
                                   joiner_center_z]) {
                            support_joiner();
                        }
                    }
                }
            }
        }

        // --- Side Walls ---
        if (add_side_walls) {
            wall_actual_height = _overall_highest_z_of_model + wall_height_extension - base_plate_top_surface_z;
            wall_center_z = base_plate_top_surface_z + wall_actual_height / 2;
            wall_actual_depth = base_plate_final_depth; // Use the calculated depth of the base plate

            // Wall at min X
            translate([_plate_actual_min_x - wall_thickness/2, // Positioned at the edge of actual rings
                       base_plate_final_center_y,    // Centered with the plate's Y
                       wall_center_z])
                cube([wall_thickness, wall_actual_depth, wall_actual_height], center=true);

            // Wall at max X
            translate([_plate_actual_max_x + wall_thickness/2, // Positioned at the edge of actual rings
                       base_plate_final_center_y,    // Centered with the plate's Y
                       wall_center_z])
                cube([wall_thickness, wall_actual_depth, wall_actual_height], center=true);
        }
    }
}

// Helper for flattening list of lists (if any complex list structures arise)
function flatten(l) = [for (a = l) for (b = a) b];

// ─── RENDER ─────────────────────────────────────────────────-
full_chainmail_assembly(r = rows, c = cols, s = stacks);
