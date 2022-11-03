require 'sinatra'
require 'httparty'
require 'active_support'

GITHUB_API = "https://api.github.com/search/repositories".freeze
#
# helpers
#
helpers do
  def error(opts = {})
    body = "<h1>error!</h1>"
    body << "<p> Something unexpected, could not get any results, please try again<p>"
    body << "<p> error_log: #{opts[:message]} <p>" if opts[:message]
    body << "\n <a href='/'>back to search</a>"
    body
  end
end

#
# root_path 
# where we sdearch for the keywords
#
get('/') do
  body = "<h1>Search for Github public repositories</h1>\n"
  body << "<h4>Enter you keywords</h4>\n"
  body << "<form action=\"/search\" method=\"get\">\n"
  body << '<label for="search">Search: </label><input type="text" id="search" name="search" required><br><br>'
  body << '<input type="submit" value="Submit">'
end

#
# search route 
#  use api.github.com/search/repositories api to search
#   api returns total count for the search keyword
#   plus the repository details in an array
#   api supports pagination default is 30 per page and upto 100
# 
# results may contain total count, but public repostories may be empty
#   in that case we show total count with message showing no items to display
#
get('/search') do
  page = params[:page].to_i <= 0 ? 1 : params[:page].to_i
  response = HTTParty.get("#{GITHUB_API}?q=#{params[:search]}&page=#{page}")
  unless response.present?
    return error(message: 'response was empty')
  end
  if response['errors'].blank? && response['total_count'].blank?
    return error(message: response)
  end
  if response['errors'].present? 
    body = "<h1>error!</h1>"
    body << "<p> #{response['message']} - #{response['errors']} </p>\n"
    body << "\n <a href='/'>back to search</a>"
  else
    body = "<h3>List of public repositories.</h3>\n"
    body << "Note: <i>showing only 1000 public repositories : per page 30</i>\n"
    body << "<p>search term: #{params[:search]}\t <a href='/'>back to search</a> </p>" 
    body << "<p>total count: #{response['total_count']}.</p> \n"
    unless response['items'].present?
      body << "<p>No public repositories to display for now</p> \n"
      return body
    end
    next_page = page + 1 if (response['items'].count*page) < response['total_count']
    body << "<a href='/search?search=#{params[:search]}&page=#{page - 1}'>previous page</a> \t / " if (next_page && page != 1)
    body << "<a href='/search?search=#{params[:search]}&page=#{next_page}'>next page</a>" if next_page
    response['items'].each do |item|
      body << "<h3> #{item['name']}</h3>"
      body << "<ul>"
      body << "<li>ID: #{item['id']} </li>"
      body << "<li>Fullname: #{item['full_name']} </li>"
      body << "<li>Desc: #{item['description']} </li>"
      body << "<li>Owner: #{item['owner']['login']} </li>" if item['owner']
      body << "<li><a href='#{item['html_url']}'>visit repo</a> </li>" if item['html_url']
      body << "</ul>"
    end
  end
  body
end