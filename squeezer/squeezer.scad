$fa=5;
$fs=0.4;

l = 80;
w = 2;

R = 8;


module arc(){
    arc_r = 0.64*R;
    translate([-arc_r,0,0])
    rotate([90,0,0])
    rotate_extrude(angle=90){
        hull(){
            translate([arc_r,  l/2, 0])
            circle(d=w);
            translate([arc_r, -l/2, 0])
            circle(d=w);
        }
    }
}

module slot(){
    translate([0,0,-0.05])
    arc();
    rotate([0,0,180])
    mirror([0,0,1])
    arc();
}

module half_sphere(){
    intersection(){
        sphere(r=R);
        cylinder(h=R+1, r=R+1);
    }
}

module body(){
    translate([0,1 + l/2,0])
    rotate([90,0,0])
    rotate_extrude(angle=180){
        square([R, l+2], center=false);
    }
    translate([0, 1 + l/2, 0])
    half_sphere();
    translate([0,-1 - l/2, 0])
    half_sphere();
}

difference(){
    body();
    
    translate([0,0,R/2])
    slot();
}