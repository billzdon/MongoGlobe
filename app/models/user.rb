class User
  include MongoMapper::Document
  
  acts_as_mongo_globe
  
  many :thing_references do 
    def stuff
      puts "hey"
    end
    
    def other_stuff
      puts "bye"
    end
  end
  
end