import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import view/ui/input as ui_input

pub type Align {
  InlineStart
  InlineEnd
  BlockStart
  BlockEnd
}

fn align_class(align: Align) -> String {
  case align {
    InlineStart ->
      "order-first flex items-center pl-3 gap-2 text-sm text-muted-foreground select-none [&_svg]:size-4 pointer-events-none"
    InlineEnd ->
      "order-last flex items-center pr-2 gap-2 text-sm text-muted-foreground select-none [&_svg]:size-4"
    BlockStart ->
      "order-first flex w-full items-center px-3 pt-2 gap-2 text-sm text-muted-foreground select-none"
    BlockEnd ->
      "order-last flex w-full items-center px-3 pb-2 gap-2 text-sm text-muted-foreground select-none"
  }
}

fn align_data(align: Align) -> String {
  case align {
    InlineStart -> "inline-start"
    InlineEnd -> "inline-end"
    BlockStart -> "block-start"
    BlockEnd -> "block-end"
  }
}

pub fn group(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.fieldset(
    [
      attribute.class(
        "group/input-group relative flex w-full min-w-0 rounded-lg border border-border bg-background m-0 p-0"
        <> " transition-[border-color,box-shadow,background-color]"
        <> " focus-within:border-faff-pink focus-within:ring-4 focus-within:ring-faff-pink/25 focus-within:bg-input-bg"
        <> " has-[>[data-align=block-end]]:flex-col has-[>[data-align=block-start]]:flex-col"
        <> " has-[>[data-align=inline-end]]:[&>input]:pr-1 has-[>[data-align=inline-start]]:[&>input]:pl-1",
      ),
      ..attrs
    ],
    children,
  )
}

pub fn input(attrs: List(Attribute(msg))) -> Element(msg) {
  ui_input.group_control(attrs)
}

pub fn addon(align: Align, children: List(Element(msg))) -> Element(msg) {
  html.div(
    [
      attribute.attribute("data-align", align_data(align)),
      attribute.class(align_class(align)),
    ],
    children,
  )
}
