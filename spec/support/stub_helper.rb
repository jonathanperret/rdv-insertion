module StubHelper
  def stub_rdv_solidarites_create_user(rdv_solidarites_user_id)
    stub_request(:post, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/users")
      .to_return(status: 200, body: { "user" => { "id" => rdv_solidarites_user_id } }.to_json)
  end

  def stub_rdv_solidarites_update_user(rdv_solidarites_user_id)
    stub_request(
      :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/users/#{rdv_solidarites_user_id}"
    ).to_return(
      status: 200,
      body: {
        user: { id: rdv_solidarites_user_id }
      }.to_json
    )
  end

  def stub_rdv_solidarites_get_organisation_user(rdv_solidarites_organisation_id, rdv_solidarites_user_id)
    stub_request(
      :get,
      "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/" \
      "#{rdv_solidarites_organisation_id}/users/#{rdv_solidarites_user_id}"
    ).to_return(
      status: 200,
      body: {
        user: { id: rdv_solidarites_user_id }
      }.to_json
    )
  end

  def stub_rdv_solidarites_invitation_requests(rdv_solidarites_user_id, rdv_solidarites_token = "123456")
    stub_request(:post, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/users/#{rdv_solidarites_user_id}/rdv_invitation_token")
      .with(headers: { "Content-Type" => "application/json" }.merge(session_hash(agent.email)))
      .to_return(body: { "invitation_token" => rdv_solidarites_token }.to_json)
  end

  def stub_geo_api_request(address)
    stub_request(:get, RetrieveGeolocalisation::API_ADRESSE_URL).with(
      headers: { "Content-Type" => "application/json" },
      query: { "q" => address }
    ).to_return(body: { "features" => [] }.to_json)
  end

  def stub_send_in_blue
    stub_request(:post, "https://api.sendinblue.com/v3/transactionalSMS/sms")
      .to_return(status: 200)
  end

  def stub_applicant_creation(rdv_solidarites_user_id)
    stub_rdv_solidarites_create_user(rdv_solidarites_user_id)
    stub_rdv_solidarites_update_user(rdv_solidarites_user_id)
    stub_send_in_blue
    stub_rdv_solidarites_get_organisation_user(rdv_solidarites_organisation_id, rdv_solidarites_user_id)
    stub_rdv_solidarites_invitation_requests(rdv_solidarites_user_id)
    stub_geo_api_request("127 RUE DE GRENELLE 75007 PARIS")
  end
end
