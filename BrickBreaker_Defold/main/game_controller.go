components {
  id: "controller"
  component: "/main/game_controller.script"
}
embedded_components {
  id: "brick_factory"
  type: "factory"
  data: "prototype: \"/main/brick.go\"\n"
}
