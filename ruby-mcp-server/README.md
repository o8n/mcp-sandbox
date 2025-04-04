# Ruby MCP Server

A Ruby implementation of the Model Context Protocol (MCP) server. This library allows you to create MCP servers that can provide tools and resources to AI assistants.

## Overview

The Model Context Protocol (MCP) enables communication between AI assistants and locally running servers that provide additional tools and resources to extend the AI's capabilities. This Ruby implementation provides a framework for creating MCP servers that can be used with AI assistants that support the MCP protocol.

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd ruby-mcp-server
```

2. Install dependencies:
```bash
bundle install
```

## Usage

### Basic Server Setup

To create a basic MCP server, you need to:

1. Create a new instance of `MCP::Server`
2. Register tools and resources
3. Start the server

Here's a minimal example:

```ruby
#!/usr/bin/env ruby

require_relative 'lib/mcp_server'

# Create a new MCP server instance
server = MCP::Server.new(
  {
    name: 'my-mcp-server',
    version: '0.1.0'
  },
  {
    capabilities: {
      resources: {},
      tools: {}
    }
  }
)

# Register a simple tool
server.register_tool(
  'hello_world',
  'Say hello to someone',
  {
    type: 'object',
    properties: {
      name: {
        type: 'string',
        description: 'Name to greet'
      }
    },
    required: ['name']
  }
) do |args|
  name = args['name']
  [{ type: 'text', text: "Hello, #{name}!" }]
end

# Start the server
server.start
```

### Creating Tools

Tools are functions that can be called by the AI assistant. To create a tool, use the `register_tool` method:

```ruby
server.register_tool(
  'tool_name',           # Unique identifier for the tool
  'Tool description',    # Human-readable description
  {                      # JSON Schema for input parameters
    type: 'object',
    properties: {
      param1: {
        type: 'string',
        description: 'Description of param1'
      },
      param2: {
        type: 'number',
        description: 'Description of param2'
      }
    },
    required: ['param1'] # Array of required parameters
  }
) do |args|
  # Tool implementation
  # args is a hash containing the input parameters
  
  # Return an array of content items
  [{ type: 'text', text: "Result of the tool" }]
end
```

### Creating Resources

Resources are static or dynamic data that can be accessed by the AI assistant. To create a resource, use the `register_resource` method:

```ruby
# Register a static resource
server.register_resource(
  'resource://example/data',  # Unique URI for the resource
  'Example Data',             # Human-readable name
  'application/json',         # MIME type (optional)
  'Description of the data'   # Description (optional)
)

# Register a resource template for dynamic resources
server.register_resource_template(
  'resource://{param}/data',  # URI template with parameters
  'Dynamic Data',             # Human-readable name
  'application/json',         # MIME type (optional)
  'Description of the data'   # Description (optional)
)

# Set up a resource reader to handle resource requests
server.set_resource_reader do |uri|
  # Parse the URI to extract parameters
  match = uri.match(/^resource:\/\/([^\/]+)\/data$/)
  
  unless match
    raise MCP::Error.new(
      MCP::ErrorCode::INVALID_REQUEST,
      "Invalid URI format: #{uri}"
    )
  end
  
  param = URI.decode_www_form_component(match[1])
  
  # Generate the resource content
  data = { param: param, value: "Data for #{param}" }
  
  # Return an array of content items
  [
    {
      uri: uri,
      mime_type: 'application/json',
      text: JSON.generate(data)
    }
  ]
end
```

## Example Servers

This repository includes example MCP servers that demonstrate how to create tools and resources:

### Hello World Server

A simple example server that provides basic tools:
- `hello_world`: Says hello to a person in different languages
- `get_time`: Returns the current time

To run the Hello World server:

```bash
# Make the script executable
chmod +x hello_world_server.rb

# Run the server
./hello_world_server.rb
```

### Weather Server

A more complex example that demonstrates how to create tools and resources for providing weather data.

To run the Weather server:

```bash
# Set the OpenWeather API key (optional, will use mock data if not set)
export OPENWEATHER_API_KEY=your_api_key

# Make the script executable
chmod +x weather_server.rb

# Run the server
./weather_server.rb
```

## Testing Your MCP Server

This repository includes a test client that you can use to test your MCP server implementation. The test client sends a series of requests to the server and displays the responses.

To use the test client:

```bash
# Make the script executable
chmod +x test_client.rb

# Run the test client with your MCP server
./test_client.rb | ./your_server.rb | ./test_client.rb
```

For example, to test the Hello World server:

```bash
./test_client.rb | ./hello_world_server.rb | ./test_client.rb
```

The test client will send requests to test the server's capabilities and display the responses.

## Configuration with AI Assistants

To use your MCP server with an AI assistant that supports the MCP protocol, you need to add it to the assistant's MCP settings configuration. The exact location and format of this configuration depends on the assistant you're using.

For example, to add the weather server to Claude's MCP settings:

```json
{
  "mcpServers": {
    "weather": {
      "command": "ruby",
      "args": ["/path/to/ruby-mcp-server/weather_server.rb"],
      "env": {
        "OPENWEATHER_API_KEY": "your_api_key"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

## Error Handling

The MCP server includes error handling to ensure that errors are properly reported to the client. You can customize the error handling by setting the `onerror` callback:

```ruby
server.onerror = ->(error) { STDERR.puts("[Custom Error] #{error}") }
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
