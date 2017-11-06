require 'sinatra'
require 'sinatra/reloader' if development?

configure do
  enable :sessions
  set :session_secret, "secret"
end

helpers do
    def flash
        @flash ||= FlashMessage.new(session)
    end
end

class FlashMessage
  #Simple flash messages
  # flash = FlashMessage.new(session)
  # flash.message = 'hello world'
  # flash.message # => 'hello world'
  # flash.message # => nil
    def initialize(session)
        @session ||= session
    end

    def message=(message)
        @session[:flash] = message
    end

    def message
        message = @session[:flash] #tmp get the value
        @session[:flash] = nil # unset the value
        message # display the value
    end
end

class Word

  attr_reader :word, :chars, :hidden_word, :lives
  
  def initialize(word)
    @word = word
    @chars = word_to_chars
    @hidden_word = chars_to_spaces
    @lives = 11 
    @incorrects = []
  end

  def word_to_chars
    @chars = @word.scan(/\S/)
  end

  def chars_to_spaces
    blank_spaces = @chars.collect {|x| x = '_'}
  end

  def flatten(array)
    flat = array.inject {|x,y| x + ' ' + y}
  end

  def word_to_spaces
    chars_to_spaces(@chars)
  end

  def guess_in_word?(guess)
    if @chars.include? guess 
      return true
    else
      return false
    end
  end

  def already_guessed?(guess)
    if @hidden_word.include?(guess) || @incorrects.include?(guess)
      return true
    else
      return false
    end
  end

  def space_to_letter(guess)
    locations = @chars.each_index.select {|i| @chars[i] == guess }
    locations.each {|i| @hidden_word[i] = guess}
  end

  def solved?
    if @hidden_word.none? {|i| i=='_'}
      return true
    else
      return false
    end
  end

  def incorrect_guess(guess)
    @lives -= 1 
    @incorrects << guess
  end

  def num_incorrects
    @incorrects.length
  end

  def incorrects
    incorrect_flattened = @incorrects.inject {|x,y| x + ', ' + y}
  end
end




#For setting the secret word. Get shows the set view, and the form within the view posts the word and stores it in the session cookie. 
get '/set' do
    session['word'] = nil
    erb :set
end

post '/set' do
  session['word'] = Word.new(params['word'])
  redirect '/'
end

get '/' do
  redirect '/set' unless session['word']
  word = session['word']
  char_spaces = word.flatten(word.hidden_word)
  incorrects = word.incorrects
  lives = word.lives
  erb :index, :locals => {:char_spaces => char_spaces, :incorrects => incorrects, :lives => lives}
end

post '/' do 
  guess = params['guess']
  word = session['word']
  incorrects = word.incorrects
  char_spaces = word.flatten(word.hidden_word)

  if word.already_guessed?(guess)
    flash.message = "You already guessed that letter!"
  elsif word.guess_in_word?(guess)
    word.space_to_letter(guess)
    char_spaces = word.flatten(word.hidden_word)
  else 
    #not in word
    word.incorrect_guess(guess)
    incorrects = word.incorrects
    flash.message = "That letter is not in the word!"
  end
  lives = word.lives
  if word.solved? || word.lives == 0
    redirect '/win'
  end
  erb :index, :locals => {:char_spaces => char_spaces, :incorrects => incorrects, :lives => lives}
end

get '/win' do
  word = session['word']
  if word.solved?
    flash.message = "You Win!"
  else 
    flash.message = "You Lose!"
  end
  erb :win
end

