$fa=2;
$fs=1;

r = 68 / 2;
w = 5;

// curve the corners
r_curve = 12;
r_disp = 0.85;

// calculated size of main box
H = (r+w)*3;
W = (r+w)*2 + (r+w)*sqrt(3);
D = (r+w)*4;

module outer_wall(){
    difference(){
        intersection(){
            square([r+w, r + w]);
            
            hull(){
                //translate([r_curve*r_disp, r_curve*r_disp])
                circle(r=r_curve);
                
                translate([r+w - r_curve*r_disp, r_curve*r_disp])
                circle(r=r_curve);
                
                translate([r_curve*r_disp, r+w - r_curve*r_disp])
                circle(r=r_curve);
                
                translate([r+w, r+w])
                circle(r=r_curve);
            }
        }
        
        translate([0, w + r])
        circle(r=r);
    }
    translate([r + w/2, r + w])
    circle(d = w);
}

module tray(){
    translate([W/2,0,0])
    rotate([0,0,180])
    rotate_extrude(angle=180){
        translate([W/2 - (r+w), 0, 0])
        outer_wall();
        
        square([W/2 - (r+w), w]);
    }
    
    // extension to join with the box
    rotate([90,0,0])
    translate([0,0,-2*w])
    linear_extrude(2*w){
            translate([W - (r+w), 0, 0])
            outer_wall();
            
            translate([r+w,0,0])
            mirror([1,0,0])
            outer_wall();
            
            translate([r+w,0,0])
            square([W - (r+w)*2, w]);
    }
}
//tray();

module box(){
    intersection(){
        cube([W,D,H-0.05]);
        
        hull(){
            translate([r_curve*r_disp, r_curve*r_disp, r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([W-r_curve*r_disp, r_curve*r_disp, r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([r_curve*r_disp, D-r_curve*r_disp, r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([W-r_curve*r_disp, D-r_curve*r_disp, r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([r_curve*r_disp, r_curve*r_disp, H-r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([W-r_curve*r_disp, r_curve*r_disp, H-r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([r_curve*r_disp, D-r_curve*r_disp, H-r_curve*r_disp])
            sphere(r=r_curve);
            
            translate([W-r_curve*r_disp, D-r_curve*r_disp, H-r_curve*r_disp])
            sphere(r=r_curve);
        }
        
    }
}

//box();

module channel(){
    translate([r+w, r+w+0.05, H])
    rotate([-90,0,-90])
    translate([-(r+w), 0, 0])
    rotate_extrude(angle=90){
        translate([r+w,0,0])
        circle(r=r);
    }
    
    translate([r+w, (r+w)*2, H-(r+w)])
    rotate([0,30,0])
    translate([r+w, 0, 0])
    rotate_extrude(angle=180){
        translate([r+w,0,0])
        circle(r=r);
    }
    
    translate([W-(r+w), 0, r+w])
    rotate([-90,0,0])
    translate([0,0,-0.05])
    cylinder(h=(r+w)*2 + 0.1, r=r);
}

//channel();

module all(){
    difference(){
        box();
        channel();
    }
    tray();
}
rotate([0,0,-90])
all();