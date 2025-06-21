$fa = 4;
$fs = 0.5;

// spice bottle size
d_bot = 51;
h_bot = 114;

// walls
thck = 1.6;
wid = 7;

// curved corners
r = 5;
Rmult = 1.9;

// how many
N = 3;

// main structure
for(ix = [0 : N-1]){
    translate([ix*(d_bot+thck), 0, 0])
    two_seg();
}


// one corner
module ccorn(r, R){
    intersection(){
        square(r);
        delta = r/2 + sqrt(1/2*R^2 - 1/4*r^2);
        translate([delta, delta, 0])
        circle(r=R);
    }
}
//ccorn(r, r*Rmult);

// one arc
module arc(){
    difference(){
        ccorn(r+thck, (r+thck)*Rmult);
        translate([thck+0.02, thck+0.02, 0])
        ccorn(r, r*Rmult);
    }
}
//arc();


// main components of the basket
module four_arcs(){
    arc();
    
    translate([d_bot+thck*2, d_bot+thck*2, 0])
    rotate([0, 0, 180])
    arc();
    
    translate([d_bot+thck*2, 0, 0])
    rotate([0, 0, 90])
    arc();
    
    translate([0, d_bot+thck*2, 0])
    rotate([0, 0, -90])
    arc();
}

module four_sides(){
    translate([thck+r, 0, 0])
    square([d_bot-2*r, thck]);
    
    translate([thck+r, d_bot+thck, 0])
    square([d_bot-2*r, thck]);
    
    translate([0, thck+r, 0])
    square([thck, d_bot-2*r]);
    
    translate([d_bot+thck, thck+r])
    square([thck, d_bot-2*r]);
}

module bottom(){
    // crossed beams
    hull(){
        arc();
        
        translate([d_bot+thck*2, d_bot+thck*2, 0])
        rotate([0, 0, 180])
        arc();
    }
    
    hull(){
        translate([d_bot+thck*2, 0, 0])
        rotate([0, 0, 90])
        arc();
        
        translate([0, d_bot+thck*2, 0])
        rotate([0, 0, -90])
        arc();
    }
    
    four_sides();
}

//bottom();

// one basket
module basket(){
    linear_extrude(thck)
    bottom();
    
    linear_extrude(wid*3)
    four_arcs();
    
    linear_extrude(wid)
    four_sides();
    
    translate([0, 0, wid*2])
    linear_extrude(wid)
    four_sides();
}

//basket();

module supp_arc(){
    translate([0, d_bot/2 + thck + wid, d_bot/2 + thck + wid])
    rotate([-90, 0, -90])
    rotate_extrude(angle=90)
    translate([d_bot/2 + thck, 0, 0])
    square([wid, thck]);
}
//supp_arc();

module two_seg(){
    basket();
    
    translate([0,0,h_bot+wid*2])
    basket();
    
    // vertical supports
    cube([thck, 2*wid, h_bot+wid*5]);
    translate([d_bot+thck,0,0])
    cube([thck, 2*wid, h_bot+wid*5]);
    
    cube([wid, thck, h_bot+wid*5]);
    translate([d_bot+2*thck-wid,0,0])
    cube([wid, thck, h_bot+wid*5]);
    
    // arcs: bottom
    translate([0, wid, wid*2])
    supp_arc();
    translate([d_bot+thck, wid, wid*2])
    supp_arc();
    // arcs: top
    translate([0, wid, h_bot+wid*3])
    rotate([-90, 0, 0])
    supp_arc();
    translate([d_bot+thck, wid, h_bot+wid*3])
    rotate([-90, 0, 0])
    supp_arc();
}
//two_seg();