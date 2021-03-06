# GraphQL Metrics Extractor

[![Build Status](https://travis-ci.org/Shopify/graphql-metrics.svg?branch=master)](https://travis-ci.org/Shopify/graphql-metrics)

Extract as much much detail as you want from GraphQL queries, served up from your Ruby app and the [`graphql` gem](https://github.com/rmosolgo/graphql-ruby).
Compatible with the [`graphql-batch` gem](https://github.com/Shopify/graphql-batch), to extract batch-loaded fields resolution timings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-metrics'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphql-metrics

## Usage

You can get started quickly with all features enabled by instrumenting your queries
with an extractor class (defined below) and with `TimedBatchExecutor` passed as
a custom executor when initializing `GraphQL::Batch` instrumentation if you're using it.

```ruby
class Schema < GraphQL::Schema
  query QueryRoot
  mutation MutationRoot

  use LoggingExtractor # Replace me with your own subclass of GraphQLMetrics::Extractor!
  use GraphQL::Batch, executor_class: GraphQLMetrics::TimedBatchExecutor # Optional.
end
```

Define your own extractor class, inheriting from `GraphQLMetrics::Extractor`, and
implementing the methods below, as needed.

Here's an example of a simple extractor that logs out all GraphQL query details.

```ruby
class LoggingExtractor < GraphQLMetrics::Extractor
  def query_extracted(metrics, _metadata)
    Rails.logger.debug({
      query_string: metrics[:query_string],     # "query Project { project(name: "GraphQL") { tagline } }"
      operation_type: metrics[:operation_type], # "query"
      operation_name: metrics[:operation_name], # "Project"
      duration: metrics[:duration]              # 0.1
    })
  end

  def field_extracted(metrics, _metadata)
    Rails.logger.debug({
      type_name: metrics[:type_name],           # "QueryRoot"
      field_name: metrics[:field_name],         # "project"
      deprecated: metrics[:deprecated],         # false
      resolver_times: metrics[:resolver_times], # [0.1]
    })
  end

  # NOTE: Applicable only if you set `use GraphQL::Batch, executor_class: GraphQLMetrics::TimedBatchExecutor`
  # in your schema.
  def batch_loaded_field_extracted(metrics, _metadata)
    Rails.logger.debug({
      key: metrics[:key],                                 # "CommentLoader/Comment"
      identifiers: metrics[:identifiers],                 # "Comment/_/string/_/symbol/Class/?"
      times: metrics[:times],                             # [0.1, 0.2, 4]
      perform_queue_sizes: metrics[:perform_queue_sizes], # [3]
    })
  end

  def argument_extracted(metrics, _metadata)
    Rails.logger.debug({
      name: metrics[:name],                           # "post"
      type: metrics[:type],                           # "postInput"
      value_is_null: metrics[:value_is_null],         # false
      default_used: metrics[:default_used],           # false
      parent_input_type: metrics[:parent_input_type], # "PostInput"
      field_name: metrics[:field_name],               # "postCreate"
      field_base_type: metrics[:field_base_type],     # "MutationRoot"
    })
  end

  def variable_extracted(metrics, _metadata)
    Rails.logger.debug({
      operation_name: metrics[:operation_name],           # "MyMutation"
      unwrapped_type_name: metrics[:unwrapped_type_name], # "PostInput"
      type: metrics[:type],                               # "PostInput!"
      default_value_type: metrics[:default_value_type],   # "IMPLICIT_NULL"
      provided_value: metrics[:provided_value],           # false
      default_used: metrics[:default_used],               # false
    })
  end

  # Define this if you want to do something with the query just before query logging.
  def before_query_extracted(query, query_context)
    Rails.logger.debug({
      something_from_context: query_context[:something]
    })
  end

  # Return something `truthy` if you want skip query extraction entirely, based on the query or
  # for example its context.
  def skip_extraction?(_query)
    false
  end

  # Return something `truthy` if you want skip producing field resolution
  # timing metrics. Applicable only if `field_extracted` is also defined.
  def skip_field_resolution_timing?(_query, _metadata)
    false
  end

  # Use or clear state after metrics extraction
  def after_query_teardown(_query)
    # Use or clear state after metrics extraction, i.e. Flush metrics to Datadog, Kafka etc.
    #   i.e. kafka.producer.produce('graphql_metrics', @collected_metrics); kafka.producer.deliver_messages
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/graphql_metrics. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GraphQLMetrics project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/graphql-metrics/blob/master/CODE_OF_CONDUCT.md).
