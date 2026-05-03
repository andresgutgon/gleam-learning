import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import route

pub fn view(content: Element(msg)) -> Element(msg) {
  html.div([attribute.class("min-h-screen bg-background")], [
    view_header(),
    html.main([attribute.class("mx-auto max-w-5xl px-4 py-8")], [content]),
  ])
}

fn view_header() -> Element(msg) {
  html.header(
    [
      attribute.class("sticky top-0 z-50 w-full shadow"),
    ],
    [
      html.div(
        [
          attribute.class("px-6 h-14 flex items-center gap-8"),
        ],
        [
          html.a(
            [
              attribute.href(route.to_path(route.Contacts)),
              attribute.class("flex items-center gap-2.5 shrink-0"),
            ],
            [
              html.img([
                attribute.src("/logo.svg"),
                attribute.alt("Gleam CRM"),
                attribute.class("h-8 w-auto"),
              ]),
              html.span(
                [
                  attribute.class(
                    "font-bold text-base tracking-tight text-header-fg",
                  ),
                ],
                [
                  element.text("Gleam "),
                  html.span([attribute.class("text-faff-pink")], [
                    element.text("CRM"),
                  ]),
                ],
              ),
            ],
          ),
          nav_link(route.to_path(route.Contacts), "Contacts"),
          html.div([attribute.class("flex-1")], []),
          github_link(),
        ],
      ),
    ],
  )
}

fn nav_link(href: String, label: String) -> Element(msg) {
  html.a(
    [
      attribute.href(href),
      attribute.class(
        "text-base font-medium text-header-fg hover:text-faff-pink transition-colors",
      ),
    ],
    [element.text(label)],
  )
}

fn github_link() -> Element(msg) {
  html.a(
    [
      attribute.href("https://github.com/andresgutgon/gleam-learning"),
      attribute.attribute("target", "_blank"),
      attribute.attribute("rel", "noopener noreferrer"),
      attribute.class(
        "shrink-0 text-faff-pink hover:opacity-75 transition-opacity",
      ),
    ],
    [
      html.svg(
        [
          attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
          attribute.attribute("viewBox", "0 0 24 25"),
          attribute.attribute("aria-label", "GitHub"),
          attribute.class("h-6 w-6 fill-current"),
        ],
        [
          svg.path([
            attribute.attribute(
              "d",
              "M12 .568a12 12 0 1 0 0 24a12 12 0 0 0 0-24m3.163 21.783h-.093a.52.52 0 0 1-.382-.14a.52.52 0 0 1-.14-.372v-1.406q.01-.702.01-1.416a3.7 3.7 0 0 0-.151-1.029a1.83 1.83 0 0 0-.542-.874a8 8 0 0 0 2.038-.471a4.05 4.05 0 0 0 1.466-.964a3.84 3.84 0 0 0 .885-1.507a6.8 6.8 0 0 0 .3-2.129a4.1 4.1 0 0 0-.26-1.476a3.9 3.9 0 0 0-.795-1.284q.113-.283.162-.583a3.6 3.6 0 0 0-.04-1.376a5 5 0 0 0-.221-.763a.3.3 0 0 0-.111-.02h-.11a2.3 2.3 0 0 0-.674.11q-.36.106-.703.261a7 7 0 0 0-.661.343q-.322.192-.573.362a9.6 9.6 0 0 0-5.143 0a14 14 0 0 0-.572-.362a6 6 0 0 0-.672-.343a4.5 4.5 0 0 0-.705-.26a2.2 2.2 0 0 0-.662-.112h-.11a.3.3 0 0 0-.11.02a6 6 0 0 0-.23.764a3.8 3.8 0 0 0-.081.773q0 .304.051.603q.05.3.16.583a3.9 3.9 0 0 0-.792 1.284a4.1 4.1 0 0 0-.263 1.476a6.9 6.9 0 0 0 .292 2.119c.181.564.483 1.082.884 1.517c.415.422.915.75 1.466.964c.653.25 1.337.41 2.033.476a1.8 1.8 0 0 0-.452.633a3 3 0 0 0-.2.744a2.75 2.75 0 0 1-1.175.27a1.8 1.8 0 0 1-1.065-.301a2.9 2.9 0 0 1-.752-.823a3 3 0 0 0-.292-.382a2.7 2.7 0 0 0-.372-.343q-.2-.15-.432-.24a1.2 1.2 0 0 0-.481-.101q-.06 0-.12.01a.7.7 0 0 0-.162.02a.4.4 0 0 0-.13.06a.12.12 0 0 0-.06.1a.33.33 0 0 0 .14.242q.14.111.232.171l.03.02q.2.156.382.333q.169.148.3.331q.136.178.231.38q.11.202.231.464c.188.473.522.874.954 1.145c.453.243.961.364 1.476.351q.262 0 .522-.03q.258-.041.515-.091v1.743a.5.5 0 0 1-.533.521h-.062a10.285 10.285 0 1 1 6.324 0z",
            ),
          ]),
        ],
      ),
    ],
  )
}
