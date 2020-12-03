page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

MAIN_LOCALE = :it
AVAILABLE_LOCALES = [:de, :en, :it]

ignore '/localizable/*'

helpers do
  def t(key, options = {})
    I18n.t(key, **options)
  end

  def path(url, options = {})
    lang = options[:lang] || I18n.locale.to_s

    if lang.to_s == MAIN_LOCALE
      prefix = ''
    else
      prefix = "/#{lang}"
    end

    prefix + "/" + clean_from_i18n(url)
  end

  def clean_from_i18n(url)
    parts = url.split('/').select { |p| p && p.size > 0 }
    parts.shift if langs.map(&:to_s).include?(parts[0])

    parts.join("/")
  end

  def css_style_name
    dato.theme_setting.name.gsub("-", "_")
  end
end

activate :dato, token: ENV.fetch('DATO_API_TOKEN'), live_reload: true
activate :i18n, langs: AVAILABLE_LOCALES, mount_at_root: MAIN_LOCALE

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

def wine_list
  data.products.wines
end

AVAILABLE_LOCALES.each do |locale|
  prefix = locale == MAIN_LOCALE ? "" : "/#{locale}"

  proxy "#{prefix}/index.html",
        "/localizable/index.html",
        locale: locale

  wine_list.each do |wine|
    proxy "#{prefix}/products/#{wine.name.parameterize}.html", "/localizable/product.html", locals: {wine: wine}
  end
end
