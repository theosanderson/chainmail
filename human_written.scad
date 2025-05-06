// Chainmail generator for OpenSCAD
// -------------------------------------------------------------
// This script creates a flat sheet of inter‑locking rings in the
// classic European‑4‑in‑1 pattern, printable *in‑place* on most
// FDM and resin printers.
// -------------------------------------------------------------
// ─── USER‑ADJUSTABLE PARAMETERS ───────────────────────────────
$fn             = 14;      // global resolution (increase for smoother rings)
ring_id         = 10;      // inner diameter of each ring (mm)
wire_d          = 2;       // wire (ring) thickness / diameter (mm)

cols            = 3;      // number of rings horizontally
rows            = 3;      // number of rings vertically
stacks = 3;

// ─── MODULES ─────────────────────────────────────────────────
// 1️⃣  Ring — torus built with rotate_extrude so it is a true round profile.
module ring(id = ring_id, wd = wire_d)
{
    rotate_extrude()
        translate([ (id + wd)/2 , 0, 0 ])
            circle(d = wd);
}

// 2️⃣  Chainmail cell — decides orientation & placement of a single ring.

x_dist = 14.5;
y_dist = 14.5;
z_dist=10;



module conditional_mirror(condition = true, v = [1, 0, 0]) {
    
    if (condition) {
        mirror(v) children();
    }
    else{
        children();
    }
}


module cell(x, y, z)


{
    
    odd_z = z%2==1;
    
    
    translate([x*x_dist,y*y_dist/2,z*z_dist]){
        
     conditional_mirror(odd_z,[0,0,1]){
        
    rotate([45,0,0])
    ring();
   
    translate([x_dist/2,3.5,0])
        
    rotate([-45,0,0])
    ring();
     }
}
}

module linker(y,z){
    odd_z = z%2==1;
    translate([-2.5,7.5+y*y_dist/2,5+z*z_dist])
     
    
    if(!odd_z){
rotate([-20,90,0])
ring();
    }
    else{
        translate([rows*x_dist-1.5,-3,0])
        rotate([-20,90,0])
ring();
        
        
    }
    

}

// 3️⃣  Main assembly loop
module chainmail(r = rows, c = cols, s = stacks)
{
   
    for (z = [0 : s - 1])
      for (y = [0 : r - 1])
      {
          union(){
              if(z!=s-1 && y!=r-1)
          linker(y,z);
    for (x = [0 : c - 1])
      

           
       
            cell(x, y, z);
        }
        }
}

// ─── RENDER ─────────────────────────────────────────────────-
chainmail(rows, cols);


