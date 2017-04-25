# encoding: utf-8

require 'cool.io'
require 'yajl'

require 'fluent/input'

module Fluent::Plugin
  class JSONStreamInput < Input
    Fluent::Plugin.register_input('jsonstream', self)

    helpers :server, :extract

    desc 'Tag of output events.'
    config_param :tag, :string
    desc 'The port to listen to.'
    config_param :port, :integer, default: 5170
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'

    config_param :blocking_timeout, :time, default: 0.5

    def configure(conf)
      super
    end

    def multi_workers_ready?
      true
    end

    def start
      super

      server_create_connection(:in_jsonstream_server, @port, bind: @bind) do |conn|
        parser = newParser()
        conn.data do |data|
          begin
            parser << data
          rescue Yajl::ParseError
            parser = newParser()
          end
        end
      end
    end

    private

    def newParser
      parser = Yajl::Parser.new(:symbolize_keys => false)
      parser.on_parse_complete = lambda { |record|
        tag = extract_tag_from_record(record)
        tag ||= @tag
        time ||= extract_time_from_record(record) || Fluent::EventTime.now

        # Use the recorded event time if available
        time = record.delete('timestamp').to_i if record.key?('timestamp')

        router.emit(tag, time, record)
      }
      parser
    end
  end
end
