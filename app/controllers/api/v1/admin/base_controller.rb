module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_admin!

        private

        attr_reader :current_admin_user

        def authenticate_admin!
          admin_user = AdminUser.find_by(id: session[:admin_user_id])
          return render_unauthorized unless admin_user&.active?

          @current_admin_user = admin_user
        end
      end
    end
  end
end
