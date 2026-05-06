$fa=4;
$fs=0.4;

// ball
R = 7;

wall = 1.2;
// vertical pipeline
r1 = R;
a1 = 65;
v_shift = 2;

// horizontal pipeline
x_h_shift = 4*R;
y_h_shift = 3;
hseg1_L = 3.3*R;
hseg1_a = 40;
hseg2_L = 1.6*R;
hseg2_a = 110;
hseg2_b = 65;
// curve parameters
r_h = R;
a_h = 55;
x_h_disp = r_h*(1-cos(a_h));
z_h_disp = r_h*sin(a_h);

p3 = [
    -hseg2_L*sin(hseg2_a)*sin(hseg2_b),
    hseg1_L*sin(hseg1_a) + hseg2_L*sin(hseg2_a)*cos(hseg2_b),
    hseg1_L*cos(hseg1_a) + hseg2_L*cos(hseg2_a)
];
p4 = [x_h_disp-x_h_shift, y_h_shift, z_h_disp];

// derived values
x_disp = r1*(1-cos(a1));
z_disp1 = r1*sin(a1);
z_disp2 = sqrt((2*R)^2 - x_disp^2);
b1 = atan(x_disp/(z_disp2+v_shift));
d_ang1 = 180 - 2*b1;
tvext = 2.1*R;
bvext = 0.3*R;
bot_z_end =  -(z_disp2+2*v_shift + bvext);
top_z_end = z_disp1 + tvext;
right_x_end = R + x_disp/sin(b1);
back_y_end = R + p3.y;


module ball() {
    delta = 0.5;
    new_r = R - delta/2;
    difference(){
        sphere(r=new_r);
        translate([0,0,-new_r])
        cylinder(h=new_r, r=R);
        // hole for filament piece
        translate([0,0,-0.05])
        cylinder(h=new_r - 1, d=1.9);
    }
}
//ball();

module arc(r, ang) {
    rotate([90,0,0]){
        rotate_extrude(angle=ang)
            difference(){
                translate([r,0,0]) circle(r=R);
                translate([-3*R,-3*R/2,0]) square(3*R, center=false);
            }
        translate([r,0,0]) sphere(r=R);
        rotate([0,0,ang]) translate([r,0,0]) sphere(r=R);
    }
}
//arc(r=10, ang=60);

module window() {
    rotate([90,0,0])
    cylinder(h=1.5*R, r1=0.5*R, r2=0.9*R);
}

module main_vert_cut() {
    // vertical well
    translate([x_disp, 0, z_disp1])
    cylinder(h=tvext, r=R);
    
    // curve to the central position
    translate([x_disp, 0, z_disp1])
    rotate([180,0,0])
    translate([-r1,0,0])
    arc(r1, a1);
    
    // detour
    translate([0,0,-v_shift])
    rotate([0, d_ang1/2, 0])
    arc(x_disp/sin(b1), d_ang1);
    
    // bottom vertical extension
    translate([x_disp, 0, bot_z_end])
    cylinder(h=bvext, r=R);
    
    window();
}
//main_vert_cut();

module horiz_cut(vert_drain=false) {
    // start
    sphere(r=R);
    
    // seg 1
    rotate([-hseg1_a,0,0])
    cylinder(h=hseg1_L, r=R);
    // seg 2 start
    translate([0,hseg1_L*sin(hseg1_a), hseg1_L*cos(hseg1_a)]) {
        sphere(r=R);
        cylinder(h=R+0.2, r=R*0.35);
    }
    
    if (vert_drain) {
        translate([0,hseg1_L*sin(hseg1_a), hseg1_L*cos(hseg1_a)])
        translate([0,0,-(top_z_end - bot_z_end)])
        cylinder(h=top_z_end - bot_z_end, r=R);
    }
    else {
        // seg 2
        translate([0,hseg1_L*sin(hseg1_a), hseg1_L*cos(hseg1_a)]) {
            rotate([-hseg2_a,0,hseg2_b])
            cylinder(h=hseg2_L, r=R);
        }
        
        // seg 3 start
        translate(p3) sphere(r=R);
        // connect p3 and p4
        translate(p4)
        rotate([
            0,
            90 - asin((p3-p4).z / norm(p3-p4)),
            atan((p3-p4).y / (p3-p4).x)
        ])
        cylinder(h=norm(p3-p4), r=R);
        
        // final curve (p4 to finish)
        translate(p4)
        rotate([180,0,0])
        translate([-r_h,0,0])
        arc(r_h, a_h);

        // finish
        translate([-x_h_shift, y_h_shift, 0]) {
            sphere(r=R);
            window();
        }
    }
}
//horiz_cut();
//horiz_cut(vert_drain=true);

module 2x2_cut() {
    // vertical extension
    translate([x_disp, 0, top_z_end-0.05])
    cylinder(h=hseg1_L*cos(hseg1_a) + R + wall - top_z_end + 0.1, r=R);
    
    main_vert_cut();
    horiz_cut();
    translate([-x_h_shift,y_h_shift,0])
    horiz_cut(vert_drain=true);
    
    translate([0,0,-(top_z_end - bot_z_end)]) {
        main_vert_cut();
        horiz_cut();
        translate([-x_h_shift,y_h_shift,0])
        horiz_cut(vert_drain=true);    
    }
}
//2x2_cut();

module 2x2_box() {
    // main box
    n_h_seg = 1;
    n_v_seg = 1;
    translate([-x_h_shift/2, -(R+wall), -((top_z_end - bot_z_end)*n_v_seg + 2*R + 0.05)])
    cube([
        x_h_shift/2 + right_x_end + wall,
        R + 2*wall + back_y_end + y_h_shift*(n_h_seg-1),
        hseg1_L*cos(hseg1_a) + R + wall + (top_z_end - bot_z_end)*n_v_seg + 2*R
    ]);
    // side box
    translate([
        -x_h_shift - x_h_shift/2 - wall,
        -(R+wall) + y_h_shift,
        -((top_z_end - bot_z_end)*n_v_seg + 2*R + 0.05)
    ])
    cube([
        x_h_shift + wall,
        R + 2*wall + back_y_end + y_h_shift*(n_h_seg-2),
        hseg1_L*cos(hseg1_a) + R + wall + (top_z_end - bot_z_end)*n_v_seg + 2*R
    ]);
}

module draft() {
    difference() {
        2x2_box();
        2x2_cut();
    }
}
draft();
