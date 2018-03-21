#!/Users/JessieYu/.rvm/rubies/ruby-2.4.1/bin/ruby
#
# Purpose: 
# Retrieve pages with higher scores showing in the front
################################################

require 'fast_stemmer'

class Retrieval
# function that writes out data to a file
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

# function that reads data from files
def read_data(file_name)
  file = File.open(file_name,"r")
  object = eval(file.gets.untaint.encode('UTF-8', :invalid => :replace))
  file.close()
  return object
end

# function that reads stop words for removing stop words from user-input queries
def load_stopwords_file(file) 
    stop_words = Hash.new(0)
    file = File.open(file, "r")
    file.readlines.each do |word|
      stop_words[word.chomp] = 1
    end

    file.close
    return stop_words
end

# function that remove stop words from user-input queries
def remove_stop_tokens(tokens, stop_words)
  tokens_without_stop = Array.new

  tokens.each do |token|
    unless stop_words.include? token
      tokens_without_stop.push(token)
    end
  end

  return tokens_without_stop
end

# function that stem tokens from user-input queries
def stem_tokens(tokens)
  stem_tokens = Array.new

  tokens.each do |token|
    stem_tokens.push(Stemmer.stem_word(token))
  end
  
  return stem_tokens
end

# function that finds the list of documents that fit the user-input requirements (queries)
def find_hitlist(mode, query, invindex)
  hit_list = Array.new
  hit_hash = Hash.new 0
  temp_list = Array.new
  first = 0

  query.each do |term|
    if invindex.has_key?(term)
      # if only one user-input query
      if (first == 0)
        hit_list |= invindex[term][1].keys
        hit_list.each {|doc| hit_hash[doc] += 1}
        first = 1
      else
        # find the pages that include at least one user-input query
        if (mode == "or")
          hit_list |= invindex[term][1].keys
        # find the pages that include all the user-input queries
        elsif (mode == "and")
          hit_list &= invindex[term][1].keys
        # map the docs to the number of user-input query they contain
        elsif (mode == "most")
          temp_list = invindex[term][1].keys
          temp_list.each {|doc| hit_hash[doc] += 1}
        end
      end
    else
      hit_list = []
    end
  end

  # find the pages that include at least half of the queries
  if (mode == "most")
    hit_list = []
    hit_hash.each {|k, v| hit_list.push(k) if v > (query.length / 2)}
  end

  return hit_list
end

# function that calculates the tfidf score for one single query
def single_tfidf(query, page, invindex, docindex)
  if invindex[query] and invindex[query][1][page]
    tf = invindex[query][1][page]
    doc_length = docindex[page][0]
    ntf = tf * 1.0 /doc_length
    df = invindex[query][1].length
    idf = 1.0 / (1 + Math.log(df))
    tfidf = ntf / idf
  else
    tfidf = 0
  end
  return tfidf
end

# function that calculates the total tfidf scores for all pages in the hist list
def cal_tfidf(clean_query, hit_list, invindex, docindex)
  tfidf_hash = Hash.new
  total_tfidf = 0 
  if hit_list.size != 0 
    for page in hit_list
      for query in clean_query
        total_tfidf += single_tfidf(query, page, invindex, docindex)
      end
      tfidf_hash[page] = total_tfidf
      total_tfidf = 0
    end
  end

  return tfidf_hash
end  

# function that combines page-rank scores with tfidf scores
def final_score(pagerank, tfidf_hash)
  final_hash = Hash.new
  pagerank.each do |key, value|
    if tfidf_hash[key]
      # (the weight can be revised for obtaining better results)
      final_hash[key] = value + tfidf_hash[key]*2
    else
      final_hash[key] = value
    end
  end

  return final_hash
end

# functions that display results with link, title and scores
def display(final_hash, docindex)
  new_docindex = Hash.new

  docindex.each do |key, value|
    value[0] = 0
  end

  # update value[0] with scores (save space)
  final_hash.each do |key, value|
    docindex[key][0] = value   
  end
  # sort with links with higher scores in the front
  docindex =  docindex.sort {|a, b| a[1] <=> b[1]}.reverse
  
  # value[0] - scores, value[1] - title, value[2] - link
  docindex.each do |key, value|
    new_docindex[key] = [value[2],value[1],value[0]]

  end
  return new_docindex
end

end

=begin
#################################################
# Main program. We expect the user to run the program like this:
#
#   ./retrieve2.rb kw1 kw2 kw3 .. kwn
#
################################################

# check that the user gave us correct command line parameters
abort "Command line should have at least 1 parameters" if ARGV.size<1

keyword_list = ARGV[0..ARGV.size]

# read in the index file produced by the crawler from Assignment 2 (mapping URLs to filenames).
docindex=read_data("doc.dat")

# read in the inverted index produced by the indexer.
invindex=read_data("invindex.dat")

# read in the pagerank file produced by the pangrank ruby file.
pagerank=read_data("pagerank.dat")

# read in list of stopwords from file
stopwords = load_stopwords_file("stop.txt")

puts keyword_list.inspect

# Step (1) Stem and stop the query terms
query_term = stem_tokens(keyword_list)
puts query_term.inspect

clean_query = remove_stop_tokens(query_term, stopwords)
puts clean_query.inspect

# Step (2) Use the inverted index file to find the hit list
hit_list = find_hitlist("most", clean_query, invindex)
puts hit_list.inspect

#
# Step (3) For each page in the hit list,
# display the URL and the title of the HTML page
num_of_doc = hit_list.length

if (num_of_doc == 0)
    print "No documents contained these query terms..\n\n"
else
  hit_list.each do |page|
      page_title = docindex[page][1]
      page_url = docindex[page][2]
      #    print "URL: #{page_url} \nTitle: #{page_title} \n\n"
  end
end

# # Step (4) Display the total number of documents
# # and the total number of hits
# #print "\n\n==============================\n"
# #print "Total number of document: #{docindex.keys.length} \n"
# #print "Total number of hits: #{num_of_doc} \n\n"

tfidf_hash = cal_tfidf(clean_query, hit_list, invindex, docindex)
final_hash = final_score(pagerank, tfidf_hash)
display(final_hash, docindex)
=end
