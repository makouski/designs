$fa = 5;
$fs = 0.4;
$fn = 60;

// gap to account for print precision
eps = 0.1;
// crank mechanism parameters
// arm lengths
r_arm = 6.6;
l_arm = 8.5;
// width of arms
h = 7;
// diameter of left arm end disk
d_e = 6;
// diameter of joint disk
d_j = 8.1;

// angle of the right arm when open
angle_r = 60;

// right arm width
r_w = 5.6;
//left arm width
l_w = 5.6;

// join axle
d_ax = d_j - 3.6;

// right arm right side pin
r_arm_pin_d = 2.4;
r_arm_pin_h = 1.4;

end_x_end = (d_e/2) + (l_arm + r_arm);
end_x_right = end_x_end - (r_arm * cos(angle_r));
end_z_right = r_arm * sin(angle_r);
end_x_left = end_x_right - sqrt(l_arm^2 - end_z_right^2);
echo("travel: ", end_x_left-(d_e/2));
end_angle = 90 - angle_r + asin((end_x_right-end_x_left)/l_arm);
echo("end angle: ", end_angle);


//// all parts for printing with recommended orientation ////

//rotate([180,0,0])
//tip();

//barrel();

//translate([2,5,0])
//rotate([0,0,180])
//arm_right();
//translate([-2,-5,0])
//arm_left();

//rotate([0,90,90])
//barrel_extension();

//endc();

/////////////////////////////////////////////////


module chamfered_cylinder(d=d_e, eps=eps){
    // main sliding cylinder
    cylinder(h=h+eps-0.6, d=d+eps, center=true);
    // taper the edges
    translate([0,0,-(h+eps-0.3)/2])
    cylinder(h=0.3, d1=d+eps-0.3, d2=d+eps, center=true);
    translate([0,0,(h+eps-0.3)/2])
    cylinder(h=0.3, d1=d+eps, d2=d+eps-0.3, center=true);
}
//chamfered_cylinder(d_e, eps);

module arm_right(){
    difference(){
        union(){
            // joint cylinder
            translate([0, 0, (h-eps)/2])
            chamfered_cylinder(d_j, -eps);
            
            hull(){
                translate([r_arm+2*eps,0,(h-eps)/2])
                chamfered_cylinder(r_w, -eps);
                
                translate([0,0,(h-eps)/2])
                chamfered_cylinder(r_w, -eps);
            }
        }
        
        // cut out with other arm
        translate([0,0,2]){
            cylinder(h=h, d=d_j+eps);
            
            rotate([0,0,-end_angle])
            hull(){
                translate([l_arm,0,0])
                cylinder(h=h, d=l_w+eps);
                
                cylinder(h=h, d=l_w+eps);
            }

        }
        
        // cutout in the right end of right arm
        translate([r_arm+2*eps, 0, h-eps - (r_arm_pin_h+eps) + 0.01]){
            rotate([0,0,-angle_r])
            hull(){
                cylinder(h=r_arm_pin_h+eps, d1=eps+r_arm_pin_d/4, d2=eps+r_arm_pin_d);
                translate([5,0,0])
                cylinder(h=r_arm_pin_h+eps, d1=eps+r_arm_pin_d/4, d2=eps+r_arm_pin_d);
            }
        }
    }
    
    // joint axle
    cylinder(h=h-eps, d=d_ax-eps);
}
//arm_right();

module arm_left(){
    difference(){
        union(){
            translate([l_arm, 0, (h-eps)/2])
            chamfered_cylinder(d_e, -eps);
            // joint cylinder
            translate([0, 0, (h-eps)/2])
            chamfered_cylinder(d_j, -eps);
            
            hull(){
                translate([l_arm,0,0])
                cylinder(h=h-eps, d=l_w-eps);
                cylinder(h=h-eps, d=l_w-eps);
            }
        }
        
        // cut out with other arm
        translate([0,0,h-2]){
            cylinder(h=h, d=d_j+eps);
            
            rotate([0,0,-end_angle])
            hull(){
                translate([r_arm,0,0])
                cylinder(h=h, d=r_w+eps);
                
                cylinder(h=h, d=r_w+eps);
            }
        }
        // hole
        translate([0,0,-0.01])
        cylinder(h=h+0.02, d=d_ax+eps);
    }
}
//arm_left();

// cutout dummies
module dummy_arm_right(angle=0){
    x_right = end_x_end;
    z_right = 0;
    
    x_left = x_right - (r_arm * cos(angle));
    z_left = r_arm * sin(angle);
    
    translate([x_left, 0, z_left])
    rotate([90,0,0])
    cylinder(h=h+0.1, d=d_j+eps, center=true);
    
    hull(){
        translate([x_right, 0, z_right])
        rotate([90,0,0])
        cylinder(h=h+eps, d=r_w+eps, center=true);
        
        translate([x_left, 0, z_left])
        rotate([90,0,0])
        cylinder(h=h+eps, d=r_w+eps, center=true);
    }
}

module dummy_arm_left(angle=0){
    x_end = end_x_end;
    
    x_right = x_end - (r_arm * cos(angle));
    z_right = r_arm * sin(angle);
    
    x_left = x_right - sqrt(l_arm^2 - z_right^2);
    z_left = 0;
    
    translate([x_right, 0, z_right])
    rotate([90,0,0])
    cylinder(h=h+eps, d=d_j+eps, center=true);
    
    translate([x_left, 0, z_left])
    rotate([90,0,0])
    // cylinder(h=h+eps, d=d_e+eps, center=true);
    // sliding cylinder
    chamfered_cylinder(d_e, eps);
    
    hull(){
        translate([x_right, 0, z_right])
        rotate([90,0,0])
        cylinder(h=h+eps, d=l_w+eps, center=true);
        
        translate([x_left, 0, z_left])
        rotate([90,0,0])
        cylinder(h=h+eps, d=l_w+eps, center=true);
    }
}

//dummy_arm_right(angle_r);
//dummy_arm_left( angle_r);
//dummy_arm_right(30);
//dummy_arm_left( 30);

//for(ang = [0 : ang_step : angle_r]){
//    dummy_arm_right(ang);
//    dummy_arm_left(ang);   
//}

ang_step = 2;
module barrel_extension(){
    difference(){
        rotate([0,90,0]){
            translate([0,0,eps+end_x_end+r_w/2])
            cylinder(h=2.3, d1=11.4, d2=9.4);
            cylinder(h=eps+end_x_end+r_w/2, d=11.4);
            translate([0,0,-1.4])
            cylinder(h=1.4, d1=11, d2=11.4);
            // extension with thread
            translate([0,0,-10.01])
            cylinder(h=10.02, d=11);
            translate([0,0,-10])
            rotate([0,180,0])
            bottom_thread(-eps);
        }
        
        // hole
        rotate([0,-90,0])
        cylinder(h=20, d=6.2);
        
        // clean the path for left sliding arm
        rotate([90,0,0])
        hull(){
            translate([(d_e/2) + l_arm,0,0])
            chamfered_cylinder(d_e, eps);
            //translate([-1.5,0,0])
            chamfered_cylinder(d_e, eps);
        }
        
        
        // arms
        for(ang = [0 : ang_step : angle_r]){
            dummy_arm_right(ang);
            dummy_arm_left(ang);   
        }
        
        // cutout size and depth adjusted by hand
        translate([0.5*d_e + l_arm, 0, 12.6])
        rotate([90,0,0])
        cylinder(h=h+eps,d=20.2,center=true);
        
        translate([0.5*d_e + l_arm, 0, -11.85])
        rotate([90,0,0])
        cylinder(h=h+eps,d=16,center=true);
        
        // trim the sharp edges
        translate([0.5*d_e + l_arm - 3.7, 0, 4])
        rotate([90,0,0])
        difference(){
            cube([4,4,h+eps],center=true);
        }
        translate([0.5*d_e + l_arm, 0, -3.9])
        rotate([90,0,0])
        cube([4,4,h+eps],center=true);
    }
    // pin for the right end of right arm
    x_right = end_x_end;
    z_right = 0;
    translate([x_right, -(0.01+(h+eps)/2) + (r_arm_pin_h), z_right])
    rotate([90,0,0])
    cylinder(h=r_arm_pin_h, d1=r_arm_pin_d/4, d2=r_arm_pin_d);
}
// to check where left arm touches the bottom when open
//dummy_arm_left(angle_r);
//
//intersection(){
//translate([-30,-100,-50])
//cube(100);
//barrel_extension();
//}

// pen tip: [ [d_start, d_stop, height], ... ]
// total z: 25
pen_tip_outer_a = [[ 4.2,  6,  2], 
                   [ 6,   12, 17],
                   [12,   11,  4],
                   [11,   11,  2],
                   [10.6,  8,  2] // instead of flat end
                  ];
// 2.7 is pen tip size
pen_tip_inner_a = [[2.7, 2.7, 4], 
                   [2.7, 4.3, 1], 
                   [4.3, 5.7,15],//20
                   [5.7, 6.3,13] // some extra
                   ];

module cone_stack(a, i=0) {
    if (len(a) > i) {
        cylinder(h = a[i][2]+0.001, d1 = a[i][0], d2 = a[i][1]);
        
        translate([0,0,a[i][2]-0.002])
        cone_stack(a, i+1);
    }
}

// bottom thread
module bottom_thread(extra=0) {
    intersection(){
            cylinder(h=9 + extra, d1=18, d2=7);
            tip_thread(9 + extra, extra);
        }
    cylinder(h=2, d1=9, d2=7);
}
//bottom_thread();

// main common thread
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
module tip_thread(len_tot=10, delta=0){
    min_d = 8.3;
    max_d = 9.2;
    step = 2;
    
    cylinder(h=len_tot, d = min_d+delta, $fn=360/$fa);
    
    intersection(){
        translate([0,0,-step])
        twist(min_d+delta-0.05, max_d+delta, step, step/5, len_tot);
        
        cylinder(h=len_tot, d = max_d+delta, $fn=360/$fa);
    }
}
//tip_thread();


module donut_cut(){
    rotate_extrude(){
        translate([5.2 + 25/2,0,0])
        circle(d=25);
        }
}
//donut_cut();

module tip() {
    difference(){
        union(){
            cone_stack(pen_tip_outer_a);
            
            translate([0,0,25-0.02])
            intersection(){
                tip_thread(7.5, -0.1);
                cylinder(h=7.5, d1=18, d2=8);
            }
        }
        
        translate([0,0,-0.01])
        cone_stack(pen_tip_inner_a);
        
        translate([0,0,22])
        donut_cut();
    }
}


module barrel(){
    difference(){
        // 69.5 tip of the insert when open
        h_to_top = 69.5;
        cylinder(h=h_to_top, d=11);
        
        // top thread
        // inner thread, extra size
        translate([0,0,h_to_top])
        rotate([180,0,0])
        translate([0,0,-0.01])
        intersection(){
            cylinder(h=7.6, d1=18, d2=8);
            tip_thread(7.6, eps);
        }
        // extra cut for the tip cone
        translate([0,0,h_to_top-2+0.01])
        cylinder(d1=8, d2=10.6, h=2);
        
        // main hole
        cylinder(h=h_to_top, d=7);
        
        // bottom thread
        translate([0,0,10])
        bottom_thread(eps);
        translate([0,0,-0.01])
        cylinder(h=10.02, d=15);
    }
}

// end cap for the back of the cartridge
endc_d = 5.6;
endc_in = 3.1;
endc_h = 0.5;

module endc_bar(){
    rotate_extrude(angle = 2*asin(1.1/(endc_d/2))){
        translate([endc_in/2,0])
        square([(endc_d - endc_in)/2, 4], center=false);
    }
}
module endc() {
    cylinder(h=0.7, d=endc_d);
    
    endc_bar();
    
    rotate([0,0,180])
    endc_bar();
}
    
// review internals //
//intersection(){
//cube(50);
//tip();
//}

//intersection(){
//translate([0,0,-50])
//cube(150);
//barrel();
//}
