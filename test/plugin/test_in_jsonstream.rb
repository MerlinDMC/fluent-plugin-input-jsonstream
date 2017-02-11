require_relative '../helper'
require 'fluent/test/driver/input'
require "fluent/plugin/in_jsonstream"

class JSONStreamInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  PORT = unused_port
  BASE_CONFIG = %[
    port #{PORT}
    tag test
  ]
  CONFIG = BASE_CONFIG + %[
    bind 127.0.0.1
  ]

  attr_reader :base_config

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::JSONStreamInput).configure(conf)
  end

  def create_tcp_socket(host, port, &block)
    if block_given?
      TCPSocket.open(host, port, &block)
    else
      TCPSocket.open(host, port)
    end
  end

  def test_configure_requires_tag
    assert_raise Fluent::ConfigError do
      create_driver("")
    end
  end

  def test_configuring_tag
    d = create_driver(BASE_CONFIG)
    assert_equal d.instance.tag, "test"
  end

  def test_simple_parse
    payload = '{"foo":"bar"}'
    expected = { 'foo' => 'bar' }

    d = create_driver(CONFIG)
    d.run(expect_records: 1) do
      create_tcp_socket('127.0.0.1', PORT) do |sock|
        sock.send(payload, 0)
      end
    end

    assert_equal 1, d.events.size
    assert_equal "test", d.events[0][0]
    assert d.events[0][1].is_a?(Fluent::EventTime)
    assert_equal expected, d.events[0][2]
  end

  def test_chunked_parse
    payloads = [
      '{"fo', 'o": "b', 'ar"}'
    ]
    expected = { 'foo' => 'bar' }

    d = create_driver(CONFIG)
    d.run(expect_records: 1) do
      create_tcp_socket('127.0.0.1', PORT) do |sock|
        payloads.each do |payload|
          sock.send(payload, 0)
        end
      end
    end

    assert_equal 1, d.events.size
    assert_equal "test", d.events[0][0]
    assert d.events[0][1].is_a?(Fluent::EventTime)
    assert_equal expected, d.events[0][2]
  end

  def test_chunked_multiple_parse
    payloads = [
      '{"fo', 'o": "b', 'ar"}',
      '{"fo', 'o": "b', 'az"}'
    ]
    expecteds = [
      { 'foo' => 'bar' },
      { 'foo' => 'baz' }
    ]

    d = create_driver(CONFIG)
    d.run(expect_records: 2) do
      create_tcp_socket('127.0.0.1', PORT) do |sock|
        payloads.each do |payload|
          sock.send(payload, 0)
        end
      end
    end

    assert_equal 2, d.events.size
    expecteds.each_with_index do |expected, i|
      assert_equal "test", d.events[i][0]
      assert d.events[i][1].is_a?(Fluent::EventTime)
      assert_equal expecteds[i], d.events[i][2]
    end
  end
end
