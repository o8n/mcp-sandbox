#!/usr/bin/env ruby

require 'json'

# Simple MCP client for testing MCP servers
class McpTestClient
  def initialize
    @request_id = 0
  end
  
  # Send a request to the MCP server
  def send_request(method, params = {})
    request = {
      jsonrpc: '2.0',
      id: @request_id,
      method: method,
      params: params
    }
    
    @request_id += 1
    
    puts "\n=== Sending Request ==="
    puts JSON.pretty_generate(request)
    puts "======================="
    
    STDOUT.puts(JSON.generate(request))
    STDOUT.flush
    
    # Read the response
    response_line = STDIN.gets
    
    if response_line
      response = JSON.parse(response_line)
      
      puts "\n=== Received Response ==="
      puts JSON.pretty_generate(response)
      puts "========================="
      
      return response
    else
      puts "\nNo response received"
      return nil
    end
  end
  
  # Run a series of test requests
  def run_tests
    # Test get_server_info
    puts "\n\n=== Testing get_server_info ==="
    send_request('get_server_info')
    
    # Test list_tools
    puts "\n\n=== Testing list_tools ==="
    tools_response = send_request('list_tools')
    
    if tools_response && tools_response['result'] && tools_response['result']['tools']
      tools = tools_response['result']['tools']
      
      # Test each tool
      tools.each do |tool|
        puts "\n\n=== Testing tool: #{tool['name']} ==="
        
        # Create sample arguments based on the tool's input schema
        args = {}
        
        if tool['input_schema'] && tool['input_schema']['properties']
          tool['input_schema']['properties'].each do |name, schema|
            # Generate a sample value based on the property type
            args[name] = case schema['type']
            when 'string'
              if schema['enum']
                schema['enum'].first
              else
                'test'
              end
            when 'number', 'integer'
              42
            when 'boolean'
              true
            when 'array'
              []
            when 'object'
              {}
            else
              nil
            end
          end
        end
        
        # Send the tool request
        send_request('call_tool', { name: tool['name'], arguments: args })
      end
    end
    
    # Test list_resources
    puts "\n\n=== Testing list_resources ==="
    resources_response = send_request('list_resources')
    
    if resources_response && resources_response['result'] && resources_response['result']['resources']
      resources = resources_response['result']['resources']
      
      # Test each resource
      resources.each do |resource|
        puts "\n\n=== Testing resource: #{resource['uri']} ==="
        send_request('read_resource', { uri: resource['uri'] })
      end
    end
    
    # Test list_resource_templates
    puts "\n\n=== Testing list_resource_templates ==="
    templates_response = send_request('list_resource_templates')
    
    if templates_response && templates_response['result'] && templates_response['result']['resource_templates']
      templates = templates_response['result']['resource_templates']
      
      # Test each resource template
      templates.each do |template|
        puts "\n\n=== Testing resource template: #{template['uri_template']} ==="
        
        # Create a sample URI by replacing parameters with test values
        uri = template['uri_template'].gsub(/\{([^}]+)\}/) { |_| 'test' }
        
        send_request('read_resource', { uri: uri })
      end
    end
    
    puts "\n\nAll tests completed!"
  end
end

# Run the tests if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  puts "MCP Test Client"
  puts "This script will send test requests to an MCP server."
  puts "To use, pipe this script to your MCP server and pipe the server's output back to this script."
  puts "Example: ruby test_client.rb | ruby hello_world_server.rb | ruby test_client.rb"
  puts "Press Ctrl+C to exit."
  
  # Check if we're running in a pipe
  if STDIN.tty?
    puts "\nError: This script should be used in a pipe with an MCP server."
    puts "Example: ruby test_client.rb | ruby hello_world_server.rb | ruby test_client.rb"
    exit 1
  end
  
  client = McpTestClient.new
  client.run_tests
end
