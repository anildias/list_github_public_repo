ENV['APP_ENV'] = 'test'

require './myapp'
require 'rspec'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe 'myapp' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:search_keyword) { 'test' }
  let(:total_count) { 2 }
  let(:items) { [
      {
        'id' => '1',
        'name' => 'test1',
        'fullname' => '1_test1',
        'owner' => {'login' => 'test1_owner'},
        'description' => 'test1_desc',
        'html_url' => 'https://test_url/test1'
      },
      {
        'id' => '2',
        'name' => 'test2',
        'fullname' => '2_test2',
        'owner' => {'login' => 'test2_owner'},
        'description' => 'test2_desc',
        'html_url' => 'https://test_url/test2'
      }
    ]
  }
  let(:api_error) {
    {'errors' => { 'error' => 'keyword should enter' }, 'message' => 'validation failed'}
  }
  let(:unexpected_error) { "Something unexpected, could not get any results, please try again" }

  it 'it takes to root_path' do
    get '/'
    last_response.body.include?('Search for Github public repositories')
    last_response.body.include?('Enter you keywords')
    last_response.body.include?('search')
    last_response.body.include?('Submit')
  end

  context 'valid search keywords' do
    it 'shows no repository to show if api response returns with empty items' do
      allow(HTTParty).to receive(:get).and_return({'total_count' => total_count, 'items' => []})
      params = { search: search_keyword } 
      get '/search', params: params
      last_response.body.include?('List of public repositories.')
      last_response.body.include?('Note: showing only 1000 public repositories : per page 30')
      last_response.body.include?("search term: #{search_keyword}")
      last_response.body.include?("total count: #{total_count}")
      last_response.body.include?('No public repositories to display for now')
    end

    it 'list repository contents for given keyword' do
      allow(HTTParty).to receive(:get).and_return({'total_count' => total_count, 'items' => items})
      params = { search: search_keyword } 
      get '/search', params: params
      last_response.body.include?("total count: #{total_count}")
      last_response.body.include?("#{items[0]['name']}")
      last_response.body.include?("#{items[0]['id']}")
      last_response.body.include?("#{items[0]['fullname']}")
      last_response.body.include?("#{items[0]['description']}")
      last_response.body.include?("#{items[0]['owner']['login']}")
      last_response.body.include?("#{items[0]['html_url']}")  
    end
  end

  context 'valid keywords were not given' do
    it 'return with an error hash' do
      allow(HTTParty).to receive(:get).and_return(api_error)
      params = { search: '' } 
      get '/search', params: params

      last_response.body.include?("#{api_error['message']}")
      last_response.body.include?("#{api_error['errors']}")
    end
  end

  context 'response were something else unexpected' do
    it 'shows error if api response was nil' do
      allow(HTTParty).to receive(:get).and_return(nil)
      params = { search: search_keyword } 
      get '/search', params: params

      last_response.body.include?("error")
      last_response.body.include?(unexpected_error)
    end

    it 'shows error if api response contains any other data set' do
      allow(HTTParty).to receive(:get).and_return({ 'data' => 'unexpected' })
      params = { search: search_keyword } 
      get '/search', params: params

      last_response.body.include?("error")
      last_response.body.include?(unexpected_error)
      last_response.body.include?("{'data' => 'unexpected'}")
    end
  end
end