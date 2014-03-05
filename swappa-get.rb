#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'open-uri'
require 'csv'

def all_pages
  noko = Nokogiri::HTML open('http://swappa.com/device/find')
  pages = noko.css('a').map { |a| a['href'] }
  pages.keep_if { |a| a.start_with? '/devices/' }
end

def all_devices
  all_pages().map do |page|
    noko = Nokogiri::HTML open("http://swappa.com/#{page}")
    noko.css('div.body').map do |body|
      prices = body.at_css('.prices').text.strip.match(/\$(\d+) - (\d+) \((\d+)\)/).captures.map(&:to_i)
      { title: body.at_css('.title').text.strip, subtitle: body.at_css('.subtitle').text.strip,
        quantity: prices[2], min_price: prices[0], max_price: prices[1] }
    end
  end.flatten!(1).uniq!
end

$devices = all_devices()

CSV.open("data.csv", "wb") do |csv|
  csv << $devices.first.keys
  $devices.each do |h|
    csv << h.values # unless h[:quantity] == 0
  end
end
