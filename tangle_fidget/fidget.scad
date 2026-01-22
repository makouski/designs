$fa=1;
$fs=0.2;

cyl_d = 12;
cyl_R = 24;
shave_frac = 0.95;


// pin_inner_full();
segment();

max_pin_d = cyl_d * shave_frac - (1.4) * 2;

module segment(){
    intersection(){
        difference(){
            // curved segment
            rotate_extrude(angle=90){
                translate([cyl_R, 0, 0])
                circle(d=cyl_d);
            }
            // cut outs
            translate([cyl_R, -0.05, 0])
            rotate([-90,0,0])
            pin_outer(0.3);
            
            translate([-0.05, cyl_R, 0])
            rotate([0,90,0])
            pin_outer(0.3);
        }
        // shave sides
        cube([4*cyl_R, 4*cyl_R, cyl_d * shave_frac], center=true);
    }
}
//segment();

// pin parameters
pin_tot_h = cyl_d * 0.7;
pin_ext = 0.6;
pin_inner_d = max_pin_d - pin_ext*2;

module pin_inner(){
    intersection(){
        difference(){
            pin_outer();
            // central slot
            hull(){
                translate([0,0,pin_tot_h*0.4])
                rotate([90,0,0])
                cylinder(h=2*pin_inner_d, d=pin_ext*4, center=true);
                
                translate([0,0,pin_tot_h])
                rotate([90,0,0])
                cylinder(h=2*pin_inner_d, d=pin_ext*2, center=true);
            }
            
            // circular cut out
            translate([0,0,pin_tot_h - (max_pin_d - pin_inner_d)*1.4 - pin_ext/2])
            difference(){
                cylinder(h=max_pin_d - pin_inner_d, 
                    d1=pin_inner_d+pin_ext*0.3, d2=pin_inner_d - pin_ext*2);
                
                cylinder(h=max_pin_d - pin_inner_d, 
                    d1=pin_inner_d-pin_ext*2, d2=pin_inner_d - pin_ext*3);
            }
        }
    
        cube([2*max_pin_d, pin_inner_d*0.9, 3*pin_tot_h], center=true);
    }
}
// pin_inner();

module pin_inner_full(){
    rotate([90,0,0]){
        pin_inner();
        mirror([0,0,1])
        pin_inner();
    }
}
// pin_inner_full();

module pin_outer(dd=0.0){
    tot_h = dd + pin_tot_h;
    inner_d = dd + pin_inner_d;
    
    rotate([180,0,0])
    translate([0,0,-tot_h]){
        cylinder(h=tot_h, d=inner_d);
        cylinder(h=(dd+max_pin_d - inner_d), d1=inner_d, d2=dd+max_pin_d);
        translate([0,0,(dd+max_pin_d - inner_d)])
        cylinder(h=(dd+max_pin_d - inner_d)/2, d2=inner_d, d1=dd+max_pin_d);
    }
}

// pin_outer(0.4);
