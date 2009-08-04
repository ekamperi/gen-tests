#!/usr/pkg/bin/ruby

require 'socket'

MSGLEN = 512	# All characters of the message, including CR-LF.

class IrcConnection
	def initialize(nick, channels, server, port)
		@nick     = nick
		@channels = channels
		@server   = server
		@port     = port

		@stats    = IrcStatistics.new
	end

	def start_connection
		@conn = TCPSocket.new(@server, @port)

		# Register a connection to the IRC server
                send_msg("NICK #{@nick}")
		send_msg('USER guest tolmoon tolsun :Ronnie Reagan')

		# Join channel/s
		if @channels.nil?
			return
		elsif @channels.respond_to?("each")
			@channels.each do |channel|
				send_msg("join ##{channel}")
			end
		else
			send_msg("join ##{@channels}")
		end

		buffer = ''
		loop {
		        data, peer = @conn.recvfrom(MSGLEN)
			buffer += data

			messages = buffer.split("\r\n", -1)
			messages.each_cons(2) do |curmsg, nextmsg|
				msg = IrcMessage.new(curmsg)
				msg.parse
				#msg.dbgprint
				dispatch_message(msg)
			end
			buffer = (messages.last == '') ? '' : messages[-1]
		}
	end

	def close_connection
		@conn.close
	end

	def dispatch_message(msg)
		case msg.command
			when "ERROR"      then respondto_error(msg)
			when "PING"       then respondto_ping(msg)
			when "PRIVMSG"    then respondto_privmsg(msg)
		end
	end

	def send_msg(msg)
		@conn.send(msg + "\r\n", 0)
	end

	def respondto_error(msg)
		exit
	end

	def respondto_ping(msg)
		send_msg("PONG " + msg.params[0])
	end

	def respondto_privmsg(msg)
		# Did She talk ?
		if msg.name =~ /[Bb]eket/
			# If so in private or in channel ?
			# So that we know where to respond to Her.
			receiver = (msg.params[0] == @nick) ? msg.name : msg.params[0]
			# send_msg("PRIVMSG " + receiver + " :Beket stfu")
			begin
				send_msg("PRIVMSG " + receiver + " :" + eval(msg.params[1..-1].join(' ')).to_s())
			rescue Exception => exc
				send_msg("PRIVMSG " + receiver + " : Syntax error (rescued)")
			end
		end

		puts ">>>  #{msg.name} talked to #{msg.params[0]}"
		@stats.add_record(msg.params[0], msg.name)
	end
end

class IrcMessage
	attr_reader :name, :user, :host, :command, :params

        def initialize(message)
                @message = message.chomp
        end

        def dbgprint
                puts  @message
		puts  "name    = #{@name}"
		puts  "user    = #{@user}"
		puts  "host    = #{@host}"
		puts  "command = #{@command}"
		print "params  = "
		@params.each do |p|
			 print "#{p} "
		end
		puts
		puts
		puts
        end

	def parse
		 split_msg = @message.split(/[: ]/).reject { |i| i=="" }

		# The presence of a prefix is indicated with a single
		# leading colon. Then message becomes:
		# [':' <prefix> <SPACE>] <command> <params> <crlf>
		if @message =~ /^:/
			prefix = split_msg[0]
			parse_prefix(prefix)
			split_msg.shift
		end

		@command = split_msg[0]
		@params  = split_msg[1..-1]
	end

	def parse_prefix(prefix)
		# The syntax of the prefix is:
		# <servername> | <nick> ['!' <user>]['@' <host>]
		split_msg = prefix.split(/[!@]/)

		@name = split_msg[0]
		@user = split_msg[1]
		@host = split_msg[2]
	end

end

class IrcStatistics
	def initialize
		@channels = {}
	end

	def add_record(channel, nick)
		# puts "About to add #{nick} on #{channel}"

		# If there is no hash for the channel in discussion,
		# create a new one.
		if ! @channels.has_key?(channel)
			@channels[channel] = {}
		end

		# If this is the 1st time `nick' has talked to `channel',
		# initialize the respective hash to 1. We do this because
		# += on nil isn't allowed.
		if ! @channels[channel].has_key?(nick)
			@channels[channel][nick] = 1
		else
			@channels[channel][nick] += 1
		end
		p @channels
	end
end

threads = []
nicks = ['kelly^', 'stathis']

for nick in nicks
    threads << Thread.new(nick) { |aNick|

    conn = IrcConnection.new(aNick, ['asdf'], 'fm1.irc.gr', 6667)
    conn.start_connection
end

# Wait for threads to complete.
threads.each { |aThread|  aThread.join }
