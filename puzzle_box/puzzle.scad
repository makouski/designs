// define the maze and visually check the paths
// defines travel_ratio and paths variables
include<maze_def.scad>

// sizes
//pin height
ah = 2.5;
// pin width
a = 4;

// travel_ratio is defined with the maze
// bolts travel
d = a * travel_steps;

// bolt width (without additional borders)
w = sin(60) * d + a;
echo("w:",w);

// box height
h_b = 120;

// handle diameter with adjustment
handle_d = 0.85*sin(60)*d/2;


// all parts to print ////////////////////////////////////////////
//x_bolt();
//y_bolt();
//z_bolt();
//lid();
//lid_cover();
//all_handles();
//body_bottom_cover();
//body();
//////////////////////////////////////////////////////////////////


// translate + project
function translate_p (p, trn) = 
    (p=="x_z") ? [(trn.x + cos(60)*trn.z)*a, sin(60)*trn.z*a, 0] :
    (p=="y_x") ? [(trn.y + cos(60)*trn.x)*a, sin(60)*trn.x*a, 0] :
    (p=="z_y") ? [(trn.z + cos(60)*trn.y)*a, sin(60)*trn.y*a, 0] :
    [0,0,0];


// pin moving along x
module pin(){
    linear_extrude(ah, scale=0.1){
        intersection(){
            square([2*a, a], center=true);
            
            rotate([0,0,120])
            square([2*a, a], center=true);
            
            rotate([0,0,-120])
            square([2*a, a], center=true);
        }
    }
}
//pin();

// intermediate constants
// pin half length
pin_hl = a/(2*sin(60));

bolt_w = w + 0.8;
xy_bolt_thk =  ah +   0.8;
z_bolt_gap = 2*xy_bolt_thk + 0.1 + 0.1 + 0.1; // 0.1 for each gap
z_bolt_wall = 1.2;
z_bolt_thk =   xy_bolt_thk + z_bolt_gap + z_bolt_wall;
bolt_tot_len = d*(1 + cos(60)) + 2*pin_hl + d;
path_tot_len = d*(1 + cos(60));

lock_in_disp = tan(30)*(w-a)/2;

module path_p(proj){
    for (seg = paths){ 
        hull(){
            translate(translate_p(proj, seg[0]))
            pin();
            
            translate(translate_p(proj, seg[1]))
            pin();
        }
    }
}

module z_top_cutout(){
    translate([0,-(w-a)/2,0]){
        hull(){
            translate([-a,0,0])
            pin();
            pin();
        }
        path_p("z_y");
    }
}
//z_top_cutout();

module y_cutout(){
    translate([0,-(w-a)/2,0]){
        hull(){
            translate([-a,0,0])
            pin();
            pin();
        }
        path_p("y_x");
    }
}
//y_cutout();

// cut out in x with bottom z pin
module x_cutout(){
    translate([0,-(w-a)/2,0]){
        rotate([0,0,60])
        hull(){
            translate([-a,0,0])
            pin();
            pin();
        }
        path_p("x_z");
    }
}
//x_cutout();

// x bolt
module x_bolt(){
    translate([0, (w-a)/2, xy_bolt_thk - 0.1])
    pin();
    
    difference(){
        translate([-pin_hl, -bolt_w/2, 0.02])
        cube([bolt_tot_len, bolt_w, xy_bolt_thk]);
        
        x_cutout();
        
        translate([path_tot_len+pin_hl, 0, 0.05])
        thread(delta=0.1);
        
        // mark to distinguish x from y
        translate([bolt_tot_len-pin_hl,0,0])
        cylinder(h=0.4, d=a/2);
    }
}
//x_bolt();

module y_bolt(){
    translate([0, (w-a)/2, xy_bolt_thk - 0.1])
    pin();
    
    difference(){
        translate([-pin_hl, -bolt_w/2, 0.02])
        cube([bolt_tot_len, bolt_w, xy_bolt_thk]);
        
        y_cutout();
        
        translate([path_tot_len+pin_hl, 0, 0.05])
        thread(delta=0.1);
    }
}
//y_bolt();

module z_bolt(){
    translate([0, (w-a)/2, z_bolt_wall - 0.1])
    pin();
    
    // bottom wall
    translate([-pin_hl, -bolt_w/2, 0])
    cube([bolt_tot_len, bolt_w, z_bolt_wall]);
    
    // thick center part
    // with cut outs for x and y bolts when they move in
    difference(){
        translate([-pin_hl + path_tot_len, -bolt_w/2, z_bolt_wall - 0.02])
        cube([(bolt_tot_len - path_tot_len), bolt_w, z_bolt_gap + 0.04]);
        
        translate([d - lock_in_disp,0,z_bolt_wall-0.2])
        rotate([0,0,60])
        translate([0,-(bolt_w + 0.2)/2, 0])
        cube([2*d, bolt_w + 0.2, z_bolt_gap + 0.4]);
        
        translate([d - lock_in_disp,0,z_bolt_wall-0.2])
        rotate([0,0,-60])
        translate([0,-(bolt_w + 0.2)/2, 0])
        cube([2*d, bolt_w + 0.2, z_bolt_gap + 0.4]);
    }
    
    difference(){
        // top wall
        translate([-pin_hl, -bolt_w/2, z_bolt_thk - xy_bolt_thk])
        cube([bolt_tot_len, bolt_w, xy_bolt_thk]);
        
        translate([0,0,z_bolt_wall + z_bolt_gap - 0.02])
        z_top_cutout();
        
        // subtract thread
        translate([path_tot_len+pin_hl, 0, z_bolt_wall + z_bolt_gap + 0.05])
        thread(delta=0.1);
    }
}
//z_bolt();

// z translations of x and y bolts in assembled position
x_disp_z = z_bolt_wall + 0.1;
y_disp_z = z_bolt_wall + xy_bolt_thk + 0.1 + 0.1;

// integration test 1: initial position of all bolts
module initial_pos(){
    translate([lock_in_disp, 0, x_disp_z])
    x_bolt();

    rotate([0,0,-120])
    translate([lock_in_disp, 0, 0])
    z_bolt();

    rotate([0,0,120])
    translate([lock_in_disp, 0, y_disp_z])
    y_bolt();
}
//initial_pos();

// integration test 2: final position of all bolts
module final_pos(){
    translate([-d + lock_in_disp, 0, x_disp_z])
    x_bolt();

    rotate([0,0,-120])
    translate([-d + lock_in_disp, 0, 0])
    z_bolt();

    rotate([0,0,120])
    translate([-d + lock_in_disp, 0, y_disp_z])
    y_bolt();
}
//final_pos();

// lid and separate cover to hold moving bolts //

bolt_shift = lock_in_disp - pin_hl - d;

module z_dummy_in(extra=0){
    translate([bolt_shift, -(bolt_w+2*extra)/2, -extra])
    cube([bolt_tot_len+extra, bolt_w+2*extra, z_bolt_thk + 2*extra]);
}
//z_dummy_in(0.2);

module y_dummy_in(extra=0){
    translate([-d + lock_in_disp, (w-a)/2, y_disp_z + xy_bolt_thk + extra])
    hull(){
        translate([0, 0, -0.02])
        pin();
        
        translate([bolt_tot_len, 0, -0.02])
        pin();
    }
    translate([bolt_shift-extra, -(bolt_w+2*extra)/2, y_disp_z - extra])
    cube([bolt_tot_len+2*extra, bolt_w+2*extra, xy_bolt_thk+2*extra]);
}

module x_dummy_in(extra=0){
    translate([-d + lock_in_disp, (w-a)/2, x_disp_z + xy_bolt_thk + extra])
    hull(){
        translate([0, 0, -0.02])
        pin();
        
        translate([bolt_tot_len, 0, -0.02])
        pin();
    }
    
    translate([bolt_shift-extra, -(bolt_w+2*extra)/2, x_disp_z - extra])
    cube([bolt_tot_len+2*extra, bolt_w+2*extra, xy_bolt_thk+2*extra]);
}
//x_dummy_in(0.4);

// x position for outer hole
outer_hpx = lock_in_disp + path_tot_len + pin_hl;
// thickness of the walls holding bolts in place
l_wall_thk = 1.6;
module lid($fa=3,$fs=0.6) {
    difference(){
        union(){
            // big flat lid
            translate([0,0,z_bolt_thk+l_wall_thk])
            cylinder(h=l_wall_thk, r=lock_in_disp+bolt_tot_len+l_wall_thk+0.6);
            // x support
            translate([bolt_shift, -(bolt_w+0.2)/2, x_disp_z + xy_bolt_thk])
            cube([bolt_tot_len, bolt_w+0.2, 2*xy_bolt_thk + l_wall_thk + 0.2]);
            // y support
            rotate([0,0,120])
            translate([bolt_shift, -(bolt_w+0.2)/2, y_disp_z + xy_bolt_thk])
            cube([bolt_tot_len, bolt_w+0.2, xy_bolt_thk + l_wall_thk + 0.2]);
            // z support
            rotate([0,0,-120])
            translate([bolt_shift, -(bolt_w+0.2)/2, z_bolt_thk])
            cube([bolt_tot_len, bolt_w+0.2, l_wall_thk]);
            // stability rim
            stab_rim_outer_d = d_in_b-3-0.4;
            stab_rim_inner_d = d_in_b-3-0.4-2*l_wall_thk;
            difference() {
                cylinder(h=z_bolt_thk+l_wall_thk, d=stab_rim_outer_d);
                translate([0,0,-0.1])
                cylinder(h=z_bolt_thk+l_wall_thk+0.2, d=stab_rim_inner_d);
            }
            // three radial ridges for lid stability
            ridge_end = (stab_rim_inner_d+0.4)/2;
            ridge_start = -(bolt_shift-l_wall_thk-0.1);
            rotate([0,0,60])
            translate([ridge_start, -l_wall_thk/2, 0])
            cube([ridge_end - ridge_start, l_wall_thk, z_bolt_thk+l_wall_thk+0.2]);
            rotate([0,0,-60])
            translate([ridge_start, -l_wall_thk/2, 0])
            cube([ridge_end - ridge_start, l_wall_thk, z_bolt_thk+l_wall_thk+0.2]);
            rotate([0,0,180])
            translate([ridge_start, -l_wall_thk/2, 0])
            cube([ridge_end - ridge_start, l_wall_thk, z_bolt_thk+l_wall_thk+0.2]);
        }
        
        // cut outs in the stability rim
        translate([0,0,-0.41])
        z_dummy_out(l_wall_thk+0.4);
        rotate([0,0,120])
        translate([0,0,-0.41])
        z_dummy_out(l_wall_thk+0.4);
        rotate([0,0,-120])
        translate([0,0,-0.41])
        z_dummy_out(l_wall_thk+0.4);
        
        
        // cut out for x bolt
        x_dummy_in(0.1);
        // cut for handle
        handle_cut_d = handle_d+0.3;
        hull() {
            translate([-d + outer_hpx, 0, z_bolt_wall+xy_bolt_thk])
            cylinder(h=2*z_bolt_gap, d = handle_cut_d);
            
            translate([outer_hpx, 0, z_bolt_wall+xy_bolt_thk])
            cylinder(h=2*z_bolt_gap, d = handle_cut_d);
        }
        
        // cut for z bolt
        rotate([0,0,-120]){
            z_dummy_in(0.1);
            // cut for handle
            hull() {
                translate([-d + outer_hpx, 0, z_bolt_gap])
                cylinder(h=2*z_bolt_gap, d = handle_cut_d);
                
                translate([outer_hpx, 0, z_bolt_gap])
                cylinder(h=2*z_bolt_gap, d = handle_cut_d);
            }
        }
        
        // cut for y bolt
        rotate([0,0,120]){
            y_dummy_in(0.1);
            // cut for handle
            hull() {
                translate([-d + outer_hpx, 0, z_bolt_wall+2*xy_bolt_thk])
                cylinder(h=2*z_bolt_gap, d = handle_cut_d);
                
                translate([outer_hpx, 0, z_bolt_wall+2*xy_bolt_thk])
                cylinder(h=2*z_bolt_gap, d = handle_cut_d);
            }
        }
    }
    // pin for lid orientation
    translate([lock_in_disp+bolt_tot_len, 0, z_bolt_thk])
    cylinder(h=l_wall_thk, d=2 - 0.1);
}
//lid();

// lid cover to print separately and glue to the bottom of the lid
module lid_cover() {
    difference(){
        union(){
            // x support
            translate([-l_wall_thk,0,0])
            z_dummy_in(l_wall_thk);
            // y support
            rotate([0,0,120])
            translate([-l_wall_thk,0,0])
            z_dummy_in(l_wall_thk);
            // z support
            rotate([0,0,-120])
            translate([-l_wall_thk,0,0])
            z_dummy_in(l_wall_thk);
        }
        
        // cut out for x bolt
        hull(){
            x_dummy_in(0.15);
            translate([0,0,z_bolt_thk])
            x_dummy_in(0.15);
        }
        // cut for z bolt
        rotate([0,0,-120]){
            hull(){
                z_dummy_in(0.15);
                translate([0,0,z_bolt_thk])
                z_dummy_in(0.15);
            }
        }
        // cut for y bolt
        rotate([0,0,120]){
            hull(){
                y_dummy_in(0.15);
                translate([0,0,z_bolt_thk])
                y_dummy_in(0.15);
            }
        }
    }
}
//translate([0,0,-0.3])
//lid_cover();

// inner diameter, calculated from lid size
d_in_b = 2*(lock_in_disp+bolt_tot_len) + 0.3;

module x_dummy_out(extra=0){
    // extended to the bottom to cut out bottom wall
    translate([outer_hpx+0.2, -(bolt_w+2*extra)/2, x_disp_z - 10])
    cube([d+extra, bolt_w+2*extra, xy_bolt_thk+extra + 10]);
}
module y_dummy_out(extra=0){
    translate([outer_hpx+0.2, -(bolt_w+2*extra)/2, y_disp_z - 15])
    cube([d+extra, bolt_w+2*extra, xy_bolt_thk+extra + 15]);
}
module z_dummy_out(extra=0){
    translate([outer_hpx+0.2, -(bolt_w+2*extra)/2, 0.05])
    cube([d+2*extra, bolt_w+2*extra, z_bolt_thk+extra -0.05]);
}

// helper part for lid attachment, no need to print separately
module body_top($fa=3,$fs=0.6) {
    difference() {
        union() {
            // part of the outer cylinder
            difference(){
                cylinder(h=z_bolt_thk+l_wall_thk, d=d_out_b);
                translate([0,0,-0.1])
                cylinder(h=z_bolt_thk+2*l_wall_thk + 0.2, d=d_in_b-3);
            }
            
            // bolt holders
            z_dummy_out(l_wall_thk);
            rotate([0,0,120])
            z_dummy_out(l_wall_thk);
            rotate([0,0,-120])
            z_dummy_out(l_wall_thk);
        }
        // cutout for pin for lid orientation
        translate([lock_in_disp+bolt_tot_len, 0, z_bolt_thk-0.2])
        cylinder(h=l_wall_thk+0.21, d=2 + 0.2);
        // cut outs for extended bolts
        // x
        translate([-0.02,0,-0.02])
        x_dummy_out(0.2);
        // y
        rotate([0,0,120])
        translate([-0.02,0,-0.02])
        y_dummy_out(0.2);
        // z
        rotate([0,0,-120])
        translate([-0.02,0,-0.02])
        z_dummy_out(0.2);
        
        // cut outs for handles
        rotate([0,0,120])
        translate([outer_hpx+0.2, 0, z_bolt_wall+2*xy_bolt_thk])
        cylinder(h=2*z_bolt_gap, d = handle_d+0.2);
        rotate([0,0,-120])
        translate([outer_hpx+0.2, 0, z_bolt_gap])
        cylinder(h=2*z_bolt_gap, d = handle_d+0.2);
        translate([outer_hpx+0.2, 0, z_bolt_wall+xy_bolt_thk])
        cylinder(h=2*z_bolt_gap, d = handle_d+0.2);
    }
}
//body_top();

// outer diameter at top/bot
d_out_b = d_in_b + 2*l_wall_thk;
// outer diameter at center (scale factor)
d_out_b_cent = d_out_b * 1.18;
// outer body thickness
thk_out_b = 2;

dR = (d_out_b_cent - d_out_b)/2;
Rcur = dR/2 + (h_b^2)/(8*dR);

// cutouts for plank gaps
pc_depth = 0.8;
pc_width = 0.8;

module body($fa=3){
    translate([0,0,h_b-(z_bolt_thk+l_wall_thk)])
    body_top();
    
    difference(){
        translate([0,0,h_b/2])
        rotate_extrude() {
            intersection(){
                // main circular walls
                difference(){
                    translate([d_out_b_cent/2 - Rcur,0,0])
                    circle(r = Rcur, $fa=2);
                    
                    translate([d_out_b_cent/2 - Rcur - thk_out_b,0,0])
                    circle(r = Rcur);
                }
                // square to limit vertical size
                translate([0,-h_b/2,0])
                square([Rcur,h_b]);
            }
        }
        
        // cut out for supporting disc (printing upside down)
        translate([0,0,2])
        body_bottom_cover(0.15);
        
        // cutout for pin for lid orientation in the barrel body
        translate([0,0,h_b-(z_bolt_thk+l_wall_thk)])
        translate([lock_in_disp+bolt_tot_len, 0, z_bolt_thk-0.2])
        cylinder(h=l_wall_thk+0.21, d=2 + 0.2);
        
        
        for (rot_gap = [10 : 360/16 : 360]) {
            rotate([0,0,rot_gap])
            translate([d_out_b_cent/2 - Rcur,0,h_b/2])
            rotate([90,45,0])
            rotate_extrude(angle=90){
                translate([Rcur-pc_depth+0.1,-pc_width/2,0])
                square([pc_depth, pc_width]);
            }
        }
    }
    
    // rims
    color("green")
        translate([0,0,h_b/2])
        rotate_extrude() {
            intersection(){
                // main circular walls
                difference(){
                    translate([d_out_b_cent/2 - Rcur,0,0])
                    circle(r = Rcur+0.3, $fa=2);
                    
                    translate([d_out_b_cent/2 - Rcur - thk_out_b,0,0])
                    circle(r = Rcur+0.3);
                }
                // squares to define rims
                union(){
                    translate([0,-4 -h_b/4,0])
                    square([Rcur,8]);
                    translate([0,-4 +h_b/4,0])
                    square([Rcur,8]);
                    
                    translate([0,-4 -h_b*1.6/4,0])
                    square([Rcur,8]);
                    translate([0,-4 +h_b*1.6/4,0])
                    square([Rcur,8]);
                }
            }
        }
    
    // bottom
    translate([0,0,2-1.6-0.1])
    cylinder(h=1.6, d=d_in_b+1.2);
}
//body();

//translate([0,0,h_b-(z_bolt_thk+l_wall_thk)])
//lid();

module body_bottom_cover(extra=0, $fa=3){
    cylinder(h=0.8, d=d_in_b+1.2+extra);
}

//translate([0,0,-5])
//body_bottom_cover();

module handle(stem = 0, $fa=5, $fs=0.8){
    cylinder(h=l_wall_thk, d1 = 2*handle_d - 2, d2 = 2*handle_d);
    translate([0,0,l_wall_thk-0.02])
    cylinder(h=2*l_wall_thk, d=2*handle_d);

    translate([0,0,3*l_wall_thk-0.02])
    cylinder(h=stem, d = handle_d - 0.2);

    translate([0,0,stem + 3*l_wall_thk - 0.2])
    intersection(){
        thread(-0.2);
        cylinder(h=1.6*(xy_bolt_thk), d1=2*handle_d, d2=0);
    }
}
module all_handles(){
    // handle for z bolt
    translate([0,50,0])
    handle(stem = 2*l_wall_thk + 0.4);
    // handle for y bolt
    translate([15,50,0])
    handle(stem = 2*l_wall_thk + xy_bolt_thk + 0.6);
    // handle for x bolt
    translate([30,50,0])
    handle(stem = 2*l_wall_thk + 2*xy_bolt_thk + 0.8);
}
//all_handles();

// thread for handles
module thread(delta=0, $fa=5, $fs=0.6){
    th_d_out = handle_d - 0.3 + delta;
    th_d_in = (handle_d - 0.3)*0.7 + delta;
    th_step = 1.8;
    th_len = xy_bolt_thk;
    intersection(){
        linear_extrude(th_len, twist=-360*th_len/th_step){
            intersection(){
                circle(d=th_d_out);
                
                translate([(th_d_out-th_d_in)*0.3, 0, 0])
                circle(d=(th_d_out+th_d_in)/2);
            }
        }
    }
    cylinder(h=th_len, d=th_d_in);
}
//thread(delta=-0.1);