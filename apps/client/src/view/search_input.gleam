import gleam/option.{type Option}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import view/ui/input_group

pub fn view(
  value value: String,
  placeholder placeholder: String,
  on_input on_input: fn(String) -> msg,
  debounce_ms debounce_ms: Option(Int),
  icon icon: Option(Element(msg)),
  loading loading: Bool,
) -> Element(msg) {
  let left = case loading, icon {
    True, _ -> option.Some(spinner())
    False, slot -> slot
  }
  let input_event = case debounce_ms {
    option.None -> event.on_input(on_input)
    option.Some(ms) -> event.debounce(event.on_input(on_input), ms)
  }
  input_group.group([], [
    case left {
      option.None -> element.none()
      option.Some(el) -> input_group.addon(input_group.InlineStart, [el])
    },
    input_group.input([
      attribute.type_("text"),
      attribute.attribute("value", value),
      attribute.placeholder(placeholder),
      input_event,
    ]),
    case string.is_empty(value) {
      True -> element.none()
      False ->
        input_group.addon(input_group.InlineEnd, [
          html.button(
            [
              attribute.type_("button"),
              attribute.class(
                "icon-[lucide--x] text-base text-muted-foreground"
                <> " hover:text-foreground transition-colors"
                <> " pointer-events-auto",
              ),
              event.on_click(on_input("")),
            ],
            [],
          ),
        ])
    },
  ])
}

fn spinner() -> Element(msg) {
  html.span(
    [
      attribute.class(
        "icon-[lucide--loader-circle] text-base text-muted-foreground animate-spin",
      ),
    ],
    [],
  )
}
