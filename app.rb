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
    db = SQLite3::Database.new("db/main_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM quizes WHERE id = ?", params[:id])
    owner_name = db.execute("SELECT * FROM users WHERE id = ?", result.first["owner_id"]).first["username"]
    questions = db.execute("SELECT questions.name FROM quz_ques INNER JOIN questions ON quz_ques.ques_id = questions.id WHERE quz_ques.quiz_id = ?", params[:id])

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
        response = params[question["name"].to_sym] || ""
        responses << response
    end

    # se vilka svar som är rätt och fel och spara i sessionen

    answers.each_with_index do |answer,index|
        if responses[index].to_s == answers[index]["answer"].to_s
            puts "rätt svar"
            #nyckeln ska inte vara svaret utan frågan
            
            session[questions[index]["name"].to_s.to_sym] = true
            #session[answers[index]["answer"].to_s.to_sym] = true
        else
            puts questions[index]["name"].to_s.to_sym
            session[questions[index]["name"].to_s.to_sym] = false
            #session[answers[index]["answer"].to_s.to_sym] = false
        end
    end

    session[("has_answered" + params[:quiz_id].to_s).to_sym] = true
    # skicka tillbaka svaren till quiz/show och visa vilka som var rätt

    redirect("/quiz/show/#{params[:quiz_id]}")

end

post('/quiz/qustions') do
    db = SQLite3::Database.new("db/main_database.db")
    db.results_as_hash = true
   
    #Variabler 
    quiz_name = params[:quiz_name]
    
    #frågor
    qustion1 = params[:qustion1]
    qustion2 = params[:qustion2]
    qustion3 = params[:qustion3]
    qustion4 = params[:qustion4]
    qustion5 = params[:qustion5]
    qustion6 = params[:qustion6]

    #svar
    answer1 = params[:answer1]
    answer2 = params[:answer2]
    answer3 = params[:answer3]
    answer4 = params[:answer4]
    answer5 = params[:answer5]
    answer6 = params[:answer6]
    


    user_id = session[:user_id]
    #skapa quiz
    db.execute('INSERT INTO quizes (name, owner_id) VALUES (?,?)',[quiz_name,user_id])
    
    #hämta quiz_id
    quiz_id = db.execute('SELECT id FROM quizes WHERE name = ? AND owner_id = ?', [quiz_name,user_id]).first["id"]
    for i in 1..6 do
        # skapa frågor och svar
        #frågor
        db.execute('INSERT INTO questions (name, answer) VALUES (?,?)',[params["qustion" + i.to_s],params["answer" + i.to_s]])
        
        #hämta fråg_id
        ques_id = db.execute('SELECT id FROM questions WHERE name = ? AND answer = ?', [params["qustion" + i.to_s],params["answer" + i.to_s]]).first["id"]
        #quz_ques
        db.execute('INSERT INTO quz_ques (quiz_id, ques_id) VALUES (?,?)',[quiz_id,ques_id])
    end


    redirect('/quiz/index')
end

get('/quiz/delete/:id') do
    if params[:id] == "nil"
        user_id = session[:user_id]
        if user_id
            db = SQLite3::Database.new("db/main_database.db")
            db.results_as_hash = true
            result = db.execute("SELECT * FROM quizes WHERE owner_id = ?", user_id)
            slim(:"quiz/delete", locals:{quizes: result})
            
        else
            redirect('/error')
        end
    else
        db = SQLite3::Database.new("db/main_database.db")
        db.results_as_hash = true
        
        # ta fram frågorna som tillhör quizet
        questions = db.execute("SELECT questions.id FROM quz_ques INNER JOIN questions ON quz_ques.ques_id = questions.id WHERE quz_ques.quiz_id = ?", params[:id])

        # ta fram quz_ques som tillhör quizet
        quz_ques = db.execute("SELECT * FROM quz_ques WHERE quiz_id = ?", params[:id])

        questions.each do |question|
            db.execute("DELETE FROM questions WHERE id = ?", question["id"])
        end

        quz_ques.each do |quz|
            db.execute("DELETE FROM quz_ques WHERE quiz_id = ? AND ques_id = ?", [params[:id], quz["ques_id"]])
        end
        db.execute("DELETE FROM quizes WHERE id = ?", params[:id])
        redirect('/quiz/index')
    end
end