require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :sessions


get('/') do
    
    
    slim(:start)
end 

get('/login') do
    
    slim(:login)
end

get('/register') do
    slim(:register)
end

get('/quiz/index') do
    db = SQLite3::Database.new("db/main_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM quizes")

    slim(:"quiz/index", locals:{quizes: result})
end

get('/quiz/:id') do
    db = SQLite3::Database.new("db/main_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM quizes WHERE id = ?", params[:id])
    
    slim(:"quiz/show", locals:{quiz: result.first})

end

# ska fixas
post('quizes') do
    title = params[:title]
    artist_id = params[:artist_id].to_i
    db = SQLite3::Database.new("db/main_database.db")
    db.execute("INSERT INTO albums (Title, ArtistId) VALUES (?, ?)",[title,artist_id])
    redirect('/albums')
end

get('/quiz/:id/edit') do


end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/main_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    #puts result
    pwdigest = result["PWdigest"]
    user_id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:user_id] = user_id
        redirect('/')
    else
        "fel lösernod"
    end

end

get('/logout') do
    session.clear
    redirect('/')
end

post('/users/new') do 
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password == password_confirm) 
      #registrera ny användare
      p "hej"
      passord_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/main_database.db')
      db.execute('INSERT INTO users (username,PWdigest) VALUES (?,?)',[username,passord_digest])
      
      
      redirect('/')
  
    else 
      #felhantering
      p "nej"
      "lösernorden matchade inte inte"
    end
  end