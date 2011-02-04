MongoMapper.connection = Mongo::Connection.new("67.214.213.129", 27017)
#MongoMapper.connection = Mongo::Connection.new("127.0.0.1", 27017)
MongoMapper.database = "mongo-globe-development"#{Rails.env}"
