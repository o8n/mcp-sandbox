require 'json'
require 'logger'

module MCP
  # Error codes as defined in the MCP specification
  module ErrorCode
    PARSE_ERROR = -32700
    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS = -32602
    INTERNAL_ERROR = -32603
  end

  # MCP error class for handling protocol errors
  class Error < StandardError
    attr_reader :code, :message, :data

    def initialize(code, message, data = nil)
      @code = code
      @message = message
      @data = data
      super(message)
    end

    def to_h
      {
        code: @code,
        message: @message,
        data: @data
      }.compact
    end
  end

  # Main MCP Server class
  class Server
    attr_reader :info, :capabilities
    attr_accessor :onerror

    def initialize(info, capabilities = {})
      @info = info
      @capabilities = capabilities
      @request_handlers = {}
      @tools = {}
      @resources = {}
      @resource_templates = {}
      @logger = Logger.new(STDERR)
      @logger.level = Logger::INFO
      @onerror = ->(error) { @logger.error("[MCP Error] #{error}") }
    end

    # Register a request handler for a specific method
    def set_request_handler(method, &handler)
      @request_handlers[method] = handler
    end

    # Register a tool with the server
    def register_tool(name, description, input_schema, &handler)
      @tools[name] = {
        name: name,
        description: description,
        input_schema: input_schema,
        handler: handler
      }
      
      # Set up request handlers for tool-related methods
      set_request_handler('list_tools') do |_params|
        { tools: @tools.values.map { |t| t.slice(:name, :description, :input_schema) } }
      end
      
      set_request_handler('call_tool') do |params|
        tool_name = params['name']
        tool = @tools[tool_name]
        
        unless tool
          raise Error.new(ErrorCode::METHOD_NOT_FOUND, "Unknown tool: #{tool_name}")
        end
        
        result = tool[:handler].call(params['arguments'])
        { content: result }
      end
    end

    # Register a resource with the server
    def register_resource(uri, name, mime_type = nil, description = nil)
      @resources[uri] = {
        uri: uri,
        name: name,
        mime_type: mime_type,
        description: description
      }.compact
      
      # Set up request handlers for resource-related methods
      set_request_handler('list_resources') do |_params|
        { resources: @resources.values }
      end
    end

    # Register a resource template with the server
    def register_resource_template(uri_template, name, mime_type = nil, description = nil)
      @resource_templates[uri_template] = {
        uri_template: uri_template,
        name: name,
        mime_type: mime_type,
        description: description
      }.compact
      
      # Set up request handlers for resource template-related methods
      set_request_handler('list_resource_templates') do |_params|
        { resource_templates: @resource_templates.values }
      end
    end

    # Set up a handler for reading resources
    def set_resource_reader(&handler)
      set_request_handler('read_resource') do |params|
        uri = params['uri']
        result = handler.call(uri)
        { contents: result }
      end
    end

    # Start the server and listen for requests
    def start
      @logger.info("Ruby MCP Server starting...")
      
      # Set up basic request handlers
      set_request_handler('get_server_info') do |_params|
        {
          name: @info[:name],
          version: @info[:version],
          capabilities: @capabilities
        }
      end

      # Main request processing loop
      loop do
        line = STDIN.gets
        break unless line

        begin
          request = JSON.parse(line)
          id = request['id']
          method = request['method']
          params = request['params'] || {}

          handler = @request_handlers[method]
          if handler
            result = handler.call(params)
            send_response(id, result)
          else
            raise Error.new(ErrorCode::METHOD_NOT_FOUND, "Method not found: #{method}")
          end
        rescue Error => e
          send_error(id, e.code, e.message, e.data)
        rescue JSON::ParserError => e
          send_error(id, ErrorCode::PARSE_ERROR, "Parse error: #{e.message}")
        rescue StandardError => e
          @onerror.call(e)
          send_error(id, ErrorCode::INTERNAL_ERROR, "Internal error: #{e.message}")
        end
      end
    end

    private

    # Send a successful response
    def send_response(id, result)
      response = {
        jsonrpc: '2.0',
        id: id,
        result: result
      }
      STDOUT.puts(JSON.generate(response))
      STDOUT.flush
    end

    # Send an error response
    def send_error(id, code, message, data = nil)
      response = {
        jsonrpc: '2.0',
        id: id,
        error: {
          code: code,
          message: message,
          data: data
        }.compact
      }
      STDOUT.puts(JSON.generate(response))
      STDOUT.flush
    end
  end
end
