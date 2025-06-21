$fa = 5;
$fs = 1;

// thread parameters used by all modules
pitch = 2;
min_d = 10;
max_d = 12;
// delta is applied to diameters to adjust tolerances

// simple spiral with a circle //
module thread_1(len_tot, delta=0, min_d=min_d, max_d=max_d, pitch=pitch){
    cir_d = delta + (max_d+min_d)/2;
    cir_disp = (max_d-min_d)/4;
    linear_extrude(len_tot, twist=-360*len_tot/pitch){
        translate([cir_disp,0,0])
        circle(d=cir_d);
    }
}
translate([-60,0,0])
thread_1(15, -0.1);


// spiral with constraints // 
// better in practical applications
module thread_2(len_tot, delta=0, min_d=min_d, max_d=max_d, pitch=pitch){
    cir_d = (min_d + max_d)/2;
    cir_disp = (max_d - min_d)/3;
    linear_extrude(len_tot, twist=-360*len_tot/pitch){
        // inner boundary
        circle(d = min_d+delta);
        
        intersection(){
            // outer cut off
            circle(d = max_d+delta);
            // moving part
            translate([cir_disp,0,0])
            circle(d = cir_d+delta);
        }
    }
}
translate([-40,0,0])
thread_2(15, -0.1);


// custom 3d shape with polyhedron spiral //
// smooth surface, less elements

function rot_shift_pt(p, a, c) = [
    p.x*cos(a) - p.y*sin(a), 
    p.x*sin(a) + p.y*cos(a),
    p.z + a*c
];

// rotation of triangular profile
module twist(d_in, d_out, pitch, tip, len_tot){
    w = pitch - tip;
    tan_ang = (w - tip) / (d_out - d_in);
    angs = [ 0 : $fa : 360 * (pitch + len_tot) / pitch ];
    //angs = [0, 10, 20, 30];
    profile = [ [d_in/2, 0, 0], [d_in/2, 0, w], [(w/2)/tan_ang + d_in/2, 0, w/2] ];
    points = [ for(a = angs) for(ii = [0 : 2]) rot_shift_pt(profile[ii], a, pitch/360) ];
    len_angs = len(points) / 3;
    i_max = len(points) - 1;
    faces = concat([ [0, 1, 2], [i_max, i_max - 1, i_max - 2] ],
        [ for(i = [0 : len_angs - 2]) [1 + 3*i, 1 + 3*(i+1), 2 + 3*(i+1), 2 + 3*i] ],
        [ for(i = [0 : len_angs - 2]) [3*i, 2 + 3*i, 2 + 3*(i+1), 3*(i+1)] ],
        [ for(i = [0 : len_angs - 2]) [3*i, 3*(i+1), 1 + 3*(i+1), 1 + 3*i] ]
    );
    polyhedron(points=points, faces=faces, convexity=10);
}

module thread_3(len_tot, delta=0, min_d=min_d, max_d=max_d, pitch=pitch){
    cylinder(h=len_tot, d = min_d+delta, $fn=360/$fa);
    
    intersection(){
        translate([0,0,-pitch])
        twist(min_d+delta-0.05, max_d+delta, pitch, pitch/4, len_tot);
        
        cylinder(h=len_tot, d = max_d+delta, $fn=360/$fa);
    }
}
translate([-20,0,0])
thread_3(15, -0.1);


// rotate-extruded 2d shapes with slant by multmatrix //
// not a perfect rotation geometry but better rendering time for long threads

// 2D section, place to customize thread profile
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

module thread_4(len_tot, delta=0, min_d=min_d, max_d=max_d, pitch=pitch){
    // inner cylinder
    cylinder(h=len_tot, d=min_d+delta, $fn=360/$fa);
    
    intersection(){
        // one revolution no matter how long the thread is
        s = pitch/(2*PI*((max_d+delta)/2));
        translate([0,0,-pitch])
        for(i = [0: (360/$fa) - 1])
            rotate([0,0,i*$fa])
            translate([0,0,i*pitch*($fa/360)])
            slice_twist(len_tot, pitch, min_d+delta, max_d+delta, s);
        
        cylinder(h=len_tot, d=max_d+delta, $fn=360/$fa);
    }
}
thread_4(15, -0.1);
