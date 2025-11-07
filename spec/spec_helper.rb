# spec/spec_helper.rb

require 'jekyll'
require_relative '../lib/jekyll-collection-pages'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.before(:each) do
    # Set Jekyll log level to debug
    Jekyll.logger.log_level = :debug
  end

  def make_site(options = {})
    site_config = Jekyll.configuration(options.merge({
                                                       'source' => File.expand_path('./fixtures', __dir__),
                                                       'destination' => File.expand_path('./dest', __dir__)
                                                     }))
    site = Jekyll::Site.new(site_config)
    site.read
    site
  end
end
