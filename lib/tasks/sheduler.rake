namespace :sheduler do
  desc "This is called by the Heroku scheduler add-on"
  task :updated_feed => :environment do
    require 'line/bot'
    require 'nokogiri'
    require 'open-uri'

    client ||= Line::Bot::client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }

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
    records = {ave: ave, homerun: homerun, rbi: rbi, hit: hit}
    return records

    push = "打率#{ave}\n本塁打#{homerun}\n打点#{rbi}\n安打数#{hit}\n"
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "ok"
end
