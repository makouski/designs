$fs = 0.4;

// important for defining the maze
travel_ratio = 3;

// labyrinth path: [ [[x1,y1,z1],[x2,y2,z2]], [], [], ...]
// x, y, z are in units of a
paths = [
    [[0,0,0],[0,0,2]],
        [[0,0,2],[0,1,2]],
        [[0,0,2],[3,0,2]],
            [[3,0,2],[3,0,1]],
                [[3,0,1],[3,1,1]],
    [[0,0,0],[1,0,0]],
        [[1,0,0],[1,0,1]],
        [[1,0,0],[1,2,0]],
            [[1,2,0],[1,2,1]],
                [[1,2,1],[2,2,1]],
                    [[2,2,1],[2,2,0]],
                        [[2,2,0],[2,3,0]],
                            [[2,3,0],[2,3,3]],
                                [[2,3,3],[3,3,3]],
            [[1,2,0],[1,3,0]],
                [[1,3,0],[0,3,0]]
                
];

// visually inspect 3D maze
show_all_paths();


module show_all_paths(){
    // start
    color("green")
    sphere(d=1.1);
    // end
    color("red")
    translate([travel_ratio, travel_ratio, travel_ratio])
    sphere(d=1.1);
    
    // all defined paths
    for(seg = paths) {
        hull(){
            translate(seg[0])
            sphere(d=0.9);
            translate(seg[1])
            sphere(d=0.9);
        }
    }
    
    // draw ghosts for QA
    for(seg_xy = paths){
        for(seg_xz = paths){
            for(seg_yz = paths){
                // try all path combinations, not considering same segment twice
                if (seg_xy != seg_xz && seg_xy != seg_yz && seg_xz != seg_yz) {
                    g = find_ghosts(seg_xy, seg_xz, seg_yz);
                    if(len(g) > 0){
                        //echo(g);
                        color("blue")
                        hull(){
                            translate(g[0])
                            sphere(d=0.8);
                            translate(g[1])
                            sphere(d=0.8);
                        }
                    }
                }
            }
        }
    }
}

function pt_distance(a, b) = sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2);

function find_longest_seg (points) = (
    let (max_dist = len(points) > 0 ?
            max([for(p1 = points) for(p2 = points) pt_distance(p1, p2)]) : 0)
    let (max_list = [for(p1 = points) for(p2 = points) 
        if(pt_distance(p1, p2) == max_dist) [p1,p2] ])
    max_dist > 0 ? max_list[0] : []
);

// find missing dimension for one segment projection
function find_missing_ax(p, ax, segax, seg) = (
    let (min_seg = min(seg[0][segax], seg[1][segax]))
    let (max_seg = max(seg[0][segax], seg[1][segax]))
    let (p_inside = (p[segax] >= min_seg) && (p[segax] <= max_seg))
    let (p_tang = (seg[0][segax] == seg[1][segax]))
    !p_inside ? [] : (p_tang ? 
            [min(seg[0][ax], seg[1][ax]), max(seg[0][ax], seg[1][ax])] :
            [(seg[0][ax]*abs(seg[1][segax] - p[segax]) + 
              seg[1][ax]*abs(seg[0][segax] - p[segax])) / (max_seg - min_seg)]
            )
);

// find missing dimension (ax), using starting point (p),
// and two other segments (their projections on two different planes)
function find_missing_dim(p, ax, seg1ax, seg1, seg2ax, seg2) = (
    let (p1_cand = find_missing_ax(p, ax, seg1ax, seg1))
    let (p2_cand = find_missing_ax(p, ax, seg2ax, seg2))
    let (not_defined = len(p1_cand)==0 || len(p2_cand)==0 ||
           (len(p1_cand)==2 && len(p2_cand)==2) ||
           (len(p1_cand)==1 && len(p2_cand)==1 && p1_cand[0] != p2_cand[0]) ||
           (len(p1_cand)==1 && len(p2_cand)==2 &&
               !(p1_cand[0] >= p2_cand[0] && p1_cand[0] <= p2_cand[1])) ||
           (len(p1_cand)==2 && len(p2_cand)==1 &&
               !(p2_cand[0] >= p1_cand[0] && p2_cand[0] <= p1_cand[1]))
        )
    let (missing_dim = len(p1_cand)==1 ? p1_cand[0] : 
                        (len(p2_cand)==1 ? p2_cand[0] : 0))
    not_defined ? [] : ([ [ for (a = [0,1,2]) a==ax ? missing_dim : p[a] ] ])
);

function find_ghosts(seg_xy, seg_xz, seg_yz) = (
    // look for z
    let (p1 = find_missing_dim(seg_xy[0], 2, 0, seg_xz, 1, seg_yz))
    let (p2 = find_missing_dim(seg_xy[1], 2, 0, seg_xz, 1, seg_yz))
    // look for y
    let (p3 = find_missing_dim(seg_xz[0], 1, 0, seg_xy, 2, seg_yz))
    let (p4 = find_missing_dim(seg_xz[1], 1, 0, seg_xy, 2, seg_yz))
    // look for x
    let (p5 = find_missing_dim(seg_yz[0], 0, 1, seg_xy, 2, seg_xz))
    let (p6 = find_missing_dim(seg_yz[1], 0, 1, seg_xy, 2, seg_xz))
    // add all possible points together
    let (points_flattened = concat(p1, p2, p3, p4, p5, p6))
    // return longest segment
    len(points_flattened) > 1 ? find_longest_seg(points_flattened) : []
);
