require 'rubygems'
require 'sinatra'

set :sessions, true

get '/new_game' do
  erb :"/users/profile"
  erb :form
end

get '/bet' do
  erb :bet
end

get '/inline' do
  "Hi, direclty from the action!"
end

get '/template' do
  erb :my_template
end

get '/nested_template' do
  erb :"/users/profile"
end

get '/nothere' do
  redirect '/inline'
end

get '/form' do
  erb :form
end

post '/myaction' do
  puts params['username']
end