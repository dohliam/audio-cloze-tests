#!/usr/bin/ruby -KuU
# encoding: utf-8

# given an ISO language code (e.g. "de" or "fr"),
# return the corresponding language name (e.g. "German" or "French")
# 
# usage: ruby iso_to_lang_name.rb zh

require_relative 'languages.rb'

def get_lang_name(lang_code)
  @languages_hash[lang_code][0]
end

def get_local_name(lang_code)
  @languages_hash[lang_code][1]
end

if __FILE__==$0
  if ARGV[0]
    lang_code = ARGV[0]
    puts get_lang_name(lang_code)
  end
end
