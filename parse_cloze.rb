#!/usr/bin/ruby -KuU
# encoding: utf-8

require 'erb'
require 'fileutils'
require 'unicode_utils/downcase'

require_relative 'lib/asp_id.rb'
require_relative 'lib/iso_to_lang_name.rb'

def story_data(lang)
  md_source_dir = "sbc-source/" + lang

  shortcodes_txt = File.read("data/shortcodes.txt")
  shortcodes = {}
  shortcodes_txt.each_line do |line|
    idx, code = line.chomp.split("\t")
    shortcodes[idx] = code
  end

  levels_txt = File.read("data/levels.txt")
  levels = {}
  levels_txt.each_line do |line|
    idx, title, level = line.chomp.split("\t")
    levels[idx] = level
  end

  md_source = Dir.glob(md_source_dir + '/*')

  data_collector = {}

  md_source.sort.each do |md|
    metadata_hash = {}
    basename = File.basename(md)
    if basename == "README.md" then next end
    idx = get_idx(basename)
    data_collector[idx] = {}
    text = File.read(md)
    data_collector[idx]["idx"] = idx
    if text.match(/# (.*)/)
      data_collector[idx]["title"] = Regexp::last_match[1]
    end
    chapters = text.gsub(/^# .*\n+##\n/, "").gsub(/\n+##\n\*.*/m, "").split(/\n\n##\n/)
    metadata = text.gsub(/^[^\*].*\n/, "")
    author = metadata.scan(/^\* Text: (.*)/)[0][0]
    illustrator = metadata.scan(/^\* Illustration: (.*)/)[0][0]
    translator = ""
    if lang != "en"
      translator = metadata.scan(/^\* Translation: (.*)/)[0][0]
    end
    license = metadata.scan(/^\* License: \[(.*)\]/)[0][0].gsub(/CC\-/, "CC ")
    uniq = unique_words_story(chapters, lang)

    data_collector[idx]["shortcode"] = shortcodes[idx]
    data_collector[idx]["lang"] = lang
    data_collector[idx]["author"] = author
    data_collector[idx]["license"] = license
    data_collector[idx]["illustrator"] = illustrator
    data_collector[idx]["translator"] = translator
    data_collector[idx]["level"] = levels[idx]
    data_collector[idx]["full_text"] = text
    data_collector[idx]["chapters"] = chapters
    data_collector[idx]["uniq"] = uniq
  end
  data_collector
end

def unique_words_story(chapters, lang)
  words = chapters.join(" ").gsub(/\n+/, " ").gsub(/[\d\?\!\.,:;"\(\)«»„”“#…—።‹›]/, "").gsub(/\s+\-\s+/, " ").gsub(/  +/, " ").gsub(/ '/, " ").gsub(/' /, " ")
  exclude = ["anansi", "nyame", "juma", "anita", "simbegwire", "nozibele", "gingile", "ngede", "khalai", "lubukusu", "zama", "maathai", "wangari", "anna", "baba", "cathy", "thabo", "themba", "thuli", "zanele", "tingi", "andiswa", "nyar-kanyada", "nyar", "kanyada", "luo", "odongo", "apiyo", "cissy", "magozwe", "thomas", "vusi", "tom", "sakima", "kraal", "ugali", "vic-torrr", "puuuuussssshhh", "rahim", "chitik", "chitik-chitik-chitik", "SIE-ger"]
  word_array = words.split(" ")
  uniq_array = []
  word_array.each do |w|
    if exclude.include?(w) then next end
    if lang != "de"
      if /[[:upper:]]/.match(w) then next end
    end
    if w.match(/'s$/) then next end
    len = w.length
    if len >= 3
      uniq_array << w
    end
  end
  uniq_array.uniq
end

def compile_corpus(data_collector)
  corpus_collector = []
  data_collector.each do |d|
    idx = d[0]
    corpus_collector << data_collector[idx]["uniq"]
  end
  corpus = corpus_collector.flatten.uniq.sort
  corpus
end

def print_json(lang, data_collector)
  data_collector.each do |story|
    idx = story[0]
    candidates = data_collector[idx]["candidates"]
    output = "var candidates = {\n"
    candidates.each do |letter, words|
      output << "  \"#{letter}\":\"#{words.join(",")}\",\n"
    end
    output.gsub!(/,\Z/, "")
    output << "};\n"
    outdir_root = "json_output/"
    dir_name = outdir_root + lang + "/" + idx
    FileUtils.mkdir_p dir_name
    FileUtils.cp_r("css", outdir_root)
    FileUtils.cp_r("js", outdir_root)
    File.open(dir_name + "/" + idx + ".js", "w") {|f| f << output}
  end
end

def prep_candidates(data_collector, corpus)
  data_collector.each do |data|
    idx = data[0]
    uniq = data_collector[idx]["uniq"]
    firsts = []
    uniq.each do |u|
      f = u.gsub(/^'/, "").gsub(/(.).*/, "\\1")
      firsts << f
    end
    data_collector[idx]["first_letters"] = firsts.sort.uniq
    candidates = {}

    corpus.each do |c|
      f = c.gsub(/(.).*/, "\\1")
      if data_collector[idx]["first_letters"].include?(f)
        if candidates[f]
          candidates[f] << c
        else
          candidates[f] = [c]
        end
      end
    end
    data_collector[idx]["candidates"] = candidates
  end
end

def generate_index(data_collector)
  data_collector.each do |data|
    counter = 2
    idx = data[0]
    title = data_collector[idx]["title"]
    lang = data_collector[idx]["lang"]
    level = data_collector[idx]["level"]
    chapters = data_collector[idx]["chapters"]

    uniq = data_collector[idx]["uniq"].sort
    uniqout = 'var uniq = ["'
    uniq.each do |u|
      uniqout << u + '","'
    end
    uniqout.gsub!(/,"\Z/, "];")
    output = "var chapters = [\n"
    chapters.each do |ch|
      padding = "0"
      if counter > 9
        padding = ""
      end
      page = padding + counter.to_s
      text = ch.gsub(/\s*\n\s*/, " ")

      words = text.gsub(/[\d\?\!\.,"\(\)«»„”“#…—።‹›]/, "").gsub(/\s+\-\s+/, " ").gsub(/  +/, " ").gsub(/ '/, " ").gsub(/' /, " ").split(" ")
      chapter_candidates = []
      words.each do |w|
        if uniq.include?(w)
          chapter_candidates << w
        end
      end

      output << "        {\"p\":\"#{page}\",\"t\":\"#{text.gsub(/"/, '\"')}\",\"c\":\"#{chapter_candidates.join(",")}\"},\n"
      counter +=1

    end
    output.gsub!(/,\Z/, "")
    output << "      ];"

    $more = print_title_chips(data_collector)
    $chapters = output
    $lang = lang
    $idx = idx
    $title = title
    $uniq = uniqout
    $level = level

    rtl = ""
    if lang == "ar" || lang == "fa"
      rtl = "rtl_"
    elsif lang == "ur"
      rtl = "ur_"
    end
    template = ERB.new(File.read("templates/" + rtl + "template.rhtml")).result
    dir_name = "json_output/" + lang + "/" + idx
    FileUtils.mkdir_p dir_name
    html_name = dir_name + "/index.html"
    File.open(html_name, "w") { |o| o << template }
  end
end

def print_title_chips(data_collector)
  more = {}
  more["1"] = ""
  more["2"] = ""
  more["3"] = ""
  more["4"] = ""
  more["5"] = ""
  data_collector.each do |story|
    idx = story[1]["idx"]
    title = data_collector[idx]["title"]
    level = data_collector[idx]["level"]
    lang = data_collector[idx]["lang"]

    label = "          <label class=\"chip def\"><a href=\"../#{idx}/\">#{title}</a></label>\n"
    more[level] << label
  end
  out = ""
  more.each do |level, label|
    out << "        <h5 class=\"chip-heading\">Level #{level}:</h5>\n"
    out << label
  end
  out
end

lang = ARGV[0]

if !lang
  abort("  Please enter a language code.")
end

data_collector = story_data(lang)

corpus = compile_corpus(data_collector)
prep_candidates(data_collector, corpus)
print_json(lang, data_collector)

generate_index(data_collector)
