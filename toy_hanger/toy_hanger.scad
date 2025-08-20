$fa = 5;
$fs = 0.5;

// joints
d_out = 18;
d_in = 10;
// beam segment:
l_seg = 200;
// width
th = 7;
// wall thickness
wall = 2;
// number of inner segments for cross beams
n_seg=6;

// maximum table top thickness
table_top_max_th = 35;
// how deep the clamp can go under the table
table_top_depth = 15;
// clamp length on top of the table
clamp_ext_len = 45;

// scale bigger joint for clamp
d_st = d_out*1.2;

module grip_ext(d_o, top) {
    h = 1;
    // connecting rim: top part outside, bottom inside
    rotate_extrude(){
        if(top){
            translate([d_o/2 - h, 0, 0])
            square([h,h]);
        } else {
            translate([d_in/2, 0, 0])
            square([h,h]);
        }
    }
    
    for(ang = [0 : 20 : 360])
    rotate([0,0,ang])
    rotate_extrude(angle = 8)
    if(top){
        translate([d_in/2 + (h+0.3), 0, 0])
        square([(d_o-d_in)/2 - (h+0.3), h]);
    } else {
        translate([d_in/2, 0, 0])
        square([(d_o-d_in)/2 - (h+0.3), h]);
    }
}
//grip_ext(d_out, top=true);
//rotate([0,0,10])
//grip_ext(d_out, top=false);

module regular_joint(d, top){
    rotate_extrude()
    translate([d_in/2, 0, 0])
    square([(d-d_in)/2, th]);
    
    translate([0, 0, th])
    grip_ext(d, top);
}


module conn_2d(r1, r2, l){
    // outside beam
    polygon([[0,r1], [l,r2], [l,r2-wall], [0,r1-wall]]);
    for(ix = [0 : n_seg-1]) {
        delta = (l-r1-r2+wall)/n_seg;
        x1 = -0.5*wall + r1 + ix*delta;
        x2 = -0.5*wall + r1 + (ix+1)*delta;
        if(ix%2 == 1) {
            y1 = r1 - x1*(r1-r2)/l - wall/2;
            y2 = wall/2;
            polygon([[x1,y1], [x2,y2], [x2,y2-wall], [x1,y1-wall]]);
        } else {
            y1 = wall/2;
            y2 = r1 - x2*(r1-r2)/l - wall/2;
            polygon([[x1,y1], [x2,y2], [x2,y2-wall], [x1,y1-wall]]);
        }
    }
}
//conn_2d(1.6*d_out/2, d_out/2, l_seg);

module conn(r1, r2, l){
    linear_extrude(th){
        conn_2d(r1, r2, l);
        mirror([0,1,0])
        conn_2d(r1, r2, l);
    }
}

module regular_arm(){
    regular_joint(d_out, top=false);
    translate([l_seg, 0, 0])
    regular_joint(d_out, top=true);
    
    conn(d_out/2, d_out/2, l_seg);
}
//regular_arm();

module start_arm(){
    regular_joint(d_st, top=false);
    translate([l_seg, 0, 0])
    regular_joint(d_out, top=true);
    
    conn(d_st/2, d_out/2, l_seg);
}
//start_arm();

module end_arm(){
    regular_joint(d_out, top=false);
    
    translate([l_seg, 0, 0])
    rotate_extrude()
    translate([d_in/4, 0, 0])
    square([d_in/4, th]);
    
    conn(d_out/2, d_in/2, l_seg);
}
//end_arm();

// clamp slider
y_len = th*3 + 1;
module clamp_slider(){
    // cut gaps for each side
    cut_x_delta = 0.2;
    cut_y_delta = 0.2;
    
    difference(){
        translate([-wall, -(1.5*wall-cut_y_delta), 0])
        {
            cube([table_top_depth+2*wall+wall, y_len+3*wall, 2*wall]);
            // round bump on the far end
            translate([table_top_depth+2*wall+wall - 1.3*wall, 0, 1.6*wall])
            rotate([-90, 0, 0])
            cylinder(h=y_len+3*wall, r=wall*1.4);
        }
        rotate([0, 6, 0])
        cube([2*wall+2*cut_x_delta, y_len+2*cut_y_delta, 5*wall]);
    }
}
//clamp_slider();

module clamp(){
    rotate([-90,0,0])
    translate([d_st/2, -d_st/2, 0]){
        regular_joint(d_st, top=true);
        difference(){
            translate([-d_st/2,0,0])
            cube([d_st, d_st/2 + 1, th]);
            
            translate([0,0,-0.5])
            cylinder(h=th+1, d=d_st-1);
        }
    }
    
    x_len = clamp_ext_len + 3*wall;
    translate([0, 0, -wall*2])
    cube([x_len, y_len, wall*2]);
      
    translate([0, 0, -(2*wall+table_top_max_th+3*wall)])
    cube([2*wall, y_len, 2*wall+table_top_max_th+3*wall]);
}
//rotate([90,0,0])
//clamp();

thread_depth = 1.6;
thread_diff = 0.3;

module bolt(){
    // thread height
    h_t = 3+th*3+1+1;
    intersection(){
        union(){
            thread(h_t, delta=-thread_diff);
            cylinder(h=3, d=d_out);
        }
        
        translate([0,0,h_t])
        cube([d_in-thread_depth-thread_diff, d_out, h_t*3], center=true);
        
        cylinder(h=h_t, d1=h_t, d2=d_in-2);
    }
}
//rotate([0,90,90])
//bolt();

module nut(){
    difference(){
        cylinder(h=th, d=d_out, $fn=7);
        translate([0,0,-0.5])
        thread(th+1, delta=thread_diff);
    }
}
//nut();


// thread
// rotate-extruded 2d shapes with slant by multmatrix //
// not a perfect rotation geometry but better rendering time for long threads

// 2D section
module vert_proj(len_tot, pitch, min_d, max_d){
    r_in = min_d/2 - 0.05;
    r_out = max_d/2;
    
    for(i = [0: floor(len_tot/pitch) + 1])
        polygon(points=[
            [r_in,  i*pitch],
            [r_in,  i*pitch + 3/4*pitch],
            [r_out, i*pitch + 2/4*pitch],
            [r_out, i*pitch + 1/4*pitch]
        ]);
}
//vert_proj(5, 0);

// rotation of 2D section by small angle
module slice_twist(len_tot, pitch, min_d, max_d, s){
    multmatrix([
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, s, 1, 0],
    ])
    rotate_extrude(angle=$fa+0.1)
    vert_proj(len_tot, pitch, min_d, max_d);
}
//slice_twist(5, 0);

module thread(len_tot, delta=0){
    max_d = d_in + delta;
    min_d = max_d - thread_depth;
    pitch = 2.4;
    
    // inner cylinder
    cylinder(h=len_tot, d=min_d, $fn=360/$fa);
    
    intersection(){
        // one revolution no matter how long the thread is
        s = pitch/(2*PI*(max_d/2));
        translate([0,0,-pitch])
        for(i = [0: (360/$fa) - 1])
            rotate([0,0,i*$fa])
            translate([0,0,i*pitch*($fa/360)])
            slice_twist(len_tot, pitch, min_d, max_d, s);
        
        cylinder(h=len_tot, d=max_d, $fn=360/$fa);
    }
}
//thread(15, 0.1);