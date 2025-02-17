$fa=5;
$fs=0.4;

lead_d = 2;
lead_l = 130;

// external shape parameters
r_in = 4.5;
r_out = 5.6;
r_cut = 14;

inner_thread_len = 20;

len_tot = lead_l + inner_thread_len/2;

//// all parts with preferred orientation ////

//rotate([180,0,0]) main_body();

//translate([0, 0,0]) rotate([0,90,0]) rotate([0,0,30]) inner_clamp_slice(n=0);
//translate([0,10,0]) rotate([0,90,0]) rotate([0,0,30]) inner_clamp_slice(n=1);
//translate([0,20,0]) rotate([0,90,0]) rotate([0,0,30]) inner_clamp_slice(n=2);

//rotate([180,0,0]) top_knob();

//////////////////////////////////////////////

// 2D cross section
module sec(scale=1.0, turn=0.0) {
    scale([scale, scale, 1.0])
    rotate([0,0,turn])
    intersection() {
        circle(r=r_out);
        
        translate([-(r_cut-r_in), 0, 0])
        circle(r=r_cut);
        
        rotate([0,0,120])
        translate([-(r_cut-r_in), 0, 0])
        circle(r=r_cut);
        
        rotate([0,0,-120])
        translate([-(r_cut-r_in), 0, 0])
        circle(r=r_cut);
    }
}

//sec();

function twist(a) = 30 * sin(-a*3/4);

s_tran = 0.5;
x1 = acos(-s_tran);
y1 = sin(x1);
echo("x1",x1);
function scale(a) = 1.0 + 0.3*( (a < x1) ? sin(a) : y1*exp(-PI/180*s_tran/y1*(a-x1)) );

// parameters of recursive loop
max_phase = 360;
phase_step = 5;
module out_iter(scale=1.0, turn=0.0, phase=0) {
    if(phase < max_phase){
        p_2 = phase + phase_step;
        
        dt=twist(p_2) - twist(phase);
        ds=scale(p_2) / scale(phase);
        
        translate([0,0,len_tot*phase/max_phase])
        linear_extrude(len_tot*phase_step/max_phase, twist=-dt, scale=ds){
            sec(scale, turn);
        }
        
        // continue iterations
        out_iter(scale(p_2), twist(p_2), p_2);
    }
}
//out_iter();


// generic thread
function rot_shift_pt(p, a, c) = [
    p.x*cos(a) - p.y*sin(a), 
    p.x*sin(a) + p.y*cos(a),
    p.z + a*c
];
// rotation of triangular profile
module twist(d_in, d_out, step, tip, len_tot){
    w = step - tip;
    tan_ang = (w - tip) / (d_out - d_in);
    angs = [ 0 : $fa : 360 * (step + len_tot) / step ];
    profile = [ [d_in/2, 0, 0], [d_in/2, 0, w], [(w/2)/tan_ang + d_in/2, 0, w/2] ];
    points = [ for(a = angs) for(ii = [0 : 2]) rot_shift_pt(profile[ii], a, step/360) ];
    len_angs = len(points) / 3;
    i_max = len(points) - 1;
    faces = concat([ [0, 1, 2], [i_max, i_max - 1, i_max - 2] ],
        [ for(i = [0 : len_angs - 2]) [1 + 3*i, 1 + 3*(i+1), 2 + 3*(i+1), 2 + 3*i] ],
        [ for(i = [0 : len_angs - 2]) [3*i, 2 + 3*i, 2 + 3*(i+1), 3*(i+1)] ],
        [ for(i = [0 : len_angs - 2]) [3*i, 3*(i+1), 1 + 3*(i+1), 1 + 3*i] ]
    );
    polyhedron(points=points, faces=faces, convexity=10);
}
//twist(10, 12, 3.0, 1, 50);

// thread parameters
th_max_d = (r_in - 0.8)*2;
th_min_d = th_max_d - 2.2;
th_step = 3;

module main_thread(height=10, delta=0){
    cylinder(h=height, d = th_min_d+delta, $fn=360/$fa);
    
    intersection(){
        translate([0,0,-th_step])
        twist(th_min_d+delta-0.05, th_max_d+delta, th_step, th_step/4, height);
        
        cylinder(h=height, d = th_max_d+delta, $fn=360/$fa);
    }
}
//main_thread(height=inner_thread_len, delta=0);

module main_sliding_cone(){
    cylinder(h=inner_thread_len/2, r1=r_in-0.4, r2=r_in/2);
}

module main_body(with_thread=true){
    difference(){
        union(){
            intersection(){
                out_iter();
                cylinder(h=len_tot+1, r1=r_in, r2=len_tot*0.3);
            }
            // donut extension
            translate([0,0,len_tot-5])
            rotate_extrude()
            translate([r_out-(5/2),0,0])
            circle(r=5/2);
        }
        
        // main cylindrical cut out
        translate([0,0,inner_thread_len])
        cylinder(h=len_tot, d=th_max_d+0.2);
        
        // cone cut out in the bottom
        translate([0,0,-0.1])
        cylinder(h=inner_thread_len+0.2, d1=th_max_d-2, d2=th_max_d+0.2);
        
        // main sliding cone, shift to make it tighter
        translate([0,0,-0.5])
        main_sliding_cone();
    }
    // alignment slots
    translate([-(th_max_d+0.2)/2,0,lead_l])
    cube([th_max_d/2-r_in/2-0.1, 1.4, inner_thread_len/2]);
    
    rotate([0,0,120])
    translate([-(th_max_d+0.2)/2,0,lead_l])
    cube([th_max_d/2-r_in/2-0.1, 1.4, inner_thread_len/2]);
    
    rotate([0,0,-120])
    translate([-(th_max_d+0.2)/2,0,lead_l])
    cube([th_max_d/2-r_in/2-0.1, 1.4, inner_thread_len/2]);
}
//main_body();

// test
//intersection(){
//    main_body();
//    
//    translate([0,0,-20])
//    cube(200);
//}

module inner_clamp(n=0){
    translate([0,0,lead_l])
    rotate([0,0,120*n])
    main_thread(height=inner_thread_len-1, delta=-0.1);
    
    difference(){
        union(){
            cylinder(h=lead_l, r=r_in/2);
            
            main_sliding_cone();
            // tip
            translate([0,0,-5])
            cylinder(h=5, r1=0.4+lead_d/2, r2=r_in-0.4);
        }
        
        // smaller hole
        translate([0,0,-5.1])
        cylinder(h=inner_thread_len, d=lead_d-0.1);
        
        // bigger hole, full length
        translate([0,0,inner_thread_len - 5.3])
        cylinder(h=lead_l-inner_thread_len/2, d=lead_d+0.4);
    }
}
//inner_clamp(n=0);

module inner_clamp_slice(n=0){
    difference(){
        // 120 degree slice
        intersection(){
            inner_clamp(n);
            
            rotate([0,0,60])
            translate([-r_out, 0.1, -6])
            cube([r_out*2, r_out*2, lead_l + inner_thread_len + 10]);
            
            translate([-r_out, 0.1, -6])
            cube([r_out*2, r_out*2, lead_l + inner_thread_len + 10]);
        }
        
        // cut out for alignment slot
        translate([-(th_max_d/2),0,lead_l-0.1])
        cube([th_max_d/2-r_in/2, 1.6, inner_thread_len+0.2]);
        
        // extra room to close tighter
        translate([-r_out,0,-6])
        cube([r_out, 0.4, lead_l +6]);
    }
}
//inner_clamp_slice(n=0);

r_top = r_out;
r_b = r_out * 1.3;
h_top = sqrt(r_b^2 - r_top^2);

module twist_ball(){ 
    intersection(){
        translate([0,0,-h_top])
        sphere(r_b);
        
        translate([0,0,-r_b*2])
        cylinder(h=r_b*2, r=r_b+1);
    }
}

module top_knob(){
    difference(){
        twist_ball();
        
        translate([0,0,-inner_thread_len/2])
        main_thread(height=inner_thread_len, delta=0.1);
    }
}
//top_knob();

//intersection(){
//    top_knob();
//    translate([0,0,-50])
//    cube(50);
//}
