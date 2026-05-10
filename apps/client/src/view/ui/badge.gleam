import glailwind_merge
import gva
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub type Variant {
  Default
  Secondary
  Destructive
  Outline
  Ghost
}

const base = "rounded inline-flex w-fit shrink-0 items-center justify-center gap-1 overflow-hidden rounded-full border border-transparent px-2 py-0.5 text-xs font-medium whitespace-nowrap transition-[color,box-shadow] focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 [&>svg]:pointer-events-none [&>svg]:size-3"

fn variant_classes(variant: Variant) -> String {
  gva.gva(
    default: base,
    resolver: fn(v) {
      case v {
        Default -> "bg-primary text-primary-foreground"
        Secondary -> "bg-secondary text-secondary-foreground"
        Destructive ->
          "bg-destructive text-white focus-visible:ring-destructive/20 dark:bg-destructive/60 dark:focus-visible:ring-destructive/40"
        Outline -> "border-border text-foreground"
        Ghost -> ""
      }
    },
    defaults: [],
  )
  |> gva.with(variant)
  |> gva.build()
}

pub fn view(
  variant variant: Variant,
  class class: String,
  attrs attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  let merged = glailwind_merge.tw_merge([variant_classes(variant), class])
  html.span(
    [
      attribute.attribute("data-slot", "badge"),
      attribute.class(merged),
      ..attrs
    ],
    children,
  )
}
