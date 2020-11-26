page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

helpers do
end

activate :external_pipeline,
  name: :webpack,
  command: build? ? "yarn run build" : "yarn run dev",
  source: ".tmp/dist",
  latency: 1

configure :development do
  activate :livereload
end

configure :build do
  activate :minify_html do |html|
    html.remove_input_attributes = false
  end
end
