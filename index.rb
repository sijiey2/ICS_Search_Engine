#!/Users/JessieYu/.rvm/rubies/ruby-2.4.1/bin/ruby
#
# Purpose: Create an index file
#          find tokens, remove stop words, stem tokens
#          create two files: invindex.dat, doc.dat
#          (invindex.data - records information of each token
#          doc.data - records information of each html page)
################################################

require 'mechanize'
require 'nokogiri'

# function that writes out data to a file
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

# function that takes the name of a file and loads in the stop words from the file
def load_stopwords_file(file)
  count = 0
  stop_hash = Hash.new
  file = File.open(file, "r")
  lines = file.readlines
  file.close
  for line in lines
    stop_hash[line] = count
    count += 1
  end
  return stop_hash
end

# function that returns a list of all the filenames in that directory
def list_files(dir)
  files = Dir.entries(dir).select {|f| !File.directory? f}
  return files
end

# function that find all tokens in a html page
def find_tokens(filename)
  page = Nokogiri::HTML(open(filename))
  list = page.text
  tokens = list.encode('UTF-8', :invalid => :replace).split(/\W+/)
  tokens.delete("")
  return tokens
end

# function that remove stop-words from the list of tokens
def remove_stop_tokens(tokens, stop_words)
  for token in tokens
    token.downcase!
    if stop_words[token]
      tokens.delete(token)
    end
  end
  return tokens
end

# function that stem each token
def stem_tokens(tokens)
  stem_tokens = Array.new

  tokens.each do |token|
    if token.length > 0 and token[-1] == 's'
      token = token[0..-2];
    end
    stem_tokens.push(token)
  end

  return stem_tokens
end

# function that count the number of each token in a file
# ex: {token1 => 2, token2 => 5, token5 => 8}
def count_tokens(token_list)
  tokens_hash = Hash.new
  for token in token_list
    if not tokens_hash[token]
      tokens_hash[token] = 1
    else
      tokens_hash[token] += 1
    end
  end
  return tokens_hash
end

# function that records information of each token
# ex: {"donald"=>[3, {"0.html"=>2, "10.html"=>2, "11.html"=>3]}
def inverted_index(tokens_hash, invindex, doc_name)
  tokens_hash.each do |key, value|
    if not invindex[key]
      content = Hash.new
      content[doc_name] = value
      invindex[key] = [1, content]
    else
      invindex[key][0] += 1
      invindex[key][1][doc_name] = value
    end
  end
  return invindex
end

# 
def read_index(index_file)
  index_hash = Hash.new
  index_file = File.open(index_file, "r")
  lines = index_file.readlines
  index_file.close
  for line in lines
    line = line.split(/\s+/)
    index_hash[line[0]] = line[1]
  end
  return index_hash
end

# function that records information of each html page
# ex: {"0.html"=>[313, "title", "http://www.ics.uci.edu/"], ...}
def documents(tokens_hash, docindex, doc_name, path_name)
  url = docindex[doc_name]
  page = Nokogiri::HTML(open(path_name))
  title = page.css("title").text
  title = title.split.join(" ")
  content = [tokens_hash.length, title, url]
  docindex[doc_name] = content
  return docindex
end


#################################################
# Main program. We expect the user to run the program like this:
#
#   ruby index.rb pages_dir/ index.dat
#
#################################################

# check that the user gave us 3 command line parameters
if ARGV.size != 2
  abort "Command line should have 3 parameters"
end

# fetch command line parameters
(pages_dir, index_file) = ARGV

# read in list of stopwords from file
stopwords = load_stopwords_file("stop.txt")

# get the list of files in the specified directory
file_list = list_files(pages_dir)

# create hash data structures to store inverted index and document index
invindex = {}
docindex = read_index(index_file)

# scan through the documents one-by-one
file_list.each do |doc_name|
  path_name = pages_dir + doc_name
  print "Parsing HTML document: #{doc_name} \n";

  tokens = find_tokens(path_name)
  tokens = remove_stop_tokens(tokens, stopwords)
  tokens = stem_tokens(tokens)
  tokens_hash = count_tokens(tokens)
  inverted_index(tokens_hash, invindex, doc_name)
  documents(tokens_hash, docindex, doc_name, path_name)
end

# save the hashes to the correct files
write_data("invindex.dat", invindex)
write_data("doc.dat", docindex)    

# done!
puts "Indexing Complete!";


