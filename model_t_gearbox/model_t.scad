$fa = 5;
$fs = 0.8;

eps = 0.1;
tooth_d = 3;
gear_thick = 5;

// attempt with 1/2 Nd/Md ratio, planetary gears are big
//// driving gear
//Nd = 8;
//N1 = 6;
//Nr = 10;
//
//// planetary gears
//Md = 16;
//M1 = (Nd+Md)-N1;
//Mr = (Nd+Md)-Nr;

// attempt with 2 Nd/Md ratio, main axis gears are somewhat big
// planetary gears
Md = 9;
M1 = 12;
Mr = 8;
// driving gear
Nd = 18;
N1 = (Nd+Md)-M1;
Nr = (Nd+Md)-Mr;

// 1:1 ratio, simple +3 -3 step
//// planetary gears
//Md = 12;
//M1 = Md+3;
//Mr = Md-3;
//// driving gear
//Nd = 12;
//N1 = Nd-3;
//Nr = Nd+3;

// gear sizes
echo(" ========= panetary:", Mr, M1, Md);
echo(" ========== central:", Nr, N1, Nd);

// transmission ratios
echo(" ====  first gear 1/x",1/(1 - (Md/Nd)*(N1/M1)), " ==== ");
echo(" ==== reverse gear 1/x",1/(1 - (Md/Nd)*(Nr/Mr)), " ==== ");

// meshing: ignore integer parts, compare fractions only
echo("meshing first: ",N1/3,"~~~",(M1/3)*(Nd/Md));
echo("meshing reverse: ",Nr/3,"~~~",(Mr/3)*(Nd/Md));

function gear_mid_r(n_tooth) = (tooth_d / 2) / tan(360/(n_tooth*2*2));

echo("axis distance", Nd, Md, "::", gear_mid_r(Nd) + gear_mid_r(Md));
echo("axis distance", N1, M1, "::", gear_mid_r(N1) + gear_mid_r(M1));
echo("axis distance", Nr, Mr, "::", gear_mid_r(Nr) + gear_mid_r(Mr));

// displacement based on gear distances ^^^
plan_disp = max(gear_mid_r(Nd) + gear_mid_r(Md),
                gear_mid_r(N1) + gear_mid_r(M1),
                gear_mid_r(Nr) + gear_mid_r(Mr));

// other params
main_axle_d = 11;
driving_tube_diff = 4;
flywheel_outer_d = 2*plan_disp + 2*gear_mid_r(M1) + tooth_d + 1;
flywheel_hub_d = 25;
planetary_axle_d = 7;


//// all parts to print ////
//flywheel();
//clutch();
//driving_gear();
//planetary_gear_1();
//planetary_gears_2_3();
//driving_disc_rod();
//first_disc_rod();
//reverse_disc_rod();
////////////////////////


module gear(n_tooth = 20){
    n_sl = n_tooth * 2;
    gear_edg = tooth_d / 2 / sin(360/n_sl/2);
    gear_mid = gear_mid_r(n_tooth);
    
    linear_extrude(gear_thick){
        difference(){
            union(){
                circle(r=gear_edg);
                for (i = [1 : n_sl]){
                    rotate([0,0,i*360/n_sl])
                    if (i % 2 == 0){
                        translate([gear_mid,0,0])
                        circle(d=tooth_d-eps, $fn=60);
                    }
                }
            }
            
            for (i = [1 : n_sl]){
                rotate([0,0,i*360/n_sl])
                if (i % 2 == 1){
                    translate([gear_mid,0,0])
                    circle(d=tooth_d+eps, $fn=60);
                }
            }
        }
        
    }
}
//gear(10);

// common part for all 4 drums
module wheel_rim(){
    // rim
    difference(){
        cylinder(h=10, d=flywheel_outer_d);
        
        translate([0,0,-0.1])
        cylinder(h=10.2, d=flywheel_outer_d-10);
    }
}

/// flywheel ///
module flywheel_spoke(){
    translate([0,-6,0])
    cube([flywheel_outer_d/2 - 1, 12, 10]);
    
    translate([plan_disp,0,0])
    cylinder(h=10 + gear_thick*3, d=planetary_axle_d-eps);
}

module flywheel(){
    wheel_rim();
    // hub
    cylinder(h=10, d=flywheel_hub_d);
    // main axle
    ax_len = 10 + gear_thick*3 + 10*3 + 2*2 + eps*5;
    difference(){
        cylinder(h=ax_len, d=main_axle_d-eps);
        translate([0,0,ax_len-6+eps])
        thread(height=6, delta=eps);
    }

    flywheel_spoke();

    rotate([0,0,120])
    flywheel_spoke();

    rotate([0,0,-120])
    flywheel_spoke();
}
//flywheel();

// not an actual clutch, this is where main clutch was
module clutch(){
    cylinder(h=gear_thick, r=12);
    translate([0,0,gear_thick-0.1])
    thread(height=5.5, delta=-eps);
}
//clutch();

module driving_gear(){
    difference(){
        gear(Nd);
        
        translate([0,0,-0.1])
        cylinder(h=20,d=main_axle_d+eps);
        
        translate([0,0,-0.1])
        difference(){
            cylinder(h=20, d=main_axle_d+driving_tube_diff+eps);
            cube([30,4-eps,30],center=true);
        }
    }
}
//driving_gear();


module conn_rods(delta=0){
    // adjust to fit the gear
    diam = 3;
    transl = 5.6;
    translate([transl,0,0])
    cylinder(h=gear_thick, d=diam+delta);
    rotate([0,0,180/9])
    translate([-transl,0,0])
    cylinder(h=gear_thick, d=diam+delta);
    rotate([0,0,-180/9])
    translate([-transl,0,0])
    cylinder(h=gear_thick, d=diam+delta);
}

module planetary_gear_1(){
    difference(){
        gear(Md);
        translate([0,0,-0.1])
        cylinder(h=30, d=planetary_axle_d+eps);
    }
    translate([0,0,gear_thick - 2])
    conn_rods(-eps);
}
//planetary_gear_1();

module planetary_gears_2_3(){
    difference(){
        union(){
            gear(M1);
            translate([0,0,gear_thick-0.01])
            gear(Mr);
        }
        translate([0,0,-0.1])
        cylinder(h=30, d=planetary_axle_d+eps);
        translate([0,0,-0.8])
        conn_rods(eps);
    }
}
//planetary_gears_2_3();

// common for all 3 drums
module plain_spoke(){
    translate([0,-6,0])
    cube([flywheel_outer_d/2 - 1, 12, 10]);
}

module driving_disc_rod(){
    wheel_rim();
    // main axle
    ax_len = 10 + 2 + gear_thick*3 + 10*2 + 2;
    difference(){
        union(){
            // hub
            cylinder(h=12, d=flywheel_hub_d);
            // main axle
            cylinder(h=ax_len, d=main_axle_d+driving_tube_diff-eps);
            
            plain_spoke();

            rotate([0,0,120])
            plain_spoke();

            rotate([0,0,-120])
            plain_spoke();
        }
        translate([0,0,-0.1])
        cylinder(h=ax_len+0.2, d=main_axle_d+eps);
        translate([-(4+eps)/2,-10,ax_len - gear_thick - 2*eps])
        cube([(4+eps),20,10]);
    }
}
//driving_disc_rod();

module first_disc_rod(){
    wheel_rim();
    // main axle
    ax_len = 10 + 2 + gear_thick*1 + 10;
    difference(){
        union(){
            // hub
            cylinder(h=12, d=2*gear_mid_r(N1) + tooth_d + 6);
            // main axle
            cylinder(h=ax_len, d=2*gear_mid_r(N1) + tooth_d - eps);
            
            plain_spoke();

            rotate([0,0,120])
            plain_spoke();

            rotate([0,0,-120])
            plain_spoke();
            
            translate([0,0,ax_len])
            gear(N1);
        }
        translate([0,0,-0.1])
        cylinder(h=ax_len+gear_thick+0.2, d=main_axle_d+driving_tube_diff+eps);
    }
}
//first_disc_rod();

module reverse_disc_rod(){
    wheel_rim();
    // main axle
    ax_len = 10;
    difference(){
        union(){
            // main axle
            cylinder(h=ax_len, d=2*gear_mid_r(Nr) + tooth_d - eps);
            
            plain_spoke();

            rotate([0,0,120])
            plain_spoke();

            rotate([0,0,-120])
            plain_spoke();
            
            translate([0,0,ax_len])
            gear(Nr);
        }
        translate([0,0,-0.1])
        cylinder(h=ax_len+gear_thick+0.2, d=2*gear_mid_r(N1) + tooth_d + eps);
    }
}
//reverse_disc_rod();


// check sizes
//driving_disc_rod();
//translate([0,0,12])
//first_disc_rod();
//translate([0,0,24])
//reverse_disc_rod();
//
//translate([0,0,gear_thick*3 + 10*3 + 2*2])
//rotate([180,0,0])
//translate([0,0,-10])
//flywheel();


// thread for flywheel and clutch
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
module thread(height=10, delta=0){
    min_d = 6.7;
    max_d = 7.5;
    step = 1.6;
    
    cylinder(h=height, d = min_d+delta, $fn=360/$fa);
    
    intersection(){
        translate([0,0,-step])
        twist(min_d+delta-0.05, max_d+delta, step, step/5, height);
        
        cylinder(h=height, d = max_d+delta, $fn=360/$fa);
    }
}
//thread(6, 0.1);
