module Api
  module V1
    module Admin
      class SessionsController < ApplicationController
        def create
          admin_user = AdminUser.authenticate(session_params[:email], session_params[:password])
          return render_unauthorized("invalid credentials") unless admin_user

          reset_session
          session[:admin_user_id] = admin_user.id

          render json: {
            admin_user: {
              email: admin_user.email,
              active: admin_user.active
            }
          }, status: :created
        end

        def destroy
          reset_session
          head :no_content
        end

        private

        def session_params
          params.permit(:email, :password)
        end
      end
    end
  end
end
