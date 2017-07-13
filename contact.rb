class Contact
  attr_reader :id, :ip, :port, :last_seen
  attr_accessor :pingable

  def initialize(options)    ### {id: '2342342', ip: '23.24.55.8', port: 80}
    @id = options[:id]
    @ip = options[:ip]
    @port = options[:port] || 80
    @last_seen = Time.now
    @pingable = true
  end

  def update_last_seen
    @last_seen = Time.now
  end
end