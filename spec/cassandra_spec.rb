require 'spec_helper'

describe Killjoy::LogLineWriter do
  subject { Killjoy::LogLineWriter.new(session) }
  let(:configuration) { Killjoy::DatabaseConfiguration.new }
  let(:cluster) do
    ::Cassandra.cluster(
      compression: :lz4,
      consistency: :local_quorum,
      hosts: configuration.hosts,
      logger: Logger.new($stdout),
      nodelay: true,
      port: configuration.port,
      timeout: nil,
      idle_timeout: nil,
      trace: true,
    )
  end
  let(:session) { cluster.connect(configuration.keyspace) }

  it 'can insert into cassandra' do
    line = '68.146.201.97 - - [23/May/2015:00:08:05 -0400] "GET /favicon.ico HTTP/1.1" 200 1150 "https://45.55.246.47/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.152 Safari/537.36"'
    parser = Killjoy::LogParser.new
    log_line = parser.parse(line)
    json = JSON.parse(log_line.to_json, symbolize_names: true)

    session.batch do |batch|
      subject.save(json) do |statement, parameters|
        batch.add(statement, parameters)
      end
    end
  end
end
