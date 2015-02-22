require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_BETTING_AMOUNT = 500

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    #correct for aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'C' then 'clubs'
      when 'S' then 'spades'
      when 'D' then 'diamonds'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end


    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @play_again = true
  end

  def loser!(msg)
    @loser = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @play_again = true
  end

  def tie!(msg)
    @winner = "<strong>It's a tie!</strong> #{msg}"
    @show_hit_or_stay_buttons = false
    @play_again = true
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/new_game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  @new_player_screen = true
  session[:player_pot] = INITIAL_BETTING_AMOUNT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty? || params[:player_name] =~ /\d/
    @error = "A real name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  @new_player_screen = false
  session[:player_bet] = nil
  if session[:player_pot].to_i == 0
    erb :loser
  else
    erb :bet
  end
end

post '/bet' do
  if params[:bet_amount].empty? || params[:bet_amount] =~ /[A-Za-z]/ || params[:bet_amount].to_i == 0
    @error = "Please enter a number"
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot].to_i
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})."
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/new_game'
  end
end

get '/new_game' do
  @new_player_screen = false
  session[:turn] = session[:player_name]

  # create a deck
  suits = ['H', 'D', 'S', 'C']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
    if player_total == BLACKJACK_AMOUNT
      winner!("#{session[:player_name]} hit blackjack.")
    end

  
  redirect '/game'

end

get '/game' do
  @new_player_screen = false
  erb :game
end

post '/game/player/hit' do
  @new_player_screen = false
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack.")
    
  elsif player_total > BLACKJACK_AMOUNT
    loser!("It looks like #{session[:player_name]} busted.")
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  @new_player_screen = false
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @new_player_screen = false
  session[:turn] = "dealer"
  
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT
   redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game, layout: false
end

post '/game/dealer/hit' do
  @new_player_screen = false
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @new_player_screen = false
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")

  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end

  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end

get '/loser' do
  erb :loser
end






