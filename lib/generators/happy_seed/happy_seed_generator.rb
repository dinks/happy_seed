module HappySeed
  module Generators
    class HappySeedGenerator < Rails::Generators::Base
      protected
        def require_omniauth
          unless gem_available?( "devise" )
            puts "The omniauth generator requires devise"

            if yes?( "Run happy_seed:devise now?" )
              generate "happy_seed:devise"
            else
              exit
            end
          end

          unless File.exists? 'app/models/identity.rb'
            generate "happy_seed:omniauth"
          end
        end

        def add_omniauth( provider, scope = nil )
          scopeline = nil
          scopeline = ", scope: \"#{scope}\"" if scope
          inject_into_file 'config/initializers/devise.rb', after: "==> OmniAuth\n" do <<-"RUBY"
    config.omniauth :#{provider}, ENV['#{provider.upcase}_APP_ID'], ENV['#{provider.upcase}_APP_SECRET']#{scopeline}
  RUBY
          end
          append_to_file ".env", "#{provider.upcase}_APP_ID=\n#{provider.upcase}_APP_SECRET=\n"

          inject_into_file 'app/views/application/_header.html.haml', "          %li= link_to 'sign in with #{provider}', user_omniauth_authorize_path(:#{provider})\n", after: "/ CONNECT\n"
          inject_into_file 'app/views/devise/sessions/new.html.haml', "                = link_to 'sign in with #{provider}', user_omniauth_authorize_path(:#{provider})\n                %br\n", after: "/ CONNECT\n"
          inject_into_file 'app/views/devise/registrations/new.html.haml', "                = link_to 'sign in with #{provider}', user_omniauth_authorize_path(:#{provider})\n                %br\n", after: "/ CONNECT\n"
          inject_into_file 'app/controllers/omniauth_callbacks_controller.rb', "\n  def #{provider}\n    generic_callback( '#{provider}' )\n  end\n", before: /\s*def generic_callback/
        end
     
        def gem_available?(name)
          Gem::Specification.find_by_name(name)
        rescue Gem::LoadError
          false
        rescue
          Gem.available?(name)
        end

    end
  end
end