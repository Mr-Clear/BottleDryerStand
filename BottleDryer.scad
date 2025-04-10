include <BOSL2/std.scad>
include <scad-utils/morphology.scad>

// Resolution (higer is better)
$fn = 0;
// Thickness of all air flow walls
wall_thickness = 1;  // [0.1:0.01:5]
// Space between seperate printet parts to fit together
print_accuracy = 0.1;  // [-1:0.01:2]

stand_count = 4;  // [1:1:10]
// The maximal bottle diameter
stand_distance = 100;  // [20:1:1000]

/* [Fan] */
// Fan diameter
fan_diameter = 40;  // [40, 50, 60, 70, 80]
// Thickness of the plate where the fan is mounted
fan_plate_thickness = 2;  // [0.1:0.01:5]
// Screw diameter
fan_screw_diameter = 3;  // [1:0.1:10]

/* [Bottle Stand] */
// Maximum inner height of a bottle
bottle_height = 200;  // [10:1:1000]
// Inner diameter of a bottle
bottleneck_diameter = 17;  // [1:0.1:100]
// Length of the bottle neck
bottleneck_length = 30;  // [1:1:100]

support_thickness = 2;  // [0.1:0.01:5]
support_count = 5;      // [3,4,5,6,7,8,9]
// Maximal diameter of the bottle neck
support_diameter = 50;  // [10:1:100]
support_height = 20;    // [10:1:100]

/* [Hidden] */
epsilon = 0.001;

feed_length = max(stand_distance * stand_count / (2 * PI),
                  (stand_distance + fan_diameter) / 2 + wall_thickness);

bottleneck_radius = bottleneck_diameter / 2;
pipe_radius = bottleneck_diameter / 3;
feed_width = (pipe_radius - wall_thickness) * 2;
feed_radius = feed_width / 2;
flow_gate_height = min(feed_width, support_height - wall_thickness * 2);
fan_box_height = flow_gate_height;

fan_screw_distance_table = [
  [ 40, 32 ], [ 50, 40 ], [ 60, 50 ], [ 70, 60 ], [ 80, 71.5 ], [ 92, 82.5 ],
  [ 120, 105 ], [ 140, 124.5 ], [ 200, 154 ], [ 220, 170 ]
];
fan_screw_radius = lookup(fan_diameter, fan_screw_distance_table) / sqrt(2);

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

module stand(feed_length = 100) {
  difference() {
    union() {
      // The pipe
      cylinder(bottle_height + support_height, r = pipe_radius);
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
      intersection() {
        for (phi = [360 / (support_count * 2):360 /
                 support_count:360 - epsilon]) {
          rotate(phi) back(support_thickness / 2) xrot(90)
              linear_extrude(support_thickness) difference() {
            square([ support_diameter / 2, support_height ]);
            right(bottleneck_radius) gate([
              support_diameter / 2 - bottleneck_radius * 2 + pipe_radius -
                  wall_thickness,
              support_height / 1.5
            ]);
          }
        }
        cylinder(support_height, r = support_diameter / 2);
      }

      // Feed shell
      fwd(feed_radius + wall_thickness) rotate([ 90, 0, 90 ])
          linear_extrude(feed_length) gate([
            feed_width + wall_thickness * 2,
            min(feed_width + wall_thickness * 2, support_height)
          ]);

      // Base
      cylinder(wall_thickness, r = support_diameter / 2);
      difference() {
        cylinder(support_height / 4, r = support_diameter / 2);
        cylinder(support_height / 4 + epsilon,
                 r = support_diameter / 2 - wall_thickness);
      }
    }
    // Air flow
    up(wall_thickness) {
      // Pipe
      cylinder(bottle_height + support_height,
               r = pipe_radius - wall_thickness);
      // Feed
      fwd(feed_radius) rotate([ 90, 0, 90 ])
          linear_extrude(feed_length + epsilon)
              gate([ feed_width, flow_gate_height ]);
    }
  }
  // Air direction
  difference() {
    intersection() {
      cylinder(feed_radius, r = feed_radius);
      translate([ -feed_width, -feed_radius ])
          cube([ feed_width, feed_width, feed_width ]);
    }
    translate([ 0, feed_radius, feed_radius + wall_thickness ]) xrot(90)
        cylinder(feed_width, r = feed_radius);
  }
}

module main_part() {
  difference() {
    union() {
      mirror() for (i = [0:stand_count - 1]) {
        rotate(i * 360 / stand_count) translate([ -feed_length, 0, 0 ])
            stand(feed_length);
      }
      cylinder(fan_box_height + wall_thickness * 2,
               r = fan_diameter / 2 + wall_thickness - print_accuracy);
    }
    up(wall_thickness) {
      cylinder(fan_box_height + wall_thickness * 2 + epsilon,
               r = fan_diameter / 2 - print_accuracy);

      for (i = [0:stand_count - 1]) {
        rotate(i * 360 / stand_count) {
          fwd(feed_radius) rotate([ 90, 0, 90 ])
              linear_extrude(fan_diameter + epsilon)
                  gate([ feed_width, flow_gate_height ]);
        }
      }
    }
  }

  up(wall_thickness) difference() {
    cylinder(fan_box_height, r = fan_diameter / 2 - epsilon);
    rotate_extrude() translate([ fan_diameter / 2, fan_box_height, 0 ])
        scale([ fan_diameter / 200, fan_box_height / 100 ]) circle(100);
  }
}

module fan_cap() {
  difference() {
    union() {
      cylinder(fan_box_height / 2 + print_accuracy,
               r = fan_diameter / 2 + wall_thickness * 2);
      up((fan_box_height + fan_plate_thickness + print_accuracy) / 2 + epsilon)
          cube(
              [
                fan_diameter + wall_thickness * 4,
                fan_diameter + wall_thickness * 4,
                fan_plate_thickness

              ],
              center = true);
    }
    down(epsilon) cylinder(fan_box_height / 2 + print_accuracy + epsilon * 2,
                           r = fan_diameter / 2 + wall_thickness);
    down(epsilon) cylinder(fan_box_height + fan_plate_thickness + epsilon * 2,
                           r = fan_diameter / 2 - wall_thickness);
    down(fan_box_height / 2 - print_accuracy) for (i = [0:stand_count - 1]) {
      rotate(i * 360 / stand_count) {
        fwd(feed_radius) rotate([ 90, 0, 90 ])
            linear_extrude(fan_diameter / 2 + wall_thickness * 2 + epsilon)
                left(print_accuracy / 2)
                    gate([ feed_width + print_accuracy, flow_gate_height ]);
      }
    }
    echo(fan_diameter, lookup(fan_diameter, fan_screw_distance_table),
         fan_screw_radius);
    // Screw holes
    up(fan_box_height / 2 + print_accuracy / 2) for (phi = [45:90:360]) {
      zrot(phi) translate([ fan_screw_radius, 0, 0 ]) cylinder(
          fan_plate_thickness + epsilon * 2, r = fan_screw_diameter / 2);
    }
  }
}

main_part();
translate([ 0, 0, fan_box_height / 2 + wall_thickness * 2 ]) fan_cap();