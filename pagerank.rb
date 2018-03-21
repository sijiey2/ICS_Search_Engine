#!/Users/JessieYu/.rvm/rubies/ruby-2.4.1/bin/ruby
#
# Purpose: 
# Rank each pages with scores based on their number of child links
####################################################

# function that writes out data to a file
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

# function that reads data from adjlinks.dat
def read_data(file_name)
  file = File.open(file_name,"r")
  object = eval(file.gets)
  file.close()
  return object
end

# function that reads data from index.dat
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

# function that maps links to their child links and exclues links that are not in the index.dat
def build_matrix(adjlinks, index)
  matrix_A = Hash.new 
  adjlinks.each do |key, value|
    child_links = value
    child_links.delete_if {|link| not index.has_value?(link)}
    matrix_A[key] = child_links
  end 
  return matrix_A
end

# function that ranks each pages
def page_rank(matrix_A, file_length)
  p = 0.8
  scores_hash = Hash.new(0)
  sum_hash = Hash.new(1.0/file_length)

  matrix_A.each do |key, value|
    degree = value.length
    if degree > 0
      for link in value
        sum_hash[link] += sum_hash[key]/degree
      end
    end
  end
  matrix_A.each_key do |key|
    scores_hash[key] = (p/file_length) + (1-p)*sum_hash[key]
  end
  return scores_hash
end

# function that maps documents to their scores
def update(scores_hash, docindex)
  scores = Hash.new
  docindex.each do |page, value1|
    scores_hash.each do |link, value2|
      if value1[2] == link
        scores[page] = value2
      end
    end
  end

  return scores
end

#################################################
# Main program. We expect the user to run the program like this:
#
#   ./pagerank.rb pages_dir/ 
#
################################################

# check that the user gave us 2 command line parameters 
if ARGV.size != 1
  abort "Command line should have 3 parameters"
end

# fetch command line parameters
pages_dir = ARGV[0]

# get the total number of files
file_list = Dir.entries(pages_dir).select {|f| !File.directory? f}
file_length = file_list.length 

# read in the index file and the adjlinks file produced by the crawler 
adjlinks = read_data("adjlinks.dat")
index = read_index("index.dat")
docindex = read_data("doc.dat")

matrix_A = build_matrix(adjlinks, index)
result = page_rank(matrix_A,file_length)
result = update(result, docindex)

# save the hashes to the correct files
write_data("pagerank.dat", result)
puts "Ranking complete!"



