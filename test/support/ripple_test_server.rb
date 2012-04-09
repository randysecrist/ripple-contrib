require 'riak/test_server'
require 'singleton'

require 'ripple'

ENV['RACK_ENV'] ||= 'test'

class RiakNotFound < StandardError; end

module Ripple
  # Extends the {Riak::TestServer} to be aware of the Ripple
  # configuration and adjust settings appropriately. Also simplifies
  # its usage in the generation of test helpers.
  class TestServer < Riak::TestServer
    include Singleton
    attr_accessor :remote

    # Creates and starts the test server
    def self.setup
      unless instance.remote
        instance.recreate
        instance.start
      end
    end

    # Clears data from the test server
    def self.mr_clear
      mphase = Riak::MapReduce::Phase.new({:type => :link, :function => {"source" => flush_riak()}})
      mphase.language = :erlang
      mphase.type = :map
      mr = Riak::MapReduce.new(Ripple.client).add("foo", "bar")
      mr.query << mphase
      mr.run
    end

    def self.clear(hard=false)
      # if map reduce clear has problems, use wipe hard
      self.mr_clear

      # uses basic riak-ruby test server commands
      #self.wipe hard
    end

    def self.destroy
      unless instance.remote
        instance.destroy
      end
    end

    def self.wipe(hard=false)
      if hard
        self.setup
      end
    end

    def find_riak
      dir = ENV['RIAK_BIN_DIR'] || ENV['PATH'].split(':').detect { |dir| File.exists?(dir+'/riak') }
      unless dir
        raise RiakNotFound.new <<-EOM

You must have riak installed and in your path to run the tests
or you can define the environment variable RIAK_BIN_DIR to
tell the tests where to find RIAK_BIN_DIR. For example:

    export RIAK_BIN_DIR=/path/to/riak/bin

      EOM
        exit 1
      end
      return dir
    end

    @private
    def initialize(options=Ripple.config.dup)
      if Ripple.config[:host] == "127.0.0.1"
        options[:env] ||= {}
        options[:env][:riak_kv] ||= {}
        if js_source_dir = Ripple.config.delete(:js_source_dir)
          options[:env][:riak_kv][:js_source_dir] ||= js_source_dir
        end
        options[:env][:riak_kv][:allow_strfun] = true
        options[:env][:riak_kv][:map_cache_size] ||= 0
        options[:env][:riak_core] ||= {}
        options[:env][:riak_core][:http] ||= [ Tuple[Ripple.config[:host], Ripple.config[:http_port]] ]
        options[:env][:riak_kv][:pb_port] ||= Ripple.config[:pb_port]
        options[:env][:riak_kv][:pb_ip] ||= Ripple.config[:host]
        options[:root] ||= (ENV['RIAK_TEST_PATH'] || '/tmp/.api.riak')
        options[:source] ||= find_riak
        options[:env][:riak_core][:slide_private_dir] ||= options[:root] + '/slide-data'
        super(options)
        @env[:riak_kv][:storage_backend] = :riak_kv_eleveldb_backend
      else
        @remote = true
      end
    end
  end
end

def flush_riak
  "fun(_, _, _) ->
            case application:get_env(riak_kv, storage_backend) of
                {ok, riak_kv_eleveldb_backend} ->
                    case application:get_env(eleveldb, data_root) of
                        {ok, Level} ->
                            os:cmd(io_lib:format(\"rm -rf ~s/*\", [Level]));
                        _ ->
                            throw(\"could not determine data_root for eleveldb\")
                    end;
                {ok, riak_kv_bitcask_backend} ->
                    case application:get_env(bitcask, data_root) of
                        {ok, Bitcask} ->
                            os:cmd(io_lib:format(\"rm -rf ~s/*\", [Bitcask]));
                        _ ->
                            throw(\"could not determine data_root for bitcask\")
                    end;
                _ ->
                    throw(\"unsupported backend\")
            end,
            [exit(Pid, kill) || {riak_kv_vnode, _, Pid} <- riak_core_vnode_manager:all_vnodes()],
            []
    end."
end

class TestServerShim
  def recycle(hard=false)
    Ripple::TestServer.clear hard
  end
end

$test_server = TestServerShim.new
