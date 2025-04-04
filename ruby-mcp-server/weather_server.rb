#!/usr/bin/env ruby

require_relative 'lib/mcp_server'
require 'json'
require 'net/http'
require 'uri'

# This is an example MCP server that provides weather data
class WeatherServer
  API_KEY = ENV['OPENWEATHER_API_KEY']
  
  def initialize
    # Create a new MCP server instance
    @server = MCP::Server.new(
      {
        name: 'ruby-weather-server',
        version: '0.1.0'
      },
      {
        capabilities: {
          resources: {},
          tools: {}
        }
      }
    )
    
    # Set up error handling
    @server.onerror = ->(error) { STDERR.puts("[MCP Error] #{error}") }
    
    # Register tools and resources
    setup_tools
    setup_resources
    
    # Handle process termination
    trap('INT') do
      STDERR.puts("Shutting down Ruby MCP server...")
      exit(0)
    end
  end
  
  # Start the server
  def start
    STDERR.puts("Ruby Weather MCP server starting...")
    @server.start
  end
  
  private
  
  # Set up example tools
  def setup_tools
    # Register a tool to get weather forecast
    @server.register_tool(
      'get_forecast',
      'Get weather forecast for a city',
      {
        type: 'object',
        properties: {
          city: {
            type: 'string',
            description: 'City name'
          },
          days: {
            type: 'number',
            description: 'Number of days (1-5)',
            minimum: 1,
            maximum: 5
          }
        },
        required: ['city']
      }
    ) do |args|
      city = args['city']
      days = args['days'] || 3
      
      # Validate API key
      unless API_KEY
        return [{ type: 'text', text: 'Error: OPENWEATHER_API_KEY environment variable is not set', is_error: true }]
      end
      
      begin
        # This is a mock implementation - in a real server, you would call the OpenWeather API
        # For demonstration purposes, we'll return mock data
        forecast_data = mock_forecast_data(city, days)
        
        [{ type: 'text', text: JSON.pretty_generate(forecast_data) }]
      rescue StandardError => e
        [{ type: 'text', text: "Error fetching weather data: #{e.message}", is_error: true }]
      end
    end
    
    # Register a tool to get current weather
    @server.register_tool(
      'get_current_weather',
      'Get current weather for a city',
      {
        type: 'object',
        properties: {
          city: {
            type: 'string',
            description: 'City name'
          }
        },
        required: ['city']
      }
    ) do |args|
      city = args['city']
      
      # Validate API key
      unless API_KEY
        return [{ type: 'text', text: 'Error: OPENWEATHER_API_KEY environment variable is not set', is_error: true }]
      end
      
      begin
        # This is a mock implementation - in a real server, you would call the OpenWeather API
        weather_data = mock_current_weather(city)
        
        [{ type: 'text', text: JSON.pretty_generate(weather_data) }]
      rescue StandardError => e
        [{ type: 'text', text: "Error fetching weather data: #{e.message}", is_error: true }]
      end
    end
  end
  
  # Set up example resources
  def setup_resources
    # Register a static resource for Tokyo weather
    @server.register_resource(
      'weather://Tokyo/current',
      'Current weather in Tokyo',
      'application/json',
      'Real-time weather data for Tokyo'
    )
    
    # Register a resource template for any city
    @server.register_resource_template(
      'weather://{city}/current',
      'Current weather for a given city',
      'application/json',
      'Real-time weather data for a specified city'
    )
    
    # Set up a resource reader
    @server.set_resource_reader do |uri|
      match = uri.match(/^weather:\/\/([^\/]+)\/current$/)
      
      unless match
        raise MCP::Error.new(
          MCP::ErrorCode::INVALID_REQUEST,
          "Invalid URI format: #{uri}"
        )
      end
      
      city = URI.decode_www_form_component(match[1])
      
      # This is a mock implementation - in a real server, you would call the OpenWeather API
      weather_data = mock_current_weather(city)
      
      [
        {
          uri: uri,
          mime_type: 'application/json',
          text: JSON.pretty_generate(weather_data)
        }
      ]
    end
  end
  
  # Mock weather data for demonstration purposes
  def mock_current_weather(city)
    {
      city: city,
      temperature: rand(0..30),
      conditions: ['Sunny', 'Cloudy', 'Rainy', 'Snowy'].sample,
      humidity: rand(30..90),
      wind_speed: rand(0..30),
      timestamp: Time.now.iso8601
    }
  end
  
  # Mock forecast data for demonstration purposes
  def mock_forecast_data(city, days)
    (1..days).map do |day|
      {
        city: city,
        date: (Time.now + (day * 86400)).strftime('%Y-%m-%d'),
        temperature: {
          min: rand(-5..25),
          max: rand(0..35)
        },
        conditions: ['Sunny', 'Cloudy', 'Rainy', 'Snowy'].sample,
        humidity: rand(30..90),
        wind_speed: rand(0..30)
      }
    end
  end
  
  # In a real implementation, you would call the OpenWeather API
  def fetch_weather_data(city)
    uri = URI("http://api.openweathermap.org/data/2.5/weather")
    params = { q: city, appid: API_KEY, units: 'metric' }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "API request failed with status: #{response.code}"
    end
  end
end

# Start the server if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  server = WeatherServer.new
  server.start
end
