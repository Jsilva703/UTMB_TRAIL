class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :render_unprocessable_entity
  rescue_from Tracking::Forbidden, with: :render_forbidden

  private

  def render_not_found(_error)
    render json: { error: "not found" }, status: :not_found
  end

  def render_unprocessable_entity(error)
    details = error.respond_to?(:record) && error.record ? error.record.errors.to_hash : {}
    render json: { error: "validation failed", details: details }, status: :unprocessable_entity
  end

  def render_forbidden(error)
    render json: { error: error.message }, status: :forbidden
  end

  def bearer_token
    request.authorization.to_s.match(/\ABearer (.+)\z/)&.captures&.first
  end
end
