class AuthenticationGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)
  argument :class_name, :type => :string, :default => "User"

  def generate_layout

    # Copies auth files
    copy_file "app/controllers/api/v1/auth/omniauth_controller.rb", "app/controllers/api/v1/auth/omniauth_controller.rb"
    if !File.exist?("app/controllers/api/v1/auth/sessions_controller.rb")
      copy_file "app/controllers/api/v1/auth/sessions_controller.rb", "app/controllers/api/v1/auth/sessions_controller.rb"
    end
    copy_file "app/controllers/concerns/token_authentication.rb", "app/controllers/concerns/token_authentication.rb"
    copy_file "app/controllers/concerns/resource_loader.rb", "app/controllers/concerns/resource_loader.rb"
    copy_file "app/controllers/api/v1/base_controller.rb", "app/controllers/api/v1/base_controller.rb"
    copy_file "app/models/concerns/authenticatable.rb", "app/models/concerns/authenticatable.rb"
    copy_file "app/models/authentication.rb", "app/models/authentication.rb"
    directory "lib/custom_exception", "lib/custom_exception"

    # Configures routes
    if File.readlines("config/routes.rb").grep(/models auth/).size <= 0
      sub_file 'config/routes.rb', search = "Rails.application.routes.draw do", "#{search}\n\n#{route_code}\n"
    end
    replace("config/routes.rb", "models auth") do |match|
      "#{match}\n#{user_route_code}"
    end
    copy_migration "create_authentications"

    # Creates add_provider_to_model migration
    files = Dir["db/migrate/*add_provider_to_#{file_pluralized}.rb"]
    if files.empty?
      out_file = File.new("db/migrate/#{(Time.now.utc.strftime("%Y%m%d%H%M%S").to_i + rand(1..10)).to_s}_add_provider_to_#{file_pluralized}.rb", "w")
      out_file.puts(provider_migration)
      out_file.close
    end

    # Includes Authenticatable to model
    sub_file "app/models/#{file_name}.rb", search = "end","\n#{model_code}\n#{search}"

    # Creates model's controller
    out_file = File.new("app/controllers/api/v1/#{file_pluralized}_controller.rb", "w")
    out_file.puts(user_controller_code)
    out_file.close

    # Adds protect_from_forgery to application controller
    gsub_file 'app/controllers/application_controller.rb', 'class ApplicationController < ActionController::API', 'class ApplicationController < ActionController::Base'
    if File.readlines("app/controllers/application_controller.rb").grep(/protect_from_forgery/).size <= 0
      sub_file 'app/controllers/application_controller.rb', search = "class ApplicationController < ActionController::Base", "#{search}\n\n  protect_from_forgery with: :exception\n"
    end

    # Sets config.action_mailer
    if File.readlines("config/environments/development.rb").grep(/config.action_mailer/).size <= 0
      sub_file 'config/environments/development.rb', search = "Rails.application.configure do", "#{search}\n\n  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }\n"
    end

    # Adds middleware Flash, enable_dependency_loading, autoload_paths from lib
    if File.readlines("config/application.rb").grep(/dependency/).size <= 0
      replace("config/application.rb", "Rails::Application") do |match|
        "#{match}\n#{application_changes}"
      end
    end

  end

  protected

  def application_changes
<<RUBY
    config.middleware.use ActionDispatch::Flash
    config.enable_dependency_loading = true
    config.autoload_paths << Rails.root.join('lib')
RUBY
  end

  def copy_migration(filename)
    if self.class.migration_exists?("db/migrate", "#{filename}")
      say_status("skipped", "Migration #{filename}.rb already exists")
    else
      migration_template "db/migrate/#{filename}.rb", "db/migrate/#{filename}.rb"
    end
  end

  def self.next_migration_number(dir)
   Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def route_code
<<RUBY
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      # models auth
    end
  end
RUBY
  end

  def user_route_code
<<RUBY
      resources :#{file_pluralized}, except: [:edit, :new, :index, :destroy], shallow: true do
        member do
          put :password
          put :register_device
        end
        collection do
          namespace :auth do
            put 'omniauth/:provider' => 'omniauth#all'
            patch 'omniauth/:provider' => 'omniauth#all'
            post 'sign_in' => 'sessions#create'
            delete 'sign_out' => 'sessions#destroy'
          end
          post :reset_password
        end
      end
RUBY
  end

  def provider_migration
<<RUBY
class AddProviderTo#{class_pluralized} < ActiveRecord::Migration[5.0]
  def self.up
    change_table :#{file_pluralized} do |t|
      ## Database authenticatable
      t.string :provider, null: false, default: "email"
      t.string :uid, null: false
    end
  end

  def self.down
    # By default, we don't want to make any assumption about how to roll back a migration when your
    # model already existed. Please edit below which fields you would like to remove in this migration.
    raise ActiveRecord::IrreversibleMigration
  end
end
RUBY
  end

  def model_code
<<RUBY
  include Authenticatable
RUBY
  end

  def alias_methods
<<RUBY
  alias_method :#{file_name}, :create
RUBY
  end

  def user_controller_code
<<RUBY
  class Api::V1::#{class_pluralized}Controller < Api::V1::BaseController
    before_action :authenticate_user!, except: [:create, :reset_password]
    before_action :load_resource, except: [:create, :reset_password]

    # CRUDs
    def create
      @user = #{class_camelized}.create!(sign_up_params)
      bypass_authenticate(@user)
      render json: @user
    end

    def update
      authorize @user
      @user.update!(update_params)
      render json: @user
    end

    def show
      authorize @user
      render json: @user
    end

    # Custom actions
    def password
      authorize @user
      @user.update_with_password!(password_params)
    end

    def reset_password
      params.require(:email)
      #{class_camelized}.reset_password(params[:email])
      # No Content
    end

    def register_device
      require_parameters([:device_id, :device_os])
      authorize @user
      current_user.register_device(request.headers["client"], params[:device_id], params[:device_os])
      # No Content
    end

    ###
    private

      def sign_up_params
        require_parameters([:email, :password])
        params.permit(:email, :password)
      end

      def update_params
        params.permit(:email)
      end

      def password_params
        require_parameters([:current_password, :password])
        params.permit(:current_password, :password, :password_confirmation)
      end


  end

RUBY
  end

  private

  def destination_path(path)
    File.join(destination_root, path)
  end

  def sub_file(relative_file, search_text, replace_text)
    path = destination_path(relative_file)
    file_content = File.read(path)

    unless file_content.include? replace_text
      content = file_content.sub(/(#{Regexp.escape(search_text)})/mi, replace_text)
      File.open(path, 'wb') { |file| file.write(content) }
    end

    print "    \e[1m\e[31mmodified\e[0m\e[22m  #{relative_file}\n"
  end

  def replace(filepath, regexp, *args, &block)
    content = File.read(filepath).gsub(regexp, *args, &block)
    File.open(filepath, 'wb') { |file| file.write(content) }
  end

  def file_name
    class_name.underscore
  end

  def file_pluralized
    file_name.pluralize
  end

  def class_camelized
    class_name.camelize
  end

  def class_pluralized
    class_name.camelize.pluralize
  end

end
