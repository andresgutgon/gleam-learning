import lustre/element.{type Element}
import shared/contacts/contact.{
  type PipelineStage, ContactStage, CustomerStage, LeadStage, OpportunityStage,
}
import view/ui/badge

pub fn view(stage: PipelineStage) -> Element(msg) {
  let #(label, extra_class) = case stage {
    ContactStage -> #(
      "Contact",
      "border-amber-400/50 bg-amber-400/10 text-amber-800",
    )
    LeadStage -> #(
      "Lead",
      "border-unnamed-blue/55 bg-unnamed-blue/15 text-sky-800",
    )
    CustomerStage -> #(
      "Customer",
      "border-faff-pink/55 bg-faff-pink/10 text-aubergine",
    )
    OpportunityStage -> #(
      "Opportunity",
      "border-purple-400/50 bg-purple-400/10 text-purple-800",
    )
  }
  badge.view(variant: badge.Outline, class: extra_class, attrs: [], children: [
    element.text(label),
  ])
}
