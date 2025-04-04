#!/bin/bash

# Ruby MCP Server Setup Script

echo "Setting up Ruby MCP Server..."

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "Ruby is not installed. Please install Ruby before continuing."
    exit 1
fi

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
    echo "Bundler is not installed. Installing Bundler..."
    gem install bundler
fi

# Install dependencies
echo "Installing dependencies..."
bundle install

# Make server scripts executable
echo "Making server scripts executable..."
chmod +x weather_server.rb hello_world_server.rb test_client.rb

echo "Setup complete!"
echo ""
echo "To run the Hello World server:"
echo "./hello_world_server.rb"
echo ""
echo "To run the Weather server:"
echo "export OPENWEATHER_API_KEY=your_api_key  # Optional, will use mock data if not set"
echo "./weather_server.rb"
echo ""
echo "To test your MCP server:"
echo "./test_client.rb | ./hello_world_server.rb | ./test_client.rb"
echo ""
echo "To configure with Claude or other AI assistants, see mcp_config_example.json"
echo "and README.md for more information."
