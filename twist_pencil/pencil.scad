$fa=5;
$fs=0.4;

lead_d = 2;
lead_l = 130;

// external parameters
r_in = 5.5;
r_out = 7;
r_cut = 16;

inner_nut_len = 8;
inner_ext_len = 4;
back_ins_len = 5;

len_tot = lead_l + inner_nut_len + back_ins_len - (inner_ext_len + 4);


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

function twist(a) = 35 * sin(-a*3/4);

s_tran = 0.5;
x1 = acos(-s_tran);
y1 = sin(x1);
echo("x1",x1);
function scale(a) = 1.0 + 0.4*( (a < x1) ? sin(a) : y1*exp(-PI/180*s_tran/y1*(a-x1)) );

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
th_max_d = (r_in - 0.6)*2;
th_min_d = th_max_d - 1.4;
th_step = 4;

module main_thread(height=10, delta=0){
    cylinder(h=height, d = th_min_d+delta, $fn=360/$fa);
    
    intersection(){
        translate([0,0,-th_step])
        twist(th_min_d+delta-0.05, th_max_d+delta, th_step, th_step/4, height);
        
        cylinder(h=height, d = th_max_d+delta, $fn=360/$fa);
    }
}
//main_thread(height=len_tot, delta=0.1);

// inner nut
cut_width = 0.8 * th_min_d/2;
cut_guide_th = 1.6;

module inner_nut_cut(delta=0){
    difference(){
        translate([-th_max_d, -(cut_width + 2*delta)/2, -0.1])
        cube([th_max_d*2, cut_width + 2*delta, inner_nut_len+0.2]);
        
        translate([0,0,-0.5])
        cylinder(h=inner_nut_len+1, r=th_min_d/2 - cut_guide_th - delta);
    }
}

module inner_nut(){
    difference(){
        main_thread(height=inner_nut_len, delta=-0.1);
        
        inner_nut_cut(0.1);
        
        // bottom slot for screwdriver
        cube([0.8, 4.5, 3.2], center=true);
    }
    
    translate([0,0,inner_nut_len-0.05])
    difference(){
        cylinder(h=inner_ext_len+1, d1=th_min_d - 2*cut_guide_th - 0.3, d2=lead_d+0.9);
        
        // hole to hold the lead
        translate([0,0,1.1])
        cylinder(h=inner_ext_len, d1=lead_d-0.3, d2=lead_d+0.3);
    }
}
//inner_nut();

// inner guides
module g_sec(delta=0.0){
    intersection(){
        circle(d=th_min_d+delta);
        
        difference(){
            translate([-th_max_d, -(cut_width + 2*delta)/2, 0])
            square([th_max_d*2, cut_width + 2*delta]);
            
            circle(r=th_min_d/2 - cut_guide_th - delta);
        }
    }
}
//g_sec();

module inner_g_latch(delta=0){
    l_h_b = (th_max_d-th_min_d)/2 + 0.8;
    cylinder(h=l_h_b+0.02, d1=th_min_d + delta, d2=th_max_d+0.8*2 + delta);
    translate([0,0,l_h_b])
    cylinder(h=1, d=th_max_d+0.8*2 + delta);
}

module inner_guide(){
    // stabilizing ring
    difference(){
        cylinder(h=1, d=th_min_d-0.1);
        
        translate([0,0,-0.1])
        cylinder(h=2, d=th_min_d - 2*cut_guide_th);
        
        translate([-(th_min_d+1)/2, cut_width/2 - 0.1, -0.2])
        cube([th_min_d+1, th_min_d+1, 2]);
    }
    
    difference(){
        union(){
            // long guide bars
            linear_extrude(len_tot, twist=0)
            g_sec(-0.1);
            
            // latch
            translate([0,0,lead_l + inner_nut_len]){
                intersection(){
                    inner_g_latch(-0.1);
                    inner_nut_cut(-0.1);
                }
            }
        }
        // shift by extra 0.6
        translate([0,0,lead_l + inner_nut_len + 0.6])
        back_nut_thread(back_ins_len+0.1, delta=0);
    }
}
//inner_guide();

// back nut thread parameters
bn_th_min_d = th_min_d - 2*cut_guide_th;
bn_th_max_d = bn_th_min_d + 1.4;
bn_th_step = 1.6;

module back_nut_thread(height=10, delta=0){
    min_d = bn_th_min_d;
    max_d = bn_th_max_d;
    step = bn_th_step;
    
    cylinder(h=height, d = min_d+delta, $fn=360/$fa);
    
    intersection(){
        translate([0,0,-step])
        twist(min_d+delta-0.05, max_d+delta, step, step/4, height);
        
        cylinder(h=height, d = max_d+delta, $fn=360/$fa);
    }
}
//back_nut_thread(10, -0.1);

module main_body(with_thread=true){
    difference(){
        union(){
            intersection(){
                out_iter();
                cylinder(h=len_tot+1, r1=r_in, r2=len_tot*0.3);
            }
            // donut extension
            translate([0,0,lead_l + inner_nut_len + back_ins_len/2])
            rotate_extrude()
            translate([r_out-(back_ins_len/2),0,0])
            circle(r=back_ins_len/2);
        }
        // thread makes rendering very slow, parametrize for testing
        if (with_thread) {
            translate([0,0,-0.05])
            intersection(){
                main_thread(height=len_tot+0.1, delta=0.1);
                cylinder(h=len_tot+1, r1=th_min_d/2, r2=len_tot);
            }
        }
        
        // latch cut out
        translate([0,0,lead_l + inner_nut_len]){
            inner_g_latch(0.1);
            
            translate([0,0,(th_max_d-th_min_d)/2+0.5])
            cylinder(h=back_ins_len, d=th_max_d+0.1);
        }
    }
    
    // tip
    translate([0,0,-(inner_ext_len+2)]){
        difference(){
            cylinder(h=inner_ext_len+2+0.02, d1=lead_d+0.8, d2=r_in*2);
            
            translate([0,0,-0.1])
            cylinder(h=2.2, d=lead_d+0.2);
            
            translate([0,0,2])
            cylinder(h=inner_ext_len+0.05, d1=lead_d+1.2, d2=th_min_d+0.2);
            
            translate([0,0,1.6])
            cylinder(h=0.41, d1=lead_d+0.3, d2=lead_d+1.2);
        }
    }
}
//main_body();

// test
//intersection(){
//    main_body();
//    
//    translate([0,0,-20])
//    cube(200);
//}


r_top = r_out;
r_bot = bn_th_max_d/2 + 1.6;
r_b = r_out * 1.2;
h_top = sqrt(r_b^2 - r_top^2);
h_bot = sqrt(r_b^2 - r_bot^2);

module twist_ball(){ 
    intersection(){
        translate([0,0,-h_top])
        sphere(r_b);
        
        translate([0,0,-(h_top+h_bot)])
        cylinder(h=h_top+h_bot, r=r_b+1);
    }
}

module knob(){
    guide_back_depth = back_ins_len - ((th_max_d-th_min_d)/2 + 0.8 +1);
    
    difference(){
        union(){
            cylinder(h=guide_back_depth, d=th_max_d - 0.1);
            twist_ball();
        }
        
        linear_extrude(guide_back_depth+0.3, twist=0)
        g_sec(0.1);
        
        translate([0,0,-2*r_out])
        cylinder(h=3*r_out, d=bn_th_max_d+0.1);
    }
}
//knob();

module top_screw(){
    top_thk = 1.6;
    h = top_thk + (h_top+h_bot) + back_ins_len - 1;
    back_nut_thread(height=h, delta=-0.1);
    cylinder(h=top_thk, r1=r_bot-1, r2=r_bot);
}
//top_screw();
