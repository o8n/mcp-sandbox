#!/usr/bin/env ruby

require_relative 'lib/mcp_server'

# This is a simple example MCP server that provides a "hello_world" tool
class HelloWorldServer
  def initialize
    # Create a new MCP server instance
    @server = MCP::Server.new(
      {
        name: 'ruby-hello-world-server',
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
    
    # Register tools
    setup_tools
    
    # Handle process termination
    trap('INT') do
      STDERR.puts("Shutting down Ruby MCP server...")
      exit(0)
    end
  end
  
  # Start the server
  def start
    STDERR.puts("Ruby Hello World MCP server starting...")
    @server.start
  end
  
  private
  
  # Set up example tools
  def setup_tools
    # Register a simple hello world tool
    @server.register_tool(
      'hello_world',
      'Say hello to someone',
      {
        type: 'object',
        properties: {
          name: {
            type: 'string',
            description: 'Name to greet'
          },
          language: {
            type: 'string',
            description: 'Language to use for greeting',
            enum: ['en', 'es', 'fr', 'de', 'ja']
          }
        },
        required: ['name']
      }
    ) do |args|
      name = args['name']
      language = args['language'] || 'en'
      
      greeting = case language
      when 'es'
        "¡Hola, #{name}!"
      when 'fr'
        "Bonjour, #{name}!"
      when 'de'
        "Hallo, #{name}!"
      when 'ja'
        "こんにちは、#{name}さん!"
      else
        "Hello, #{name}!"
      end
      
      [{ type: 'text', text: greeting }]
    end
    
    # Register a tool to get the current time
    @server.register_tool(
      'get_time',
      'Get the current time',
      {
        type: 'object',
        properties: {
          timezone: {
            type: 'string',
            description: 'Timezone (e.g., UTC, JST, PST)'
          }
        }
      }
    ) do |args|
      timezone = args['timezone'] || 'UTC'
      
      # This is a simple implementation that doesn't actually handle timezones properly
      # In a real implementation, you would use a proper timezone library
      current_time = Time.now.to_s
      
      [{ type: 'text', text: "Current time (#{timezone}): #{current_time}" }]
    end
  end
end

# Start the server if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  server = HelloWorldServer.new
  server.start
end
