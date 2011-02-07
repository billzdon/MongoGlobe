class ThingReference
  include MongoMapper::EmbeddedDocument
  
  acts_as_mongo_globe
  
  key :thing_id, ObjectId
  belongs_to :thing
  
  key :name, String
  
  atomicize :name
end