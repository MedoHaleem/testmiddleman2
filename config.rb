page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

AVAILABLE_LOCALES = [:it, :en, :de]
MAIN_LOCALE = AVAILABLE_LOCALES.first

ignore '/localizable/*'

module SharedMethods
  def wine_list
    data.products.wines
  end

  def locale_prefix(locale)
    prefix = locale == MAIN_LOCALE ? "" : "/#{locale}"
  end

  def wine_paths(wine)
    AVAILABLE_LOCALES.each.with_object({}) do |locale, acc|
      I18n.with_locale(locale) do
        acc[locale] = [
          locale_prefix(locale),
          I18n.t(:product_basepath),
          "#{wine.name.parameterize}.html"
        ].join("/")
      end
    end
  end

  def wine_path(wine, locale)
    wine_paths(wine)[locale]
  end

  def home_paths
    AVAILABLE_LOCALES.each.with_object({}) do |locale, acc|
      acc[locale] = "#{locale_prefix(locale)}/index.html"
    end
  end

  def home_path(locale)
    home_paths[locale]
  end
end

include SharedMethods

helpers do
  include SharedMethods

  def t(key, options = {})
    I18n.t(key, **options)
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

AVAILABLE_LOCALES.each do |locale|
  proxy home_paths[locale],
        "/localizable/index.html",
        locale: locale,
        locals: {urls: home_paths}

  wine_list.each do |wine|
    urls = wine_paths(wine)
    proxy urls[locale],
          "/localizable/product.html",
          locals: {wine: wine, urls: urls}
  end
end
