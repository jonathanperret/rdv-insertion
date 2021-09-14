module FilterRdvSolidaritesWebhooksConcern
  extend ActiveSupport::Concern

  SUPPORTED_EVENTS_FOR_MODELS_TYPES = {
    "Rdv" => %w[created destroyed]
  }.freeze

  included do
    before_action :check_webhook_auth!
    before_action :check_if_webhook_is_supported!
  end

  def check_webhook_auth!
    return if webhook_correctly_signed?

    render plain: 'webhook auth error', status: :bad_request
  end

  def check_if_webhook_is_supported!
    return if webhook_supported?

    render plain: "webhook event not handled", status: :ok
  end

  def webhook_supported?
    supported_events.present? && supported_events.include?(params[:meta][:event])
  end

  def supported_events
    SUPPORTED_EVENTS_FOR_MODELS_TYPES[params[:meta][:model]]
  end

  def webhook_correctly_signed?
    OpenSSL::HMAC.hexdigest("SHA256", ENV['RDV_SOLIDARITES_SECRET'], request.body.read) ==
      request.headers['X-Lapin-Signature']
  end
end
