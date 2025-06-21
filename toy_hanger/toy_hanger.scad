$fa = 5;
$fs = 1;

// joints
d_out = 18;
d_in = 10;
// beam segment
l_seg = 200;
th = 7;
wall = 2;
// number of inner segments for cross beams
n_seg=6;

// minimum table top thickness
table_top_min_th = 18;
// how deep the clamp can go under the table
table_top_depth = 15;
// clamp length
clamp_ext_len = 45;

// bigger joint for clamp
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



slide_w = th*4;
// add a little extra height
slide_h = table_top_min_th + th;
module slider_comb(delta=0){
    // parameters for 2d "comb"
    depth = wall + delta;
    w = 1.6 + delta;
    p = 1.6*2 + 0.4;
    depth_t = 0.2;
    side_t = 0.3;
    
    translate([0,0,slide_h])
    rotate([0,90,0])
    intersection(){
    cube([slide_h, depth, slide_w]);
    
    multmatrix([
        [1, 0, -side_t, 0],
        [0, 1, 0,      0],
        [0, 0, 1,      0],
    ])
    linear_extrude(slide_w)
    for(dx = [0 : p : slide_h + slide_w*side_t])
    translate([dx, 0, 0])
    polygon([[0,0], [w,0], [w + depth*depth_t, depth], [depth*depth_t, depth]]);
    }
}
//slider_comb(delta=0);

module clamp_slider(){
    slider_comb(delta=0);
    translate([0,-2*wall,0])
    cube([slide_w, 2*wall, slide_h]);
    
    hull(){
        translate([0, -2*wall, -3*wall])
        cube([slide_w, 2*wall, 3*wall]);
        
        translate([0, -2*wall + (3*wall + table_top_depth), -2*wall])
        cube([slide_w, 2*wall, 2*wall]);
    }
}
//clamp_slider();

module clamp(){
    translate([wall+0.3, 0, 0])
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
    
    difference(){
        // parts along table corner
        union(){
            x_len = clamp_ext_len + 3*wall;
            y_len = th*3 + 1;
            translate([0, 0, -wall*2])
            cube([x_len, y_len, wall*2]);
              
            translate([0, 0, -(2*wall+table_top_min_th)])
            cube([3*wall, y_len, 2*wall+table_top_min_th]);
        }
        // cut out for comb
        
        rotate([0, 0, -90])
        translate([-slide_w+0.02, -0.02, -slide_h+0.02])
        slider_comb(delta=0.3);
    }
}
//clamp();

module bolt(){
    // thread height
    h_t = 3+th*3+1+1;
    intersection(){
        union(){
            thread(h_t, delta=-0.2);
            cylinder(h=3, d=d_out);
        }
        
        translate([0,0,h_t])
        cube([d_in-1.6-0.2, d_out, h_t*3], center=true);
        
        cylinder(h=h_t, d1=h_t, d2=d_in-2);
    }
}
//rotate([0,90,90])
//bolt();

module nut(){
    difference(){
        cylinder(h=th, d=d_out, $fn=7);
        translate([0,0,-0.5])
        thread(th+1, delta=0.2);
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
    min_d = max_d - 1.6;
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