include <scad-utils/morphology.scad>

/* [General] */
// Resolution (Number of edges in a circle)
$fn = 200;
// The part to be printed
part = "MAIN";  // [ALL:"All Together (Not printable!)", MAIN:"Stand", CAP:"Cap to block air"]
// Thickness of all air flow walls
wall_thickness = 1.25;  // [0.1:0.01:5]
// Thickness of the floor
base_thickness = 1.4;  // [0.1:0.1:5]

stand_count = 5;  // [1:1:10]
// The maximal bottle diameter
stand_distance = 100;  // [20:1:1000]

// Base type
base_type = "SEPARATE";  // [SEPARATE:"Separate base for every stand", COMMON:"Common base for all stands"]

/* [Fan] */
// Fan diameter
fan_diameter = 40;  // [40, 50, 60, 70, 80, 92, 120, 140, 200, 220]
// Thickness of the plate where the fan is mounted. Determines the screw hole length
fan_plate_thickness = 2;  // [0.1:0.01:5]
// Screw diameter
fan_screw_diameter = 3.5;  // [1:0.01:10]

/* [Bottle Stand] */
// Maximum inner height of a bottle
bottle_height = 150;  // [10:1:1000]
// Inner diameter of a bottle
bottleneck_diameter = 17;  // [1:0.1:100]
// Length of the bottle neck
bottleneck_length = 30;  // [1:1:100]

support_thickness = 1.6;  // [0.1:0.01:5]
support_count = 5;        // [3,4,5,6,7,8,9]
// Maximal diameter of the bottle neck
support_diameter = 50;  // [10:1:100]
support_height = 15;    // [10:1:100]

/* [Cap] */
cap_height = 10;  // [0:0.1:20]
// Space between separate printed parts to fit together
print_accuracy = 0.1;  // [-1:0.01:2]

/* [Hidden] */
epsilon = 0.001;

feed_length =
    max(stand_distance * stand_count / (2 * PI),
        (fan_diameter * sqrt(2) + support_diameter) / 2 + wall_thickness * 2);
support_radius = support_diameter / 2;
bank_height = support_height / 3;
bottleneck_radius = bottleneck_diameter / 2;
pipe_radius = bottleneck_diameter / 3;
feed_width = (pipe_radius - wall_thickness) * 2;
feed_radius = feed_width / 2;
flow_gate_height = min(feed_width, support_height - wall_thickness * 2);
fan_box_height = base_thickness + flow_gate_height + wall_thickness * 2;
fan_box_top = fan_box_height + fan_plate_thickness;
fan_radius = fan_diameter / 2;

fan_screw_distance_table = [
  [ 40, 32 ], [ 50, 40 ], [ 60, 50 ], [ 70, 60 ], [ 80, 71.5 ], [ 92, 82.5 ],
  [ 120, 105 ], [ 140, 124.5 ], [ 200, 154 ], [ 220, 170 ]
];
fan_screw_radius = lookup(fan_diameter, fan_screw_distance_table) / sqrt(2);

main();

module main() {
  if (part == "ALL") {
    main_part();
    for (i = [0:stand_count - 1]) {
      rotate(i * 360 / stand_count) translate([ feed_length, 0, 0 ])
          rotate([ 0, 0, 180 ]) up(bottle_height + support_height +
                                   wall_thickness + cap_height * 2)
              rotate([ 0, 180 ]) cap();
    }
  } else if (part == "MAIN") {
    main_part();
  } else if (part == "CAP") {
    cap();
  } else {
    echo("Unknown part: ", part);
  }
}

module main_part() {
  union() {
    difference() {
      union() {
        // Stands
        for (i = [0:stand_count - 1]) {
          rotate(i * 360 / stand_count) translate([ feed_length, 0, 0 ])
              rotate([ 0, 0, 180 ]) stand(feed_length);
        }
        // Fan Box
        cylinder(fan_box_top, r = fan_radius);
        intersection() {
          translate(-[ fan_radius, fan_radius, 0 ]) cube([
            fan_diameter, fan_diameter, fan_box_height + fan_plate_thickness
          ]);

          cylinder(fan_box_top, fan_radius, (fan_radius)*sqrt(2));
        }

        // Common Base
        if (base_type == "COMMON") {
          linear_extrude(base_thickness) common_base();
          linear_extrude(base_thickness + bank_height) shell(wall_thickness)
              common_base();
        }
      }
      // Air flow
      up(base_thickness) {
        cylinder(fan_box_top + epsilon, r = fan_radius - wall_thickness);

        for (i = [0:stand_count - 1]) {
          rotate(i * 360 / stand_count) {
            fwd(feed_radius) rotate([ 90, 0, 90 ])
                linear_extrude(fan_diameter + epsilon)
                    gate([ feed_width, flow_gate_height ]);
          }
        }
      }
      // Screw holes
      up(fan_box_top - fan_plate_thickness + epsilon) for (phi = [45:90:360]) {
        zrot(phi) translate([ fan_screw_radius, 0, 0 ])
            cylinder(fan_plate_thickness, r = fan_screw_diameter / 2);
      }
    }
    // Air direction
    up(base_thickness) difference() {
      cylinder(fan_box_height, r = fan_radius - epsilon);
      rotate_extrude() translate([ fan_radius + epsilon, fan_box_height, 0 ])
          scale([ 1, fan_box_height / fan_radius ]) circle(fan_radius);
    }
  }
}

module stand(feed_length = 100) {
  difference() {
    union() {
      // The pipe
      up(base_thickness)
          cylinder(bottle_height + support_height, r = pipe_radius);
      up(base_thickness + bottle_height + support_height) rotate_extrude()
          right(pipe_radius - wall_thickness / 2) circle(wall_thickness / 2);
      // Bottle neck spacers
      up(support_height) {
        intersection() {
          for (phi = [360 / (support_count * 2):360 /
                   support_count:360 - epsilon]) {
            rotate(phi) back(support_thickness / 2) xrot(90)
                linear_extrude(support_thickness) union() {
              translate([ 0, bottleneck_length, 0 ]) intersection() {
                circle(bottleneck_radius);
                square(bottleneck_radius);
              }
              square([ bottleneck_radius, bottleneck_length ]);
            }
          }
          cylinder(bottleneck_length + bottleneck_radius,
                   r = bottleneck_radius);
        }
      }

      // Support
      up(base_thickness) intersection() {
        for (phi = [360 / (support_count * 2):360 /
                 support_count:360 - epsilon]) {
          rotate(phi) back(support_thickness / 2) xrot(90)
              linear_extrude(support_thickness) difference() {
            square([ support_radius, support_height ]);
            right(bottleneck_radius) gate([
              support_radius - bottleneck_radius * 2 + pipe_radius -
                  wall_thickness,
              support_height / 1.5
            ]);
          }
        }
        cylinder(support_height, r = support_radius);
      }

      // Feed shell
      fwd(feed_radius + wall_thickness) rotate([ 90, 0, 90 ])
          linear_extrude(feed_length) union() {
        back(base_thickness) gate([
          feed_width + wall_thickness * 2,
          min(feed_width + wall_thickness + base_thickness, support_height)
        ]);
        square([ feed_width + wall_thickness * 2, base_thickness ]);
      }

      // Separate Base
      if (base_type == "SEPARATE") {
        cylinder(base_thickness, r = support_radius + wall_thickness * 2);
        difference() {
          cylinder(base_thickness + bank_height,
                   r = support_radius + wall_thickness * 2);
          cylinder(base_thickness + bank_height + epsilon,
                   r = support_radius + wall_thickness - bank_height);
          up(base_thickness + bank_height) rotate_extrude()
              right(support_radius + wall_thickness - bank_height)
                  circle(bank_height);
        }
        up(base_thickness + bank_height) rotate_extrude()
            right(support_radius + wall_thickness * 1.5)
                circle(wall_thickness / 2);
      }
    }
    // Air flow
    up(base_thickness) {
      // Pipe
      cylinder(bottle_height + support_height + epsilon,
               r = pipe_radius - wall_thickness);
      // Feed
      fwd(feed_radius) rotate([ 90, 0, 90 ])
          linear_extrude(feed_length + epsilon)
              gate([ feed_width, flow_gate_height ]);
    }
  }
  // Air direction
  up(base_thickness - wall_thickness) difference() {
    intersection() {
      cylinder(feed_radius, r = feed_radius);
      translate([ -feed_width, -feed_radius ])
          cube([ feed_width, feed_width, feed_width ]);
    }
    translate([ 0, feed_radius, feed_radius + wall_thickness ]) xrot(90)
        cylinder(feed_width, r = feed_radius);
  }
}

module cap() {
  union() {
    difference() {
      cylinder(cap_height + wall_thickness, r = pipe_radius + wall_thickness);
      up(wall_thickness)
          cylinder(cap_height + epsilon, r = pipe_radius + print_accuracy);
    }
    cylinder(cap_height + wall_thickness,
             r = pipe_radius - wall_thickness - print_accuracy);
  }
}

module common_base() {
  conv_hull() union() {
    for (i = [0:stand_count - 1]) {
      rotate(i * 360 / stand_count) translate([ feed_length, 0, 0 ])
          circle(r = support_radius + wall_thickness * 2);
      circle((fan_radius + wall_thickness) * sqrt(2));
    }
  }
}

// Creates a pointed arch.
module gate(size, pointiness = 0) {
  top = [ size[0] / 2, size[1] ];
  c = top / 2;
  d = [ c[1], -c[0] ] / norm(c);
  min_x = max(c[0] / d[0], -c[1] / d[1]);
  m = c + d * (min_x + pointiness);
  r = norm(m);
  right(top[0]) mirror_copy([ 1, 0 ]) left(top[0]) intersection() {
    translate(m) circle(r);
    square([ size[0] / 2, size[1] ]);
  }
}

module xrot(angle) { rotate([ angle, 0, 0 ]) children(); }
module yrot(angle) { rotate([ 0, angle, 0 ]) children(); }
module zrot(angle) { rotate([ 0, 0, angle ]) children(); }
module fwd(y) { translate([ 0, -y, 0 ]) children(); }
module back(y) { translate([ 0, y, 0 ]) children(); }
module up(z) { translate([ 0, 0, z ]) children(); }
module down(z) { translate([ 0, 0, -z ]) children(); }
module left(x) { translate([ -x, 0, 0 ]) children(); }
module right(x) { translate([ x, 0, 0 ]) children(); }

module mirror_copy(vec) {
  children();
  mirror(vec) children();
}