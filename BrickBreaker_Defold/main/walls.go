# A trio of static collider boxes acting as the play-field walls.
# Three children, each a kinematic static box positioned at left, right, top.

embedded_components {
  id: "left_wall"
  type: "collisionobject"
  position { x: -8 y: 360 z: 0 }
  data: "type: COLLISION_OBJECT_TYPE_STATIC\n"
        "group: \"wall\"\n"
        "mask: \"ball\"\n"
        "restitution: 1.0\n"
        "embedded_collision_shape {\n"
        "  shapes { shape_type: TYPE_BOX index: 0 count: 3 }\n"
        "  data: 8.0\n"
        "  data: 360.0\n"
        "  data: 1.0\n"
        "}\n"
}
embedded_components {
  id: "right_wall"
  type: "collisionobject"
  position { x: 968 y: 360 z: 0 }
  data: "type: COLLISION_OBJECT_TYPE_STATIC\n"
        "group: \"wall\"\n"
        "mask: \"ball\"\n"
        "restitution: 1.0\n"
        "embedded_collision_shape {\n"
        "  shapes { shape_type: TYPE_BOX index: 0 count: 3 }\n"
        "  data: 8.0\n"
        "  data: 360.0\n"
        "  data: 1.0\n"
        "}\n"
}
embedded_components {
  id: "top_wall"
  type: "collisionobject"
  position { x: 480 y: 728 z: 0 }
  data: "type: COLLISION_OBJECT_TYPE_STATIC\n"
        "group: \"wall\"\n"
        "mask: \"ball\"\n"
        "restitution: 1.0\n"
        "embedded_collision_shape {\n"
        "  shapes { shape_type: TYPE_BOX index: 0 count: 3 }\n"
        "  data: 480.0\n"
        "  data: 8.0\n"
        "  data: 1.0\n"
        "}\n"
}
