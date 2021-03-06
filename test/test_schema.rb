# frozen_string_literal: true

class CommentLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    ids.flatten.each do |id|
      fulfill(id, { id: id, body: 'Great blog!' })
    end
  end
end

class Comment < GraphQL::Schema::Object
  description "A blog comment"

  field :id, ID, null: false
  field :body, String, null: false
end

class Post < GraphQL::Schema::Object
  description "A blog post"

  field :id, ID, null: false

  field :title, String, null: false do
    argument :upcase, Boolean, required: false
  end

  field :body, String, null: false do
    argument :truncate, Boolean, required: false, default_value: false
  end

  field :deprecated_body, String, null: false, method: :body, deprecation_reason: 'Use `body` instead.'

  field :comments, [Comment], null: true do
    argument :ids, [ID], required: false
    argument :tags, [String], required: false
  end

  def comments(args)
    CommentLoader.for(Comment).load_many(args[:ids]).then { |comments| comments }
  end
end

class PostInput < GraphQL::Schema::InputObject
  argument :title, String, "Title for the post", required: true
  argument :body, String, "Body of the post", required: true
end

class PostCreate < GraphQL::Schema::Mutation
  argument :post, PostInput, required: true

  field :post, Post, null: false

  def resolve(post:)
    { post: { id: 42, title: post.title, body: post.body } }
  end
end

class MutationRoot < GraphQL::Schema::Object
  field :post_create, mutation: PostCreate
end

class QueryRoot < GraphQL::Schema::Object
  field :post, Post, null: true do
    argument :id, ID, required: true
    argument :locale, String, required: false, default_value: 'en-us'
  end

  def post(id:, locale:)
    { id: 1, title: "Hello, world!", body: "... you're still here?" }
  end
end
