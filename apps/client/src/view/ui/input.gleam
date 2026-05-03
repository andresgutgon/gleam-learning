import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

/// Standalone input with its own border, background, and focus ring.
pub fn view(attrs: List(Attribute(msg))) -> Element(msg) {
  html.input([
    attribute.class(
      "w-full min-w-0 flex-1 bg-background border border-border rounded-lg"
      <> " py-2 px-3 text-sm text-foreground placeholder:text-muted-foreground outline-none"
      <> " focus:border-faff-pink focus:ring-4 focus:ring-faff-pink/25 focus:bg-input-bg"
      <> " transition-[border-color,box-shadow,background-color]",
    ),
    ..attrs
  ])
}

/// Stripped variant for use inside an InputGroup fieldset.
/// The group provides the border, background, and focus ring.
pub fn group_control(attrs: List(Attribute(msg))) -> Element(msg) {
  html.input([
    attribute.attribute("data-slot", "input-group-control"),
    attribute.class(
      "w-full min-w-0 flex-1 bg-transparent rounded-none border-0 shadow-none"
      <> " py-2 px-3 text-sm text-foreground placeholder:text-muted-foreground outline-none",
    ),
    ..attrs
  ])
}
