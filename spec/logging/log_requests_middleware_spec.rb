# frozen_string_literal: true

require 'spec_helper'
require 'rack'

RSpec.describe Logging::LogRequestsMiddleware do
  let(:status) { 200 }
  let(:headers) do
    Rack::Utils::HeaderHash.new({ 'content-type' => 'text/plain', 'content-length' => '3' })
  end
  let(:response) { [] }
  let(:url) { 'http://localhost:3000/index' }
  let(:header_auth) { 'Bearer fake_token' }

  let(:get_request) do
    { 'search' => 'search_username' }
  end
  let(:get_request_body) { get_request.to_json }

  let(:post_request) do
    { 'username' => 'test', 'location' => 'Chicago' }
  end
  let(:post_request_body) { post_request.to_json }

  let(:get_env) do
    Rack::MockRequest.env_for(
      url,
      method: 'POST',
      params: get_request_body
    )
  end
  let(:post_env) do
    Rack::MockRequest.env_for(
      url,
      method: 'POST',
      headers: { 'HTTP_AUTHORIZATION' => header_auth },
      params: post_request_body
    )
  end
  let(:app) do
    lambda do |_env|
      [status, headers, response]
    end
  end
  let(:middleware_instance) { described_class.new(app) }
  let(:http_authorization) { 'Bearer fake_token' }

  before(:each) do
    allow(app).to receive(:call).and_return([status, headers, response])
    allow_any_instance_of(NilClass).to receive(:empty?).and_return(true)
  end

  context 'skip logging URLs' do
    context 'documentation url' do
      let(:url) { 'http://localhost:3000/swagger' }

      it 'does not create log instance for accessing swagger documentation' do
        expect(Logging::Log).not_to receive('create!')
        expect(middleware_instance.call(get_env)).to eq([status, headers, response])
      end
    end

    context 'favicon url' do
      let(:url) { 'http://localhost:3000/favicon.ico' }

      it 'does not create log instance for accessing favicon' do
        expect(Logging::Log).not_to receive('create!')
        expect(middleware_instance.call(get_env)).to eq([status, headers, response])
      end
    end
  end

  context 'create Log record for GET requests' do
    before(:each) do
      get_env['HTTP_AUTHORIZATION'] = header_auth
    end

    context 'with empty request and response' do
      let(:get_request_body) { nil }

      it 'creates Log record with empty fields' do
        expect(Logging::Log).to receive('create!').with(
          request: '',
          headers: header_auth,
          url: '/index',
          response: nil
        )
        expect(middleware_instance.call(get_env)).to eq([status, headers, response])
      end
    end

    context 'with JSON request' do
      it 'creates Log record for ' do
        expect(Logging::Log).to receive('create!').with(
          request: get_request,
          headers: header_auth,
          url: '/index',
          response: nil
        )
        expect(middleware_instance.call(get_env)).to eq([status, headers, response])
      end
    end

    context 'with malformed requests' do
      let(:get_request_body) { 'some_text' }

      it 'returns logger' do
        expect(Logging::Log).not_to receive('create!')
        expect_any_instance_of(::ActiveSupport::Logger)
          .to receive(:error)
          .with("Request is not JSON! Body: #{get_request_body}")
        expect(middleware_instance.call(get_env)).to eq([status, headers, response])
      end
    end
  end

  context 'create Log record for POST requests' do
    let(:url) { 'http://localhost:3000/users/create' }

    before(:each) do
      post_env['HTTP_AUTHORIZATION'] = header_auth
    end

    context 'with empty request and response' do
      let(:post_request_body) { nil }

      it 'creates Log record with empty fields' do
        expect(Logging::Log).to receive('create!').with(
          request: '',
          headers: header_auth,
          url: '/users/create',
          response: nil
        )
        expect(middleware_instance.call(post_env)).to eq([status, headers, response])
      end
    end

    context 'with JSON request and JSON response' do
      let(:response_body) { { 'status' => 'ok' } }
      let(:response) { [response_body.to_json] }

      it 'creates Log record' do
        expect(Logging::Log).to receive('create!').with(
          request: post_request,
          headers: header_auth,
          url: '/users/create',
          response: response_body
        )
        expect(middleware_instance.call(post_env)).to eq([status, headers, response])
      end
    end

    context 'with malformed request' do
      let(:post_request_body) { 'some_text' }

      it 'returns logger' do
        expect(Logging::Log).not_to receive('create!')
        expect_any_instance_of(::ActiveSupport::Logger)
          .to receive(:error)
          .with("Request is not JSON! Body: #{post_request_body}")
        expect(middleware_instance.call(post_env)).to eq([status, headers, response])
      end
    end

    context 'with malformed response' do
      let(:post_response_body) { 'some_text' }
      let(:response) { [post_response_body] }

      it 'returns logger' do
        expect(Logging::Log).not_to receive('create!')
        expect_any_instance_of(::ActiveSupport::Logger)
          .to receive(:error)
          .with("Response is not JSON! Body: #{post_response_body}")
        expect(middleware_instance.call(post_env)).to eq([status, headers, response])
      end
    end
  end
end
