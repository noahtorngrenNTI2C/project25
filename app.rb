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

get('/quiz/show/:id') do
    p session
    db = SQLite3::Database.new("db/main_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM quizes WHERE id = ?", params[:id])
    owner_name = db.execute("SELECT * FROM users WHERE id = ?", result.first["owner_id"]).first["username"]
    questions = db.execute("SELECT questions.name FROM quz_ques INNER JOIN questions ON quz_ques.ques_id = questions.id WHERE quz_ques.quiz_id = ?", params[:id])
    puts questions

    slim(:"quiz/show", locals:{quiz: result.first, owner: owner_name, questions: questions})

end

# ska fixas
post('quizes') do
    
end

get('/quiz/:id/edit') do


end

get('/quiz/new') do
    slim(:"quiz/new")
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

get('/error') do
    slim(:error, locals:{error_message: "hej"})
end

before("/quiz/new") do
    puts "hej"
    puts !session[:user_id]
    if !session[:user_id]
        redirect('/error')
        #locals:{error_message: "Du måste vara inloggad för att skapa en quiz"}
    end
end

#H2 Svara på frågorna nedan    
#form action="quiz_answer" method="POST"
#    -questions.each do |question|
#        p #{question["name"]}
#        input type="text" name="#{question["name"]}" placeholder="Skriv svar"

post('/quiz/show/quiz_answer') do
    db = SQLite3::Database.new("db/main_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM quizes WHERE id = ?", params[:quiz_id])
    owner_name = db.execute("SELECT * FROM users WHERE id = ?", result.first["owner_id"]).first["username"]
    questions = db.execute("SELECT questions.name FROM quz_ques INNER JOIN questions ON quz_ques.ques_id = questions.id WHERE quz_ques.quiz_id = ?", params[:quiz_id])
    answers = db.execute("SELECT questions.answer FROM quz_ques INNER JOIN questions ON quz_ques.ques_id = questions.id WHERE quz_ques.quiz_id = ?", params[:quiz_id])
    

    responses = []
    questions.each do |question|
        response = params[question["name"].to_sym]
        responses << response
    end

    # se vilka svar som är rätt och fel och spara i sessionen

    answers.each_with_index do |answer,index|
        if responses[index].to_s == answers[index]["answer"].to_s
            puts "rätt svar"
            session[answers[index]["answer"].to_s.to_sym] = true
        else
            puts "fel svar"
            session[answers[index]["answer"].to_s.to_sym] = false
        end
    end

    session[("has_answered" + params[:quiz_id].to_s).to_sym] = true
    # skicka tillbaka svaren till quiz/show och visa vilka som var rätt

    redirect("/quiz/show/#{params[:quiz_id]}")

end