#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'
require 'csv'

# require 'colorize'
# require 'pry'
# require 'csv'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def unbracket(str)
  return ['Independent', 'Independent'] if str.empty?
  cap = str.match(/^(.*?)\s*\((.*?)\)\s*$/) or return [str, str]
  return cap.captures 
end

def scrape_list(url)
  warn "Getting #{url}"
  noko = noko_for(url)
  noko.css('.views-table').xpath('.//tr[td]').each do |row|
    rel_link = row.css('.views-field-title a/@href').text
    data = { 
      id: rel_link.split('/').last,
      name: row.css('.views-field-title a').text.strip,
      constituency: row.css('.views-field-name').text.strip,
      tel: row.css('.views-field-field-phone-value').text.strip,
    }
    abs_link = URI.join(url, rel_link)
    scrape_mp(abs_link, data)
  end

  next_page = noko.css('li.pager-next a').find { |a| a.text.include? 'Next' }
  scrape_list(URI.join(url, next_page.attr('href'))) if next_page
end

def scrape_mp(url, data)
  noko = noko_for(url)
  party = noko.xpath('.//div[contains(@class,"field-label") and contains(.,"Political Party")]/following-sibling::div').text.strip
  data.merge!({ 
    image: noko.css('img.imagefield-field_contact_photo/@src').text,
    member_since: noko.xpath('.//div[@class="field-label" and contains(.,"Member Since")]/following::span[1]').text,
    party: unbracket(party).first,
    party_id: unbracket(party).last,
    term: 53,
    source: url.to_s,
  })
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://legislature.gov.lr/house')

