import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import modem
import router
import virtual_list/page_transition as vt_pt

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

pub type Msg {
  RouterSentMsg(router.Msg)
}

fn init(_) -> #(router.Model, Effect(Msg)) {
  let #(model, router_effect) = router.init(modem.initial_uri())
  let effects = [
    effect.from(fn(_) {
      vt_pt.install("^(/contacts|/)$", "^/contacts/(\\d+)$")
    }),
    modem.init(router.on_url_change) |> effect.map(RouterSentMsg),
    router_effect |> effect.map(RouterSentMsg),
  ]
  #(model, effect.batch(effects))
}

fn update(model: router.Model, msg: Msg) -> #(router.Model, Effect(Msg)) {
  case msg {
    RouterSentMsg(router_msg) -> {
      let #(new_model, eff) = router.update(model, router_msg)
      #(new_model, eff |> effect.map(RouterSentMsg))
    }
  }
}

fn view(model: router.Model) -> Element(Msg) {
  router.view(model) |> element.map(RouterSentMsg)
}
