class LinebotController < ApplicationController
  require 'line/bot'
  require 'nokogiri'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    charset = nil
    html = open("https://baseball.yahoo.co.jp/mlb/teams/player/737794") do |f|
      charset = f.charset
      f.read
    end

    doc = Nokogiri::HTML.parse(html, nil, charset)

    ave = doc.search("table tr:first-child td")[1].inner_text
    homerun = doc.search("table tr:first-child td")[3].inner_text
    rbi = doc.search("table tr:first-child td")[5].inner_text
    hit = doc.search("table tr:first-child td")[7].inner_text

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
        when '打率'
          message = {
            type: 'text',
            text: "#{ave}です"
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }

    head :ok
  end
end
