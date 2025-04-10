include <BOSL2/std.scad>
include <scad-utils/morphology.scad>

// Resolution (higer is better)
$fn = 0;
// Thickness of all air flow walls
wall_thickness = 1;  // [0.1:0.01:5]

stand_count = 4;  // [1:1:10]
// The maximal bottle diameter
stand_distance = 100;  // [20:1:1000]

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
  bottleneck_radius = bottleneck_diameter / 2;
  pipe_radius = bottleneck_diameter / 3;
  feed_width = (pipe_radius - wall_thickness) * 2;
  feed_radius = feed_width / 2;
  difference() {
    union() {
      // The pipe
      cylinder(bottle_height + support_height, pipe_radius, pipe_radius);
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
          cylinder(bottleneck_length + bottleneck_radius, bottleneck_radius,
                   bottleneck_radius);
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
        cylinder(support_height, support_diameter / 2, support_diameter / 2);
      }

      // Feed shell
      fwd(feed_radius + wall_thickness) rotate([ 90, 0, 90 ])
          linear_extrude(feed_length) gate([
            feed_width + wall_thickness * 2,
            min(feed_width + wall_thickness * 2, support_height)
          ]);

      // Base
      cylinder(wall_thickness, support_diameter / 2, support_diameter / 2);
      difference() {
        cylinder(support_height / 4, support_diameter / 2,
                 support_diameter / 2);
        cylinder(support_height / 4 + epsilon,
                 support_diameter / 2 - wall_thickness,
                 support_diameter / 2 - wall_thickness);
      }
    }
    // Air flow
    up(wall_thickness) {
      // Pipe
      cylinder(bottle_height + support_height, pipe_radius - wall_thickness,
               pipe_radius - wall_thickness);
      // Feed
      fwd(feed_radius) rotate([ 90, 0, 90 ])
          linear_extrude(feed_length + epsilon) gate([
            feed_width, min(feed_width, support_height - wall_thickness * 2)
          ]);
    }
  }
  // Air direction
  difference() {
    intersection() {
      cylinder(feed_radius, feed_radius, feed_radius);
      translate([ -feed_width, -feed_radius ])
          cube([ feed_width, feed_width, feed_width ]);
    }
    translate([ 0, feed_radius, feed_radius + wall_thickness ]) xrot(90)
        cylinder(feed_width, feed_radius, feed_radius);
  }
}

feed_length = stand_distance * stand_count / (2 * PI);
color("#0DDF") for (i = [0:stand_count - 1]) {
  rotate(i * 360 / stand_count) translate([ -feed_length, 0, 0 ])
      stand(feed_length);
}